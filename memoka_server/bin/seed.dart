// ignore_for_file: avoid_print
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:memoka_server/src/chat/link_preview_service.dart';
import 'package:memoka_server/src/generated/endpoints.dart';
import 'package:memoka_server/src/generated/protocol.dart';
import 'package:memoka_server/src/media/image_processor.dart';
import 'package:memoka_server/src/sync/version_helper.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';

/// Resets the database and seeds 6 purpose-specific channels for dogfood testing.
///
/// Channels: General (text), Images, Videos, Documents, Links, Reminders
/// Each channel gets 50+ notes (except Reminders which is deferred).
///
/// Media channels require fixture files in fixtures/seed/{images,videos,docs}/.
/// If fewer than 50 files exist, the seed cycles through available files.
///
/// Usage: dart run bin/seed.dart
void main(List<String> args) async {
  print('Memoka Seed');
  print('=' * 50);

  final pod = Serverpod(args, Protocol(), Endpoints());

  try {
    final session = await pod.createSession();

    // ── Clean slate ────────────────────────────────────────────────
    print('Clearing existing data...');

    final mediaDir = Directory('data/media');
    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) await entity.delete();
      }
    }

    await session.db.unsafeQuery('TRUNCATE TABLE channels CASCADE');
    await session.db.unsafeQuery('UPDATE "sync_state" SET "globalVersion" = 0');
    print('  Done');

    // ── Create channels ────────────────────────────────────────────
    print('\nCreating channels...');

    final channelDefs = [
      ('General', 'chatCircle'),
      ('Images', 'image'),
      ('Videos', 'videoCamera'),
      ('Documents', 'file'),
      ('Links', 'link'),
      ('Reminders', 'bellRinging'),
    ];

    final channels = <String, Channel>{};
    for (var i = 0; i < channelDefs.length; i++) {
      final (name, emoji) = channelDefs[i];
      final saved = await session.db.transaction((tx) async {
        final version = await incrementGlobalVersion(session, transaction: tx);
        return Channel.db.insertRow(
          session,
          Channel(
            name: name,
            emoji: emoji,
            position: i.toDouble(),
            version: version,
          ),
          transaction: tx,
        );
      });
      channels[name] = saved;
      print('  $name ($emoji)');
    }

    // ── Seed each channel ──────────────────────────────────────────
    await _seedGeneral(session, channels['General']!);
    await _seedMedia(session, channels['Images']!, 'fixtures/seed/images');
    await _seedMedia(session, channels['Videos']!, 'fixtures/seed/videos');
    await _seedMedia(session, channels['Documents']!, 'fixtures/seed/docs');
    await _seedLinks(session, channels['Links']!);

    print('\nReminders: empty (deferred)');

    // ── Summary ────────────────────────────────────────────────────
    print('\n${'=' * 50}');
    print('Seed complete!\n');
    for (final entry in channels.entries) {
      final count = await Note.db.count(
        session,
        where: (n) => n.channelId.equals(entry.value.id!),
      );
      print('  ${entry.key}: $count notes');
    }

    await session.close();
    await pod.shutdown();
  } catch (e, stackTrace) {
    print('\nError: $e');
    print(stackTrace);
    await pod.shutdown();
    exit(1);
  }
}

// ── General channel: varied markdown notes ─────────────────────────────────

Future<void> _seedGeneral(Session session, Channel channel) async {
  print('\nSeeding General...');

  final notes = _generalNotes;
  final now = DateTime.now();

  for (var i = 0; i < notes.length; i++) {
    final minutesAgo = (notes.length - i) * 360;
    await session.db.transaction((tx) async {
      final version = await incrementGlobalVersion(session, transaction: tx);
      final note = Note(
        channelId: channel.id!,
        content: notes[i],
        version: version,
      );
      note.createdAt = now.subtract(Duration(minutes: minutesAgo));
      await Note.db.insertRow(session, note, transaction: tx);
    });
  }

  channel.updatedAt = now;
  await Channel.db.updateRow(session, channel);
  print('  ${notes.length} notes');
}

// ── Media channels: cycle through fixture files ───────────────────────────

