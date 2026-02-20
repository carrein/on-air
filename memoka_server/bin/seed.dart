// ignore_for_file: avoid_print
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:memoka_server/src/generated/endpoints.dart';
import 'package:memoka_server/src/generated/protocol.dart';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';

/// Resets the database and seeds sample data.
///
/// Two modes:
///   demo — 3 channels with rich content and images from fixtures/demo/
///   full — 26 channels with 500+ notes for load testing
///
/// Usage: dart run bin/seed.dart
///
/// WARNING: This will DELETE ALL existing data!
void main(List<String> args) async {
  print('🌱 Memoka Seed');
  print('━' * 50);
  print('⚠️  WARNING: This will DELETE ALL existing data!');
  print('━' * 50);
  print('');
  print('  [1] demo — 3 channels, rich content + images');
  print('  [2] full — 26 channels, 500+ notes (load test)');
  print('');
  stdout.write('Choose mode (1/2): ');
  final modeInput = stdin.readLineSync()?.trim();

  final bool isDemo;
  if (modeInput == '1') {
    isDemo = true;
  } else if (modeInput == '2') {
    isDemo = false;
  } else {
    print('❌ Invalid choice. Aborted.');
    exit(0);
  }

  stdout.write('\nAre you sure? Type "yes" to continue: ');
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
        if (entity is File) await entity.delete();
      }
      print('   ✓ Deleted media files');
    }

    await session.db.unsafeQuery('TRUNCATE TABLE channels CASCADE');
    await session.db.unsafeQuery('TRUNCATE TABLE notes CASCADE');
    await session.db.unsafeQuery('TRUNCATE TABLE media_attachments CASCADE');
    print('   ✓ Cleared database tables');

    if (isDemo) {
      await _seedDemo(session);
    } else {
      await _seedFull(session);
    }

    await session.close();
    await pod.shutdown();
  } catch (e, stackTrace) {
    print('\n❌ Error: $e');
    print(stackTrace);
    await pod.shutdown();
    exit(1);
  }
}

// ── Demo seed ────────────────────────────────────────────────────────────────

