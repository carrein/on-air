import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'src/chat/link_preview_service.dart';
import 'src/pagewatch/page_watch_service.dart';
import 'src/pagewatch/page_watch_setup.dart';
import 'src/reminder/reminder_service.dart';
import 'src/reminder/reminder_setup.dart';
import 'src/search/search_setup.dart';
import 'src/settings/archive_purge_service.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/shared/constants.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/cors_media_route.dart';
import 'src/web/routes/healthcheck_route.dart';
import 'src/web/routes/media_upload_route.dart';
import 'src/web/routes/root.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Serve media files
  // Use local data/media directory in development, /app/media in production
  final mediaDir = Directory(ServerConstants.mediaBaseDir);
  if (!await mediaDir.exists()) {
    await mediaDir.create(recursive: true);
  }
  pod.webServer.addRoute(
    CorsMediaRoute(mediaDir),
    '/media',
  );

  // Multipart upload route (streams file to disk, no OOM)
  pod.webServer.addRoute(MediaUploadRoute(), '/media/upload');

  // Healthcheck route — used by Flutter web as a connectivity probe.
  // GET-based so the browser XHR timeout actually aborts the request.
  pod.webServer.addRoute(HealthcheckRoute(), '/healthcheck');

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Start the server.
  await pod.start();

  // Ensure default "General" channel exists
  await _ensureDefaultChannel(pod);

  // Ensure app_settings singleton table exists.
  // Created at startup (not via migration) because Serverpod's schema validator
  // can't model singleton tables with CHECK constraints.
  await _ensureAppSettings(pod);

  // Ensure search infrastructure (tsvector, trigram indexes, trigger).
  // Created at startup (not via migration) because Serverpod's schema validator
  // can't model tsvector columns or custom triggers.
  final searchSession = await pod.createSession();
  try {
    await SearchSetup.ensureSearchInfrastructure(searchSession);
  } finally {
    await searchSession.close();
  }

  // Ensure page_watches table for URL change monitoring.
  final pageWatchSession = await pod.createSession();
  try {
    await PageWatchSetup.ensurePageWatchTable(pageWatchSession);
  } finally {
    await pageWatchSession.close();
  }

  // Run archive purge on startup + every hour
  await ArchivePurgeService.runPurge(pod);
  Timer.periodic(
    const Duration(hours: 1),
    (_) => ArchivePurgeService.runPurge(pod),
  );

  // Run page watch check on startup + every 5 minutes
  await PageWatchService.runCheck(pod);
  Timer.periodic(
    const Duration(minutes: 5),
    (_) => PageWatchService.runCheck(pod),
  );

  // Ensure reminders table for time-based note notifications.
  final reminderSession = await pod.createSession();
  try {
    await ReminderSetup.ensureReminderTable(reminderSession);
  } finally {
    await reminderSession.close();
  }

  // Initialize per-reminder timer scheduler (replaces 60s batch poll)
  await ReminderService.init(pod);

  // One-time migration: download external preview images to local storage.
  // Idempotent — skips notes whose imageUrl/faviconUrl are already local paths.
  unawaited(_migrateExternalPreviewImages(pod));

  // One-time cleanup: null out non-raster preview paths (SVG, ICO, etc.)
  // that were downloaded before the format filter was added.
  unawaited(_cleanupNonRasterPreviews(pod));
}

Future<void> _ensureAppSettings(Serverpod pod) async {
  final session = await pod.createSession();
  try {
    // Singleton table for app-wide settings (same pattern as sync_state).
    await session.db.unsafeQuery('''
      CREATE TABLE IF NOT EXISTS "app_settings" (
        "id" bigint PRIMARY KEY DEFAULT 1,
        "archiveRetentionDays" bigint NOT NULL DEFAULT 0,
        CONSTRAINT "app_settings_singleton" CHECK ("id" = 1)
      )
    ''');
    await session.db.unsafeQuery('''
      INSERT INTO "app_settings" ("id", "archiveRetentionDays")
      VALUES (1, 0)
      ON CONFLICT ("id") DO NOTHING
    ''');
  } finally {
    await session.close();
  }
}