Future<void> _seedMedia(
  Session session,
  Channel channel,
  String fixturesPath,
) async {
  print('\nSeeding ${channel.name}...');

  final fixturesDir = Directory(fixturesPath);
  if (!await fixturesDir.exists()) {
    print('  No fixtures directory: $fixturesPath (skipped)');
    return;
  }

  final files = await fixturesDir
      .list()
      .where((e) => e is File)
      .cast<File>()
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    print('  No files in $fixturesPath (skipped)');
    return;
  }

  final targetCount = files.length;
  const mediaBaseDir = 'data/media';
  final uuid = Uuid();
  final now = DateTime.now();

  /// Extensions that browsers can display natively — no conversion needed.
  const webSafeImageExtensions = {'.jpg', '.jpeg', '.png', '.webp', '.gif'};

  for (var i = 0; i < targetCount; i++) {
    final file = files[i];
    final bytes = await file.readAsBytes();
    final filename = path.basename(file.path);
    final ext = path.extension(filename).toLowerCase();
    final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';

    // Copy file to media directory
    final channelMediaDir = Directory(
      path.join(mediaBaseDir, 'channels', channel.id!.toString()),
    );
    if (!await channelMediaDir.exists()) {
      await channelMediaDir.create(recursive: true);
    }
    final destFilename = '${uuid.v4()}$ext';
    final destPath = path.join(channelMediaDir.path, destFilename);
    await file.copy(destPath);

    // For non-web-safe images, run through ImageProcessor to convert to PNG.
    final bool isImage = mimeType.startsWith('image/');
    final bool isNonWebSafeImage =
        isImage && !webSafeImageExtensions.contains(ext);

    String resultPath = destPath;
    String resultMimeType = mimeType;
    int? width;
    int? height;
    String? thumbnailRelPath;
    bool animated = false;
    String contentHash;

    if (isNonWebSafeImage) {
      try {
        final result = await ImageProcessor.processImage(
          tempFilePath: destPath,
          finalFilePath: destPath,
          channelDir: channelMediaDir.path,
        );
        resultPath = result.filePath;
        resultMimeType = lookupMimeType(resultPath) ?? mimeType;
        width = result.width;
        height = result.height;
        thumbnailRelPath = result.thumbnailPath;
        animated = result.animated;
        contentHash = result.contentHash;
      } catch (_) {
        // Decode failed — treat as document.
        contentHash = sha256.convert(bytes).toString().substring(0, 8);
        final (w, h) = _parseDimensions(bytes, ext);
        width = w;
        height = h;
      }
    } else {
      contentHash = sha256.convert(bytes).toString().substring(0, 8);
      final (w, h) = _parseDimensions(bytes, ext);
      width = w;
      height = h;
    }

    // Create note + attachment in transaction
    final minutesAgo = (targetCount - i) * 360;
    await session.db.transaction((tx) async {
      final version = await incrementGlobalVersion(session, transaction: tx);

      final note = Note(
        channelId: channel.id!,
        content: '',
        version: version,
      );
      note.createdAt = now.subtract(Duration(minutes: minutesAgo));
      final savedNote = await Note.db.insertRow(session, note, transaction: tx);

      await MediaAttachment.db.insertRow(
        session,
        MediaAttachment(
          noteId: savedNote.id!,
          channelId: channel.id!,
          filePath: path.relative(resultPath, from: mediaBaseDir),
          originalFilename: filename,
          mimeType: resultMimeType,
          fileSize: bytes.length,
          width: width,
          height: height,
          thumbnailPath: thumbnailRelPath,
          animated: animated,
          contentHash: contentHash,
        ),
        transaction: tx,
      );
    });
  }

  channel.updatedAt = now;
  await Channel.db.updateRow(session, channel);
  print('  $targetCount notes (${files.length} unique files)');
}

// ── Links channel: create notes + fetch previews ──────────────────────────

