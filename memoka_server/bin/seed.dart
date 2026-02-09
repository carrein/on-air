import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../lib/src/generated/protocol.dart';
import '../lib/src/generated/endpoints.dart';

/// Resets the database to a clean state and seeds sample data.
///
/// Usage: dart run bin/seed.dart
///
/// WARNING: This will DELETE ALL existing data!
void main(List<String> args) async {
  print('🌱 Memoka Database Reset & Seed');
  print('━' * 50);
  print('⚠️  WARNING: This will DELETE ALL existing data!');
  print('   - All channels and notes will be removed');
  print('   - All uploaded media files will be deleted');
  print('   - Fresh sample data will be seeded');
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

    print('🗑️  Clearing existing data...');

    // Delete all media files
    final mediaDir = Directory('data/media');
    if (await mediaDir.exists()) {
      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          await entity.delete();
        }
      }
      print('   ✓ Deleted media files');
    }

    // Truncate tables (CASCADE will handle foreign keys)
    await session.db.unsafeQuery('TRUNCATE TABLE channels CASCADE');
    print('   ✓ Cleared channels table');

    await session.db.unsafeQuery('TRUNCATE TABLE notes CASCADE');
    print('   ✓ Cleared notes table');

    await session.db.unsafeQuery('TRUNCATE TABLE media_attachments CASCADE');
    print('   ✓ Cleared media_attachments table');

    print('\n🌱 Seeding sample data...');

    // Create sample channels
    final channels = [
      Channel(name: 'General', emoji: '💬', pinned: true),
      Channel(name: 'Ideas', emoji: '💡'),
      Channel(name: 'Tasks', emoji: '✅'),
      Channel(name: 'Notes', emoji: '📝'),
      Channel(name: 'Links', emoji: '🔗'),
      Channel(name: 'Load Test', emoji: '🧪'),
      // Additional channels for scrolling test
      Channel(name: 'Project Alpha', emoji: '🚀'),
      Channel(name: 'Resources', emoji: '📚'),
      Channel(name: 'Design', emoji: '🎨'),
      Channel(name: 'Development', emoji: '💻'),
      Channel(name: 'Marketing', emoji: '📢'),
      Channel(name: 'Sales', emoji: '💰'),
      Channel(name: 'Support', emoji: '🛟'),
      Channel(name: 'Feedback', emoji: '💬'),
      Channel(name: 'Archive', emoji: '📦'),
      Channel(name: 'Personal', emoji: '👤'),
      Channel(name: 'Team Chat', emoji: '👥'),
      Channel(name: 'Announcements', emoji: '📣'),
      Channel(name: 'Random', emoji: '🎲'),
      Channel(name: 'Water Cooler', emoji: '☕'),
      Channel(name: 'Meetings', emoji: '📅'),
      Channel(name: 'Goals', emoji: '🎯'),
      Channel(name: 'Wins', emoji: '🏆'),
      Channel(name: 'Questions', emoji: '❓'),
      Channel(name: 'Bugs', emoji: '🐛'),
      Channel(name: 'Features', emoji: '✨'),
    ];

    final createdChannels = <Channel>[];
    for (final channel in channels) {
      final saved = await Channel.db.insertRow(session, channel);
      createdChannels.add(saved);
      print('   ✓ Created channel: ${saved.emoji} ${saved.name}');
    }

    // Sample note templates
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
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
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

    // Seed notes across channels with varying dates
    var totalNotes = 0;
    final now = DateTime.now();

    for (var i = 0; i < createdChannels.length; i++) {
      final channel = createdChannels[i];
      // Load Test channel gets 500 notes, first 6 channels get notes, rest are empty
      final noteCount = channel.name == 'Load Test'
          ? 500
          : i < 6 ? 10 + (i * 8) : 0;

      for (var j = 0; j < noteCount; j++) {
        final template = noteTemplates[j % noteTemplates.length];
        final content = j == 0
            ? 'Welcome to ${channel.emoji} ${channel.name}!'
            : '$template (#${j + 1})';

        // Spread notes across last 10 years (oldest first)
        // Using logarithmic distribution for more recent density
        final maxDays = 3650; // ~10 years
        final progress = j / noteCount; // 0.0 to 1.0

        // Logarithmic distribution: more notes in recent days, fewer in distant past
        // Using exponential decay: most recent notes are densest
        final daysAgo = (maxDays * (1 - progress * progress)).floor();
        final hoursOffset = (j % 10) * 2; // Vary hours within each day
        final createdAt = now.subtract(Duration(days: daysAgo, hours: hoursOffset));

        final note = Note(channelId: channel.id!, content: content);
        note.createdAt = createdAt;

        await Note.db.insertRow(session, note);
        totalNotes++;
      }

      // Update channel timestamp
      channel.updatedAt = DateTime.now();
      await Channel.db.updateRow(session, channel);

      if (channel.name == 'Load Test') {
        print('   ✓ Created ${noteCount} notes in ${channel.emoji} ${channel.name} (for pagination testing)');
      }
    }

    print('   ✓ Created $totalNotes total notes across ${createdChannels.length} channels');

    await session.close();
    await pod.shutdown();

    print('\n✅ Database reset and seeded successfully!');
    print('   Run: dart bin/main.dart');
    print('   Then visit: http://localhost:8082/app/');

  } catch (e, stackTrace) {
    print('\n❌ Error: $e');
    print(stackTrace);
    await pod.shutdown();
    exit(1);
  }
}