Future<void> _seedDemo(Session session) async {
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

  final now = DateTime.now();
  final uuid = Uuid();
  const mediaBaseDir = 'data/media';
  final demoDir = Directory('fixtures/demo');

  Future<Note> addNote(
    int channelId,
    String content, {
    int minutesAgo = 0,
  }) async {
    final note = Note(channelId: channelId, content: content);
    note.createdAt = now.subtract(Duration(minutes: minutesAgo));
    return await Note.db.insertRow(session, note);
  }

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

    final bytes = await sourceFile.readAsBytes();
    final contentHash = sha256.convert(bytes).toString().substring(0, 8);

    int? width, height;
    if (bytes.length > 24 && bytes[0] == 0x89 && bytes[1] == 0x50) {
      width =
          (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      height =
          (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
    }

    final channelMediaDir = Directory(
      path.join(mediaBaseDir, 'channels', channelId.toString()),
    );
    if (!await channelMediaDir.exists()) {
      await channelMediaDir.create(recursive: true);
    }

    final destPath = path.join(channelMediaDir.path, '${uuid.v4()}.png');
    await sourceFile.copy(destPath);

    final note = Note(channelId: channelId, content: content);
    note.createdAt = now.subtract(Duration(minutes: minutesAgo));
    final savedNote = await Note.db.insertRow(session, note);

    await MediaAttachment.db.insertRow(
      session,
      MediaAttachment(
        noteId: savedNote.id!,
        channelId: channelId,
        filePath: path.relative(destPath, from: mediaBaseDir),
        originalFilename: demoFilename,
        mimeType: 'image/png',
        fileSize: bytes.length,
        width: width,
        height: height,
        contentHash: contentHash,
      ),
    );

    return savedNote;
  }

  // ── General ──
  print('\n📝 Populating General...');

  await addNote(
    general.id!,
    'Welcome to Memoka! 🎉\n\nThis is your personal notes space. '
    'Create channels to organize different topics, and jot down '
    'thoughts as they come.',
    minutesAgo: 1440,
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
  await addImageNote(general.id!, '', 'splash_apollo.png', minutesAgo: 840);
  await addNote(
    general.id!,
    'Found a great article on Dart isolates and concurrency:\n\n'
    'https://dart.dev/language/concurrency',
    minutesAgo: 720,
  );
  await addImageNote(general.id!, '', 'splash_celeste.png', minutesAgo: 600);
  await addNote(
    general.id!,
    'Reminder: the WebSocket connection auto-reconnects if the server '
    'restarts. No need to refresh the page manually.',
    minutesAgo: 480,
  );
  await addImageNote(general.id!, '', 'splash_graves.png', minutesAgo: 360);
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
  await addImageNote(general.id!, '', 'splash_rem.png', minutesAgo: 240);
  await addNote(
    general.id!,
    'Interesting comparison of state management approaches in Flutter:\n\n'
    'https://docs.flutter.dev/data-and-backend/state-mgmt/options',
    minutesAgo: 180,
  );
  await addImageNote(general.id!, '', 'splash_silver.png', minutesAgo: 120);
  await addImageNote(general.id!, '', 'splash_venator.png', minutesAgo: 60);
  await addNote(
    general.id!,
    'That wraps up the demo content. Try creating your own notes!',
    minutesAgo: 5,
  );

  general.updatedAt = now;
  await Channel.db.updateRow(session, general);
  print('   ✓ 16 notes (6 with images)');

  // ── Ideas ──
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

  // ── Todos ──
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
  await addNote(todos.id!, '[x] Build and test Android APK', minutesAgo: 2000);
  await addNote(
    todos.id!,
    '[ ] Add push notifications for new notes',
    minutesAgo: 1000,
  );
  await addNote(todos.id!, '[ ] Write user documentation', minutesAgo: 200);

  todos.updatedAt = now;
  await Channel.db.updateRow(session, todos);
  print('   ✓ 5 notes');

  print('\n✅ Demo seeded! 3 channels, 26 notes, 6 images.');
}

// ── Full / load-test seed ────────────────────────────────────────────────────

Future<void> _seedFull(Session session) async {
  print('\n🌱 Creating channels...');

  final channels = [
    Channel(name: 'General', emoji: 'chatCircle', pinned: true),
    Channel(name: 'Ideas', emoji: 'lightbulb'),
    Channel(name: 'Tasks', emoji: 'checkSquare'),
    Channel(name: 'Notes', emoji: 'notepad'),
    Channel(name: 'Links', emoji: 'link'),
    Channel(name: 'Load Test', emoji: 'flask'),
    Channel(name: 'Project Alpha', emoji: 'rocketLaunch'),
    Channel(name: 'Resources', emoji: 'books'),
    Channel(name: 'Design', emoji: 'palette'),
    Channel(name: 'Development', emoji: 'code'),
    Channel(name: 'Marketing', emoji: 'megaphone'),
    Channel(name: 'Sales', emoji: 'currencyCircleDollar'),
    Channel(name: 'Support', emoji: 'lifebuoy'),
    Channel(name: 'Feedback', emoji: 'chatTeardropDots'),
    Channel(name: 'Archive', emoji: 'archive'),
    Channel(name: 'Personal', emoji: 'user'),
    Channel(name: 'Team Chat', emoji: 'users'),
    Channel(name: 'Announcements', emoji: 'speakerHigh'),
    Channel(name: 'Random', emoji: 'diceFive'),
    Channel(name: 'Water Cooler', emoji: 'coffee'),
    Channel(name: 'Meetings', emoji: 'calendarBlank'),
    Channel(name: 'Goals', emoji: 'target'),
    Channel(name: 'Wins', emoji: 'trophy'),
    Channel(name: 'Questions', emoji: 'question'),
    Channel(name: 'Bugs', emoji: 'bug'),
    Channel(name: 'Features', emoji: 'sparkle'),
  ];

  final createdChannels = <Channel>[];
  for (final channel in channels) {
    final saved = await Channel.db.insertRow(session, channel);
    createdChannels.add(saved);
    print('   ✓ ${saved.name} (${saved.emoji})');
  }

  final noteTemplates = [
    'Welcome to Memoka! 🎉',
    'This is a sample note to demonstrate the chat interface.',
    'You can create channels to organize different topics.',
    'Notes support **Markdown formatting** including *italic*, **bold**, and `code`.',
    'Paste links to get automatic previews: https://serverpod.dev',
    'Upload images by dragging and dropping them into the chat.',
    'Right-click on notes to copy, edit, or delete them.',
    'Channels can be pinned to keep them at the top of the sidebar.',
    'Try creating a new note with Shift+Enter for multi-line input.',
    'The WebSocket connection keeps everything real-time.',
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
    'Short note.',
    'This is a longer note to test text wrapping in the chat bubbles. It spans multiple lines and demonstrates how the constrained width works with longer content.',
    'Testing emoji: 🚀 🎨 🔥 ⚡ 🌟',
    '# Heading 1\n## Heading 2\n### Heading 3',
    '- Bullet point 1\n- Bullet point 2\n- Bullet point 3',
    '1. Numbered item\n2. Another item\n3. And one more',
    'Inline `code` and **bold** text.',
    '[This is a link](https://flutter.dev)',
    'Code block:\n```dart\nvoid main() {\n  print("Hello!");\n}\n```',
  ];

  print('\n📝 Seeding notes...');

  var totalNotes = 0;
  final now = DateTime.now();

  for (var i = 0; i < createdChannels.length; i++) {
    final channel = createdChannels[i];
    final noteCount = channel.name == 'Load Test'
        ? 500
        : i < 6
        ? 10 + (i * 8)
        : 0;

    for (var j = 0; j < noteCount; j++) {
      final template = noteTemplates[j % noteTemplates.length];
      final content = j == 0
          ? 'Welcome to ${channel.name}!'
          : '$template (#${j + 1})';

      final daysAgo = (3650 * (1 - (j / noteCount) * (j / noteCount))).floor();
      final createdAt = now.subtract(
        Duration(days: daysAgo, hours: (j % 10) * 2),
      );

      final note = Note(channelId: channel.id!, content: content);
      note.createdAt = createdAt;
      await Note.db.insertRow(session, note);
      totalNotes++;
    }

    channel.updatedAt = DateTime.now();
    await Channel.db.updateRow(session, channel);

    if (noteCount > 0) {
      print('   ✓ ${channel.name}: $noteCount notes');
    }
  }

  print(
    '\n✅ Full seed done! ${createdChannels.length} channels, $totalNotes notes.',
  );
}