Future<void> _seedLinks(Session session, Channel channel) async {
  print('\nSeeding Links...');

  final urls = _curatedUrls;
  final now = DateTime.now();

  // Create all notes first
  final createdNotes = <Note>[];
  for (var i = 0; i < urls.length; i++) {
    final minutesAgo = (urls.length - i) * 360;
    final saved = await session.db.transaction((tx) async {
      final version = await incrementGlobalVersion(session, transaction: tx);
      final note = Note(
        channelId: channel.id!,
        content: urls[i],
        version: version,
      );
      note.createdAt = now.subtract(Duration(minutes: minutesAgo));
      return Note.db.insertRow(session, note, transaction: tx);
    });
    createdNotes.add(saved);
  }
  print('  ${urls.length} notes created');

  // Batch-fetch link previews (5 at a time)
  print('  Fetching link previews...');
  var previewCount = 0;
  for (var i = 0; i < createdNotes.length; i += 5) {
    final batch = createdNotes.sublist(
      i,
      i + 5 > createdNotes.length ? createdNotes.length : i + 5,
    );
    final previews = await Future.wait(
      batch.map((note) => LinkPreviewService.fetchPreview(note.content)),
    );
    for (var j = 0; j < batch.length; j++) {
      if (previews[j] != null) {
        final note = batch[j];
        note.linkPreview = previews[j];
        note.updatedAt = DateTime.now();
        await session.db.transaction((tx) async {
          final version = await incrementGlobalVersion(
            session,
            transaction: tx,
          );
          note.version = version;
          await Note.db.updateRow(session, note, transaction: tx);
        });
        previewCount++;
      }
    }
    stdout.write(
      '\r  Fetching link previews... ${i + batch.length}/${createdNotes.length}',
    );
  }
  print('\n  $previewCount/${urls.length} previews fetched');

  channel.updatedAt = now;
  await Channel.db.updateRow(session, channel);
}

// ── Dimension parsing ─────────────────────────────────────────────────────

