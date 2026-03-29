import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';

import 'ffmpeg_utils.dart';
import 'hash_utils.dart';

/// In-process singleton tracking the state of one thumbnail regen job.
///
/// Dart is single-threaded so no locking is needed. Only one job runs at a
/// time; [startThumbnailRegen] is a no-op if [isRunning] is already true.
class ThumbnailRegenJob {
  ThumbnailRegenJob._();

  static bool isRunning = false;
  static int total = 0;
  static int processed = 0;
  static int failed = 0;

  static void _start(int count) {
    isRunning = true;
    total = count;
    processed = 0;
    failed = 0;
  }

  static void _finish() {
    isRunning = false;
  }
}

/// Shared logic for regenerating thumbnails for all image/video attachments.
///
/// Used by both the settings endpoint (live, fire-and-forget) and the CLI
/// script (bin/regenerate_thumbnails.dart, standalone mode).
class ThumbnailRegenService {
  static const _mediaBaseDir = 'data/media';

  /// Counts non-deleted image/video attachments eligible for thumbnail regen.
  static Future<int> countEligible(Session session) async {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT COUNT(*)
      FROM   media_attachments ma
      JOIN   notes n ON n.id = ma."noteId"
      WHERE  n."deletedAt" IS NULL
        AND  (ma."mimeType" LIKE 'image/%' OR ma."mimeType" LIKE 'video/%')
        AND  ma."mimeType" != 'image/svg+xml'
      ''',
    );
    return rows.first[0] as int;
  }

  /// Starts a background thumbnail regen job. Returns immediately after
  /// recording the total count. Progress is tracked in [ThumbnailRegenJob].
  ///
  /// Does nothing if a job is already running.
  /// Throws if ffmpeg is not available.
  static Future<int> startBackground(Session session) async {
    if (ThumbnailRegenJob.isRunning) return ThumbnailRegenJob.total;

    if (!await FfmpegUtils.checkAvailable()) {
      throw Exception('ffmpeg is not available on the server');
    }

    final total = await countEligible(session);
    ThumbnailRegenJob._start(total);

    // Create a background session independent of the request session so the
    // job outlives the RPC call.
    // ignore: avoid_print
    print('[ThumbnailRegen] Starting background job for $total attachments');
    unawaited(() async {
      Session? bgSession;
      try {
        bgSession = await session.serverpod.createSession();
        // ignore: avoid_print
        await _runAll(bgSession, log: print);
        // ignore: avoid_print
        print(
          '[ThumbnailRegen] Done — '
          '${ThumbnailRegenJob.processed} ok, '
          '${ThumbnailRegenJob.failed} failed',
        );
      } catch (e, stack) {
        // ignore: avoid_print
        print('[ThumbnailRegen] Background job error: $e\n$stack');
      } finally {
        ThumbnailRegenJob._finish();
        await bgSession?.close();
      }
    }());

    return total;
  }

  /// Runs the full regen loop, updating [ThumbnailRegenJob] as it goes.
  /// Also accepts an optional [log] callback for CLI output.
  static Future<void> _runAll(
    Session session, {
    void Function(String)? log,
  }) async {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT ma.id, ma."channelId", ma."filePath", ma."thumbnailPath"
      FROM   media_attachments ma
      JOIN   notes n ON n.id = ma."noteId"
      WHERE  n."deletedAt" IS NULL
        AND  (ma."mimeType" LIKE 'image/%' OR ma."mimeType" LIKE 'video/%')
        AND  ma."mimeType" != 'image/svg+xml'
      ORDER  BY ma.id
      ''',
    );

    final size = FfmpegUtils.thumbnailSize;
    final compression = FfmpegUtils.thumbnailCompressionLevel;

    for (final row in rows) {
      final id = row[0] as int;
      final channelId = row[1] as int;
      final filePath = row[2] as String;
      final existingThumbPath = row[3] as String?;

      final sourceFile = File('$_mediaBaseDir/$filePath');
      if (!await sourceFile.exists()) {
        log?.call('  [$id] SKIP — source file missing: $filePath');
        ThumbnailRegenJob.failed++;
        continue;
      }

      final channelDir = '$_mediaBaseDir/channels/$channelId';
      final baseName = path.basenameWithoutExtension(filePath);
      final thumbFilePath = '$channelDir/thumbnails/${baseName}_thumb.webp';

      final thumbDir = Directory('$channelDir/thumbnails');
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }

      final result = await Process.run('ffmpeg', [
        '-i',
        sourceFile.path,
        '-vframes',
        '1',
        '-vf',
        'scale=$size:$size:force_original_aspect_ratio=decrease',
        '-lossless',
        '1',
        '-compression_level',
        '$compression',
        '-y',
        thumbFilePath,
      ]);

      if (result.exitCode != 0) {
        log?.call('  [$id] FAIL — ${result.stderr}');
        ThumbnailRegenJob.failed++;
        continue;
      }

      final newThumbRelative = path.relative(thumbFilePath, from: channelDir);
      final newHash = await computeFileHash(thumbFilePath);

      if (existingThumbPath == null) {
        final escaped = newThumbRelative.replaceAll("'", "''");
        await session.db.unsafeQuery(
          'UPDATE media_attachments SET "thumbnailPath" = \'$escaped\', '
          '"contentHash" = \'$newHash\' WHERE id = $id',
        );
      } else {
        await session.db.unsafeQuery(
          'UPDATE media_attachments SET "contentHash" = \'$newHash\' WHERE id = $id',
        );
      }

      log?.call('  [$id] OK — $newThumbRelative');
      ThumbnailRegenJob.processed++;
    }
  }

  /// Synchronous variant used by the CLI script (standalone mode).
  /// Runs the full loop in the foreground, returns final counts.
  static Future<({int ok, int skipped, int failed})> regenerateAll(
    Session session, {
    void Function(String)? log,
  }) async {
    ThumbnailRegenJob._start(await countEligible(session));
    try {
      await _runAll(session, log: log);
    } finally {
      ThumbnailRegenJob._finish();
    }
    return (
      ok: ThumbnailRegenJob.processed,
      skipped: 0,
      failed: ThumbnailRegenJob.failed,
    );
  }
}
