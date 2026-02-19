// ignore_for_file: avoid_print
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:memoka_server/src/generated/endpoints.dart';
import 'package:memoka_server/src/generated/protocol.dart';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';

/// Resets the database and seeds a clean demo state.
///
/// Creates 3 channels (General, Ideas, Todos) with sample content
/// including text, links, and images from the demo/ folder.
///
/// Usage: dart run bin/seed_demo.dart
///
/// WARNING: This will DELETE ALL existing data!
void main(List<String> args) async {
  print('🌱 Memoka Demo Seed');
  print('━' * 50);
  print('⚠️  WARNING: This will DELETE ALL existing data!');
  print('   Creates 3 channels with sample content.');
  print('━' * 50);

  stdout.write('Are you sure? Type "yes" to continue: ');
  final confirmation = stdin.readLineSync();

  if (confirmation?.toLowerCase() != 'yes') {
    print('❌ Aborted. No changes made.');
    exit(0);
  }

  print('\n📦 Initializing Serverpod...');
  final pod = Serverpod(args, Protocol(), Endpoints());

  try {
    final session = await pod.createSession();

    // ── Clean slate ──────────────────────────────────────────────
    print('🗑️  Clearing existing data...');

    final mediaDir = Directory('data/media');
    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          await entity.delete();
        }
      }
      print('   ✓ Deleted media files');
    }

    await session.db.unsafeQuery('TRUNCATE TABLE channels CASCADE');
    await session.db.unsafeQuery('TRUNCATE TABLE notes CASCADE');
    await session.db.unsafeQuery('TRUNCATE TABLE media_attachments CASCADE');
    print('   ✓ Cleared database tables');

    // ── Channels ─────────────────────────────────────────────────
    print('\n🌱 Creating channels...');

    final general = await Channel.db.insertRow(
      session,
      Channel(name: 'General', emoji: 'chatCircle', pinned: true, sortOrder: 0),
    );
    print('   ✓ ${general.name}');

    final ideas = await Channel.db.insertRow(
      session,
      Channel(name: 'Ideas', emoji: 'lightbulb', sortOrder: 1),
    );
    print('   ✓ ${ideas.name}');

    final todos = await Channel.db.insertRow(
      session,
      Channel(name: 'Todos', emoji: 'checkSquare', sortOrder: 2),
    );
    print('   ✓ ${todos.name}');

    // ── Helper to insert a note at a specific time ───────────────
    final now = DateTime.now();

    Future<Note> addNote(
      int channelId,
      String content, {
      int minutesAgo = 0,
    }) async {
      final note = Note(channelId: channelId, content: content);
      note.createdAt = now.subtract(Duration(minutes: minutesAgo));
      return await Note.db.insertRow(session, note);
    }

    // ── Helper to insert a note with an image ────────────────────
    final uuid = Uuid();
    const mediaBaseDir = 'data/media';
    final demoDir = Directory('fixtures/demo');

    Future<Note> addImageNote(
      int channelId,
      String content,
      String demoFilename, {
      int minutesAgo = 0,
    }) async {
      final sourceFile = File(path.join(demoDir.path, demoFilename));
      if (!await sourceFile.exists()) {
        print('   ⚠ Missing demo image: $demoFilename');
        return await addNote(channelId, content, minutesAgo: minutesAgo);
      }

      // Read file and compute hash
      final bytes = await sourceFile.readAsBytes();
      final hashDigest = sha256.convert(bytes);
      final contentHash = hashDigest.toString().substring(0, 8);

      // Read PNG dimensions from header (bytes 16-19 = width, 20-23 = height)
      int? width;
      int? height;
      if (bytes.length > 24 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50) {
        // PNG signature confirmed
        width = (bytes[16] << 24) |
            (bytes[17] << 16) |
            (bytes[18] << 8) |
            bytes[19];
        height = (bytes[20] << 24) |
            (bytes[21] << 16) |
            (bytes[22] << 8) |
            bytes[23];
      }

      // Create channel media directory
      final channelMediaDir = Directory(
        path.join(mediaBaseDir, 'channels', channelId.toString()),
      );
      if (!await channelMediaDir.exists()) {
        await channelMediaDir.create(recursive: true);
      }

      // Copy file with UUID name
      final fileUuid = uuid.v4();
      final destFilename = '$fileUuid.png';
      final destPath = path.join(channelMediaDir.path, destFilename);
      await sourceFile.copy(destPath);

      // Create note
      final note = Note(channelId: channelId, content: content);
      note.createdAt = now.subtract(Duration(minutes: minutesAgo));
      final savedNote = await Note.db.insertRow(session, note);

      // Create attachment
      final relativePath = path.relative(destPath, from: mediaBaseDir);
      final attachment = MediaAttachment(
        noteId: savedNote.id!,
        channelId: channelId,
        filePath: relativePath,
        originalFilename: demoFilename,
        mimeType: 'image/png',
        fileSize: bytes.length,
        width: width,
        height: height,
        contentHash: contentHash,
      );
      await MediaAttachment.db.insertRow(session, attachment);

      return savedNote;
    }

    // ── General channel ──────────────────────────────────────────
    print('\n📝 Populating General...');

    await addNote(
      general.id!,
      'Welcome to Memoka! 🎉\n\nThis is your personal notes space. '
          'Create channels to organize different topics, and jot down '
          'thoughts as they come.',
      minutesAgo: 1440, // 1 day ago
    );

    await addNote(
      general.id!,
      'Serverpod is the backend framework powering this app. '
          'Check it out: https://serverpod.dev',
      minutesAgo: 1380,
    );

    await addNote(
      general.id!,
      'Built with Flutter — one codebase for web, Android, and iOS.\n\n'
          'https://flutter.dev',
      minutesAgo: 1200,
    );

    await addNote(
      general.id!,
      'Quick tip: you can drag and drop images directly into the chat to upload them.',
      minutesAgo: 1080,
    );

    await addNote(
      general.id!,
      '## Meeting Notes — Project Kickoff\n\n'
          '**Date:** Monday morning\n'
          '**Attendees:** Alex, Jordan, Sam\n\n'
          '### Key Decisions\n'
          '- Use Serverpod for the backend (Dart everywhere)\n'
          '- Flutter web as the primary client, Android as secondary\n'
          '- PostgreSQL for persistence, Redis for real-time events\n\n'
          '### Action Items\n'
          '1. Set up CI/CD pipeline\n'
          '2. Design the channel data model\n'
          '3. Prototype the chat UI\n\n'
          '### Open Questions\n'
          '- How do we handle offline sync?\n'
          '- What\'s our media storage strategy for production?\n'
          '- Do we need end-to-end encryption?',
      minutesAgo: 960,
    );

    await addImageNote(
      general.id!,
      '',
      'splash_apollo.png',
      minutesAgo: 840,
    );

    await addNote(
      general.id!,
      'Found a great article on Dart isolates and concurrency:\n\n'
          'https://dart.dev/language/concurrency',
      minutesAgo: 720,
    );

    await addImageNote(
      general.id!,
      '',
      'splash_celeste.png',
      minutesAgo: 600,
    );

    await addNote(
      general.id!,
      'Reminder: the WebSocket connection auto-reconnects if the server '
          'restarts. No need to refresh the page manually.',
      minutesAgo: 480,
    );

    await addImageNote(
      general.id!,
      '',
      'splash_graves.png',
      minutesAgo: 360,
    );

    await addNote(
      general.id!,
      '```dart\n'
          'Future<void> main() async {\n'
          '  final pod = Serverpod(args, Protocol(), Endpoints());\n'
          '  await pod.start();\n'
          '}\n'
          '```\n\n'
          'That\'s literally all you need to start a Serverpod server.',
      minutesAgo: 300,
    );

    await addImageNote(
      general.id!,
      '',
      'splash_rem.png',
      minutesAgo: 240,
    );

    await addNote(
      general.id!,
      'Interesting comparison of state management approaches in Flutter:\n\n'
          'https://docs.flutter.dev/data-and-backend/state-mgmt/options',
      minutesAgo: 180,
    );

    await addImageNote(
      general.id!,
      '',
      'splash_silver.png',
      minutesAgo: 120,
    );

    await addImageNote(
      general.id!,
      '',
      'splash_venator.png',
      minutesAgo: 60,
    );

    await addNote(
      general.id!,
      'That wraps up the demo content. Try creating your own notes!',
      minutesAgo: 5,
    );

    general.updatedAt = now;
    await Channel.db.updateRow(session, general);
    print('   ✓ 17 notes (6 with images)');

    // ── Ideas channel ────────────────────────────────────────────
    print('📝 Populating Ideas...');

    await addNote(
      ideas.id!,
      'Add keyboard shortcuts for power users — Cmd+K for quick channel switch',
      minutesAgo: 2000,
    );

    await addNote(
      ideas.id!,
      'What if channels could have sub-channels? Like folders inside folders. '
          'Might get complex but could be useful for large projects.',
      minutesAgo: 1500,
    );

    await addNote(
      ideas.id!,
      'Markdown preview toggle — sometimes you want to see the raw text, '
          'sometimes the rendered version.',
      minutesAgo: 800,
    );

    await addNote(
      ideas.id!,
      'Export channel as PDF or Markdown file for sharing outside the app.',
      minutesAgo: 400,
    );

    await addNote(
      ideas.id!,
      'Dark/light theme toggle. The dark theme is great but some people '
          'prefer light mode during the day.',
      minutesAgo: 100,
    );

    ideas.updatedAt = now;
    await Channel.db.updateRow(session, ideas);
    print('   ✓ 5 notes');

    // ── Todos channel ────────────────────────────────────────────
    print('📝 Populating Todos...');

    await addNote(
      todos.id!,
      '[ ] Set up production server on Hetzner',
      minutesAgo: 3000,
    );

    await addNote(
      todos.id!,
      '[x] Configure Tailscale for secure remote access',
      minutesAgo: 2500,
    );

    await addNote(
      todos.id!,
      '[x] Build and test Android APK',
      minutesAgo: 2000,
    );

    await addNote(
      todos.id!,
      '[ ] Add push notifications for new notes',
      minutesAgo: 1000,
    );

    await addNote(
      todos.id!,
      '[ ] Write user documentation',
      minutesAgo: 200,
    );

    todos.updatedAt = now;
    await Channel.db.updateRow(session, todos);
    print('   ✓ 5 notes');

    // ── Done ─────────────────────────────────────────────────────
    await session.close();
    await pod.shutdown();

    print('\n✅ Demo seeded successfully!');
    print('   3 channels, 27 notes, 6 images');
    print('   Run: dart bin/main.dart');
    print('   Then visit: http://localhost:8082/app/');
  } catch (e, stackTrace) {
    print('\n❌ Error: $e');
    print(stackTrace);
    await pod.shutdown();
    exit(1);
  }
}