(int?, int?) _parseDimensions(List<int> bytes, String ext) {
  // PNG: IHDR chunk at fixed offset
  if (bytes.length > 24 && bytes[0] == 0x89 && bytes[1] == 0x50) {
    final width =
        (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
    final height =
        (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    return (width, height);
  }

  // JPEG: find SOF0 or SOF2 marker
  if (bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
    var offset = 2;
    while (offset < bytes.length - 9) {
      if (bytes[offset] != 0xFF) break;
      final marker = bytes[offset + 1];
      if (marker == 0xC0 || marker == 0xC2) {
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return (width, height);
      }
      // Skip to next marker
      if (offset + 3 >= bytes.length) break;
      final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];
      offset += 2 + segLen;
    }
  }

  // WebP: RIFF header
  if (bytes.length > 30 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46) {
    // VP8 lossy
    if (bytes[12] == 0x56 &&
        bytes[13] == 0x50 &&
        bytes[14] == 0x38 &&
        bytes[15] == 0x20) {
      if (bytes.length > 29) {
        final width = (bytes[26] | (bytes[27] << 8)) & 0x3FFF;
        final height = (bytes[28] | (bytes[29] << 8)) & 0x3FFF;
        return (width, height);
      }
    }
    // VP8L lossless
    if (bytes[12] == 0x56 &&
        bytes[13] == 0x50 &&
        bytes[14] == 0x38 &&
        bytes[15] == 0x4C) {
      if (bytes.length > 24) {
        final b0 = bytes[21];
        final b1 = bytes[22];
        final b2 = bytes[23];
        final b3 = bytes[24];
        final width = 1 + (((b1 & 0x3F) << 8) | b0);
        final height = 1 + (((b3 & 0x0F) << 10) | (b2 << 2) | ((b1 >> 6) & 3));
        return (width, height);
      }
    }
  }

  // GIF: width at bytes 6-7, height at bytes 8-9 (little-endian)
  if (bytes.length > 9 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46) {
    final width = bytes[6] | (bytes[7] << 8);
    final height = bytes[8] | (bytes[9] << 8);
    return (width, height);
  }

  // TIFF: IFD tags 0x0100 (width) and 0x0101 (height)
  if (bytes.length > 8 &&
      ((bytes[0] == 0x49 && bytes[1] == 0x49) || // Little-endian (II)
          (bytes[0] == 0x4D && bytes[1] == 0x4D))) {
    // Big-endian (MM)
    final littleEndian = bytes[0] == 0x49;

    int readU16(int offset) {
      if (offset + 1 >= bytes.length) return 0;
      return littleEndian
          ? bytes[offset] | (bytes[offset + 1] << 8)
          : (bytes[offset] << 8) | bytes[offset + 1];
    }

    int readU32(int offset) {
      if (offset + 3 >= bytes.length) return 0;
      return littleEndian
          ? bytes[offset] |
                (bytes[offset + 1] << 8) |
                (bytes[offset + 2] << 16) |
                (bytes[offset + 3] << 24)
          : (bytes[offset] << 24) |
                (bytes[offset + 1] << 16) |
                (bytes[offset + 2] << 8) |
                bytes[offset + 3];
    }

    final ifdOffset = readU32(4);
    if (ifdOffset > 0 && ifdOffset + 2 < bytes.length) {
      final entryCount = readU16(ifdOffset);
      int? width;
      int? height;
      for (var i = 0; i < entryCount; i++) {
        final entryBase = ifdOffset + 2 + i * 12;
        if (entryBase + 12 > bytes.length) break;
        final tag = readU16(entryBase);
        final type = readU16(entryBase + 2);
        // Type 3 = SHORT (2 bytes), Type 4 = LONG (4 bytes)
        final value = type == 3
            ? readU16(entryBase + 8)
            : readU32(entryBase + 8);
        if (tag == 0x0100) width = value;
        if (tag == 0x0101) height = value;
        if (width != null && height != null) return (width, height);
      }
    }
  }

  return (null, null);
}

// ── Text content for General channel ──────────────────────────────────────

const _generalNotes = [
  // Short notes
  'Quick thought: Dart null safety is a game changer.',
  'Need to refactor the auth middleware.',
  'Server uptime: 99.97% this month.',
  'Remember to update the API docs.',
  'Hot reload makes Flutter development incredibly fast.',
  'Lunch at 12:30.',
  'CI is green.',
  'Done for today. Picking up the media panel tomorrow.',
  'git rebase -i HEAD~3',
  'Need more coffee.',

  // Bold / italic
  'The **most important** thing about API design is *consistency*.',
  'Always use **strong typing** -- it catches bugs at compile time, not runtime.',
  'We should *really* consider adding rate limiting to the public endpoints.',
  'The ***critical path*** for the release is the database migration.',
  'Test coverage is at **87%** -- target is *90%* by end of sprint.',

  // Headers
  '# Architecture Decision Record\n\nWe chose Serverpod over shelf+custom because it provides code generation, ORM, and WebSocket support out of the box.',
  '## Performance Benchmarks\n\nLatency p50: 12ms\nLatency p95: 45ms\nLatency p99: 120ms\n\nAll within acceptable thresholds.',
  '### Quick Status Update\n\nEverything is on track. No blockers.',

  // Bullet lists
  '**Frontend priorities this week:**\n- Fix the channel list scroll position reset\n- Add loading skeleton for notes\n- Implement pull-to-refresh on mobile\n- Test offline mode on Android',
  'Things I learned today:\n- PostgreSQL LISTEN/NOTIFY is powerful but limited\n- Redis Streams might be better for our use case\n- WebSockets need heartbeat pings to stay alive',
  'Grocery list:\n- Eggs\n- Milk\n- Coffee beans\n- Sourdough bread\n- Avocados',

  // Numbered lists
  'Steps to deploy:\n1. Run integration tests\n2. Build the Flutter web app\n3. Push Docker image to registry\n4. SSH into production server\n5. Pull and restart containers\n6. Verify healthcheck endpoint\n7. Monitor logs for 10 minutes',
  'Top 3 Dart features:\n1. Sound null safety\n2. Extension methods\n3. Records and patterns',
  'Sprint retrospective actions:\n1. Reduce PR review turnaround to < 24h\n2. Add more integration tests for sync\n3. Document the deployment process\n4. Set up error alerting',

  // Code blocks
  '```dart\nfinal channel = await Channel.db.insertRow(\n  session,\n  Channel(\n    name: \'General\',\n    emoji: \'chatCircle\',\n    pinned: true,\n  ),\n);\n```\n\nThat\'s how you create a channel with Serverpod ORM.',
  '```sql\nSELECT n.*, array_agg(ma.*) as attachments\nFROM notes n\nLEFT JOIN media_attachments ma ON ma.note_id = n.id\nWHERE n.channel_id = \$1\nGROUP BY n.id\nORDER BY n.created_at DESC\nLIMIT 50;\n```',
  '```python\ndef fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)\n\nprint([fibonacci(i) for i in range(10)])\n```',
  '```javascript\nconst debounce = (fn, delay) => {\n  let timer;\n  return (...args) => {\n    clearTimeout(timer);\n    timer = setTimeout(() => fn(...args), delay);\n  };\n};\n```',
  '```yaml\nservices:\n  postgres:\n    image: postgres:16\n    environment:\n      POSTGRES_PASSWORD: secret\n    ports:\n      - "5432:5432"\n    volumes:\n      - pgdata:/var/lib/postgresql/data\n```',

  // Inline code
  'Use `dart format .` before committing to keep the code style consistent.',
  'The `incrementGlobalVersion` function uses `UPDATE ... RETURNING` for atomic version bumps.',
  'Run `flutter build web --base-href /app/` to build the web client.',

  // Blockquotes
  '> The best code is no code at all.\n> -- Jeff Atwood\n\nSimplicity should be our guiding principle.',
  '> Make it work, make it right, make it fast.\n> -- Kent Beck\n\nWe\'re currently in the "make it right" phase.',
  '> Premature optimization is the root of all evil.\n> -- Donald Knuth\n\nBut that doesn\'t mean we should ignore obvious performance issues.',

  // Multi-paragraph
  'Just finished reading about event sourcing vs state-based sync. Both have trade-offs.\n\nEvent sourcing gives you a complete audit trail and the ability to replay events. But it\'s complex to implement correctly, especially conflict resolution.\n\nState-based sync is simpler -- you just compare versions and merge. That\'s what we went with for Memoka. Last-write-wins with version vectors.',
  'The offline sync engine is working well. Here\'s the flow:\n\nWhen the app detects a network connection, it first pulls all changes since the last known version. Then it pushes any local dirty entities.\n\nConflicts are resolved server-side with last-write-wins. The server always has the final say on the canonical version.',
  'Been thinking about the notification system. We need:\n\n1. Server-side event detection (new note, mention, reminder)\n2. Push notification delivery (FCM for Android, Web Push for browser)\n3. Client-side notification display\n4. Read/unread tracking\n\nStarting with reminders since they have a clear trigger (scheduled time).',

  // Mixed formatting
  '**Meeting Notes -- 2026-03-15**\n\n*Attendees:* Full team\n\n## Agenda\n1. Sprint review\n2. Architecture discussion\n3. Release planning\n\n### Key Decisions\n- Migrate to `Serverpod 3.3.1` -- better WebSocket handling\n- Add `position: double` for channel ordering\n- Implement archive retention (30/60/90 days)\n\n> Action: Update migration scripts by Friday',
  '# Dart 3.x Pattern Matching\n\nThe new `switch` expressions are amazing:\n\n```dart\nfinal result = switch (status) {\n  \'active\' => handleActive(),\n  \'paused\' => handlePaused(),\n  \'stopped\' => handleStopped(),\n  _ => throw StateError(\'Unknown status: \$status\'),\n};\n```\n\n**Key benefits:**\n- Exhaustiveness checking\n- Destructuring\n- Guard clauses with `when`',

  // Long technical notes
  'PostgreSQL tips for Serverpod developers:\n\n**1. Use EXPLAIN ANALYZE**\nAlways check query plans for slow queries. Add `EXPLAIN ANALYZE` before your SQL to see the execution plan.\n\n**2. Index strategy**\nCreate indexes for:\n- Foreign key columns (channelId, noteId)\n- Columns used in WHERE clauses\n- Columns used in ORDER BY\n\n**3. Connection pooling**\nServerpod handles this automatically, but be aware of connection limits. Default is usually 100 connections.\n\n**4. Transactions**\nWrap related operations in transactions. Use `session.db.transaction()` for atomic operations.\n\n**5. Migrations**\nAlways test migrations on a copy of production data before deploying.',
  'The WebSocket reconnection logic has been solid. Here\'s what we do:\n\n1. Detect disconnection (socket close event)\n2. Start exponential backoff: 1s, 2s, 4s, 8s, max 10s\n3. On each attempt, ping the health endpoint first\n4. If ping succeeds, open WebSocket connection\n5. On successful connect, trigger sync pull\n6. Reset backoff timer\n\nEdge cases handled:\n- Android app backgrounding kills the socket silently\n- Network transitions (WiFi to cellular)\n- Server restarts\n- DNS resolution failures',

  // Task-like notes
  'Archive retention tasks:\n- Write migration for archive retention\n- Add purge scheduler\n- ~~Create settings endpoint~~\n- ~~Build settings UI~~\n- Add retention period selector',
  'Upload pipeline tasks:\n- Image compression on upload\n- ~~Thumbnail generation~~\n- ~~EXIF stripping~~\n- WebP conversion\n- Animated GIF support',

  // Technical notes
  'Drift (SQLite ORM for Flutter) quirks:\n\n- `customStatement()` for raw DDL -- typed column refs don\'t work with `addColumn()`\n- Use `watchDirtyCount()` with a single combined SQL query, not chained `asyncExpand()`\n- WASM SQLite on web needs `package:drift/wasm.dart` import\n- Schema migrations use `onUpgrade` callback with version checks',
  'MediaAttachment content hash: first 8 chars of SHA-256 of the file bytes. Used for deduplication -- if two uploads produce the same hash, we can skip the duplicate.\n\n```dart\nfinal hash = sha256.convert(bytes);\nfinal contentHash = hash.toString().substring(0, 8);\n```',
  'Note to self: the `chatStreamProvider` has a `cancelled` flag to prevent stale generator race conditions. Don\'t remove it thinking it\'s dead code.',
  'Fractional ordering for channels:\n\nInstead of integer sort orders that require reindexing, we use doubles.\n\nInsert between positions 1.0 and 2.0? Use 1.5.\nInsert between 1.0 and 1.5? Use 1.25.\n\nEventually the precision runs out, but for a personal notes app with < 100 channels, this is more than sufficient.',
  'Why we chose Riverpod over BLoC:\n\n1. Less boilerplate -- no event classes, no state classes\n2. Provider dependencies are explicit and type-safe\n3. Code generation with `@riverpod` annotation\n4. Better testing support with `ProviderContainer`\n5. `keepAlive` for persistent state without global singletons',

  // H4 / H5 / H6
  '#### H4 Heading\n\nThis is an H4 heading. Useful for deeply nested sections.\n\n##### H5 Heading\n\nEven deeper nesting.\n\n###### H6 Heading\n\nThe smallest heading level.',

  // Horizontal rules
  'Section one content.\n\n---\n\nSection two content after a horizontal rule.\n\n***\n\nSection three after another style of rule.',

  // Markdown links
  'Some useful links:\n- [Dart language tour](https://dart.dev/language)\n- [Flutter documentation](https://docs.flutter.dev)\n- [Serverpod docs](https://docs.serverpod.dev)\n\nInline link: check out [pub.dev](https://pub.dev) for packages.',

  // Markdown images
  '![Dart logo](https://dart.dev/assets/img/shared/dart/logo+text/horizontal/white.svg)\n\nMarkdown image syntax test (may not render if URL is unreachable).',

  // Tables
  '| Method | Endpoint | Description |\n|--------|----------|-------------|\n| GET | /api/channels | List all channels |\n| POST | /api/channels | Create a channel |\n| PUT | /api/channels/:id | Update a channel |\n| DELETE | /api/channels/:id | Delete a channel |',

  // Nested lists
  'Project structure:\n- Server\n  - Endpoints\n    - chat_endpoint.dart\n    - sync_endpoint.dart\n  - Models\n    - channel.spy.yaml\n    - note.spy.yaml\n- Client (generated)\n- Flutter app\n  - Screens\n  - Widgets\n  - Providers',

  // Task lists
  'Release checklist:\n- [x] Run all integration tests\n- [x] Update changelog\n- [ ] Tag release in git\n- [ ] Build Docker image\n- [ ] Deploy to production\n- [ ] Verify healthcheck',

  // Nested blockquotes
  '> First level quote\n>\n> > Nested quote inside the first\n> >\n> > > Triple-nested quote for emphasis\n>\n> Back to first level.',

  // Escape characters
  'Markdown escape test:\n\n\\*This is not italic\\*\n\n\\# This is not a heading\n\n\\`This is not code\\`\n\nPipe in text: 10 \\| 20 \\| 30',

  // Mixed: link + bold + code
  'Check the [**official Dart docs**](https://dart.dev) for `pattern matching` syntax. The new `switch` expressions with *guard clauses* are especially useful.',

  // Long table
  '## HTTP Status Codes\n\n| Code | Name | Usage |\n|------|------|-------|\n| 200 | OK | Successful request |\n| 201 | Created | Resource created |\n| 204 | No Content | Successful, no body |\n| 400 | Bad Request | Invalid input |\n| 401 | Unauthorized | Auth required |\n| 403 | Forbidden | Access denied |\n| 404 | Not Found | Resource missing |\n| 409 | Conflict | Version conflict |\n| 500 | Internal Error | Server bug |',
];

// ── Curated stable URLs for Links channel ─────────────────────────────────

const _curatedUrls = [
  // Wikipedia
  'https://en.wikipedia.org/wiki/Dart_(programming_language)',
  'https://en.wikipedia.org/wiki/Flutter_(software)',
  'https://en.wikipedia.org/wiki/PostgreSQL',
  'https://en.wikipedia.org/wiki/Redis',
  'https://en.wikipedia.org/wiki/WebSocket',
  'https://en.wikipedia.org/wiki/Markdown',
  'https://en.wikipedia.org/wiki/Rust_(programming_language)',
  'https://en.wikipedia.org/wiki/Go_(programming_language)',
  'https://en.wikipedia.org/wiki/TypeScript',
  'https://en.wikipedia.org/wiki/GraphQL',
  'https://en.wikipedia.org/wiki/HTTP/2',
  'https://en.wikipedia.org/wiki/OAuth',
  'https://en.wikipedia.org/wiki/JSON',
  'https://en.wikipedia.org/wiki/SQLite',
  'https://en.wikipedia.org/wiki/Docker_(software)',

  // GitHub repos
  'https://github.com/serverpod/serverpod',
  'https://github.com/flutter/flutter',
  'https://github.com/dart-lang/sdk',
  'https://github.com/microsoft/vscode',
  'https://github.com/vercel/next.js',
  'https://github.com/denoland/deno',
  'https://github.com/supabase/supabase',
  'https://github.com/torvalds/linux',
  'https://github.com/rust-lang/rust',
  'https://github.com/golang/go',

  // MDN docs
  'https://developer.mozilla.org/en-US/docs/Web/JavaScript',
  'https://developer.mozilla.org/en-US/docs/Web/CSS',
  'https://developer.mozilla.org/en-US/docs/Web/HTML',
  'https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API',
  'https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API',

  // Dart / Flutter
  'https://dart.dev/language',
  'https://dart.dev/guides/libraries/library-tour',
  'https://api.flutter.dev/flutter/widgets/widgets-library.html',
  'https://pub.dev/packages/riverpod',
  'https://pub.dev/packages/drift',

  // Infrastructure docs
  'https://www.postgresql.org/docs/current/tutorial.html',
  'https://redis.io/docs/getting-started/',
  'https://docs.docker.com/get-started/',
  'https://kubernetes.io/docs/home/',
  'https://www.sqlite.org/about.html',

  // Language / framework homepages
  'https://www.rust-lang.org/',
  'https://go.dev/',
  'https://www.typescriptlang.org/',
  'https://nodejs.org/en',
  'https://www.python.org/',

  // Specs and standards
  'https://docs.github.com/en/rest',
  'https://spec.graphql.org/October2021/',
  'https://datatracker.ietf.org/doc/html/rfc7231',
  'https://datatracker.ietf.org/doc/html/rfc6455',
  'https://www.w3.org/TR/css-flexbox-1/',

  // Dev tools
  'https://code.visualstudio.com/',
  'https://www.jetbrains.com/idea/',
  'https://github.com/features/copilot',
  'https://www.figma.com/',
  'https://linear.app/',
];