/// One-time migration: re-download external preview images to local storage.
/// After this, imageUrl/faviconUrl fields store relative paths served via /media.
/// Idempotent: skips notes whose URLs are already relative (non-http) paths.
Future<void> _migrateExternalPreviewImages(Serverpod pod) async {
  // Skip if already completed
  final marker = File('${ServerConstants.mediaBaseDir}/previews/.migrated');
  if (await marker.exists()) return;

  final session = await pod.createSession();
  try {
    // ColumnSerializable (JSONB) doesn't support notEquals, so use raw SQL
    // to get IDs of notes with link previews, then load via ORM.
    final rows = await session.db.unsafeQuery(
      '''SELECT "id" FROM "notes" WHERE "linkPreview" IS NOT NULL''',
    );
    if (rows.isEmpty) {
      await marker.parent.create(recursive: true);
      await marker.writeAsString('');
      return;
    }

    final ids = rows.map((r) => r.toColumnMap()['id'] as int).toList();
    final notes = await Note.db.find(
      session,
      where: (t) => t.id.inSet(ids.toSet()),
    );

    var migrated = 0;
    for (final note in notes) {
      final preview = note.linkPreview;
      if (preview == null) continue;
      var changed = false;

      var newImageUrl = preview.imageUrl;
      var newFaviconUrl = preview.faviconUrl;

      // Download external OG image
      if (newImageUrl != null &&
          (newImageUrl.startsWith('http://') ||
              newImageUrl.startsWith('https://'))) {
        newImageUrl = await LinkPreviewService.downloadPreviewImage(
          newImageUrl,
          'previews',
        );
        changed = true;
      }

      // Download external favicon
      if (newFaviconUrl != null &&
          (newFaviconUrl.startsWith('http://') ||
              newFaviconUrl.startsWith('https://'))) {
        newFaviconUrl = await LinkPreviewService.downloadPreviewImage(
          newFaviconUrl,
          'previews/favicons',
        );
        changed = true;
      }

      if (changed) {
        note.linkPreview = LinkPreview(
          url: preview.url,
          title: preview.title,
          description: preview.description,
          imageUrl: newImageUrl,
          faviconUrl: newFaviconUrl,
          fetchedAt: preview.fetchedAt,
        );
        await Note.db.updateRow(session, note);
        migrated++;
      }
    }

    if (migrated > 0) {
      session.log(
        'Migrated $migrated link preview(s) to self-hosted images',
      );
    }

    // Mark migration as complete
    await marker.parent.create(recursive: true);
    await marker.writeAsString('');
  } catch (e) {
    session.log('Preview image migration error: $e', level: LogLevel.warning);
  } finally {
    await session.close();
  }
}

/// One-time cleanup: null out non-raster preview image/favicon paths (SVG, ICO,
/// etc.) that were downloaded before the raster-only filter was added.
/// These formats crash CanvasKit on Flutter web.
Future<void> _cleanupNonRasterPreviews(Serverpod pod) async {
  const safeExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'wbmp',
  };

  final marker = File(
    '${ServerConstants.mediaBaseDir}/previews/.format_cleaned',
  );
  if (await marker.exists()) return;

  final session = await pod.createSession();
  try {
    final rows = await session.db.unsafeQuery(
      '''SELECT "id" FROM "notes" WHERE "linkPreview" IS NOT NULL''',
    );
    if (rows.isEmpty) {
      await marker.parent.create(recursive: true);
      await marker.writeAsString('');
      return;
    }

    final ids = rows.map((r) => r.toColumnMap()['id'] as int).toList();
    final notes = await Note.db.find(
      session,
      where: (t) => t.id.inSet(ids.toSet()),
    );

    bool isUnsafe(String? path) {
      if (path == null) return false;
      // External URLs are handled separately; only check local paths
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return false;
      }
      final dot = path.lastIndexOf('.');
      if (dot == -1) return true; // no extension — unsafe
      final ext = path.substring(dot + 1).toLowerCase();
      return !safeExtensions.contains(ext);
    }

    var cleaned = 0;
    for (final note in notes) {
      final preview = note.linkPreview;
      if (preview == null) continue;
      var changed = false;

      var newImageUrl = preview.imageUrl;
      var newFaviconUrl = preview.faviconUrl;

      if (isUnsafe(newImageUrl)) {
        newImageUrl = null;
        changed = true;
      }
      if (isUnsafe(newFaviconUrl)) {
        newFaviconUrl = null;
        changed = true;
      }

      if (changed) {
        note.linkPreview = LinkPreview(
          url: preview.url,
          title: preview.title,
          description: preview.description,
          imageUrl: newImageUrl,
          faviconUrl: newFaviconUrl,
          fetchedAt: preview.fetchedAt,
        );
        await Note.db.updateRow(session, note);
        cleaned++;
      }
    }

    if (cleaned > 0) {
      session.log('Cleaned $cleaned non-raster preview path(s)');
    }

    await marker.parent.create(recursive: true);
    await marker.writeAsString('');
  } catch (e) {
    session.log(
      'Non-raster preview cleanup error: $e',
      level: LogLevel.warning,
    );
  } finally {
    await session.close();
  }
}

Future<void> _ensureDefaultChannel(Serverpod pod) async {
  final session = await pod.createSession();
  try {
    final count = await Channel.db.count(
      session,
      where: (t) => t.archived.equals(false) & t.deletedAt.equals(null),
    );
    if (count == 0) {
      // Bump globalVersion so the new channel is visible to syncPull(0).
      final versionResult = await session.db.unsafeQuery(
        'UPDATE "sync_state" SET "globalVersion" = "globalVersion" + 1 RETURNING "globalVersion"',
      );
      final newVersion =
          versionResult.first.toColumnMap()['globalVersion'] as int;
      await Channel.db.insertRow(
        session,
        Channel(name: 'General', emoji: '💬', version: newVersion),
      );
      session.log('Created default "General" channel (version: $newVersion)');
    }
  } finally {
    await session.close();
  }
}
