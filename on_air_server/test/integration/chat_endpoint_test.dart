import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Chat endpoint', (sessionBuilder, endpoints) {
    group('Channel operations', () {
      test('getChannels returns channels sorted by updatedAt (newest first)', () async {
        // Create test channels
        await endpoints.chat.createChannel(sessionBuilder, 'First', emoji: '💬');
        await endpoints.chat.createChannel(sessionBuilder, 'Second', emoji: '📝');

        final channels = await endpoints.chat.getChannels(sessionBuilder);

        expect(channels, isNotEmpty);
        expect(channels.length, greaterThanOrEqualTo(2));
        // Second was created later, so it should come first
        expect(channels.first.name, 'Second');
      });

      test('createChannel adds new channel and returns it', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        expect(channel.name, 'Test Channel');
        expect(channel.id, isNotNull);
        expect(channel.createdAt, isNotNull);
      });

      test('createChannel rejects empty name', () async {
        expect(
          () => endpoints.chat.createChannel(sessionBuilder, '', emoji: '💬'),
          throwsException,
        );
      });

      test('deleteChannel removes channel from database', () async {
        // Create two channels (need at least 2 to allow deletion)
        await endpoints.chat.createChannel(sessionBuilder, 'Keep', emoji: '✅');
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'To Delete',
          emoji: '🗑️',
        );

        await endpoints.chat.deleteChannel(sessionBuilder, channel.id!);

        final channels = await endpoints.chat.getChannels(sessionBuilder);
        expect(channels.any((c) => c.id == channel.id), isFalse);
      });

      test('deleteChannel rejects if last remaining channel', () async {
        // Create a single channel
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Only Channel',
          emoji: '💬',
        );

        // Try to delete it (should fail as it's the only one)
        expect(
          () => endpoints.chat.deleteChannel(sessionBuilder, channel.id!),
          throwsException,
        );
      });
    });

    group('Note operations', () {
      test('createNote adds note to channel', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Test note content',
        );

        expect(note.content, 'Test note content');
        expect(note.channelId, channel.id);
        expect(note.id, isNotNull);
      });

      test('createNote rejects empty content', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        expect(
          () => endpoints.chat.createNote(sessionBuilder, channel.id!, ''),
          throwsException,
        );
      });

      test('getNotes returns notes for channel', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        await endpoints.chat.createNote(sessionBuilder, channel.id!, 'Note 1');
        await endpoints.chat.createNote(sessionBuilder, channel.id!, 'Note 2');

        final notes = await endpoints.chat.getNotes(sessionBuilder, channel.id!, limit: 50);

        expect(notes.length, greaterThanOrEqualTo(2));
        expect(notes.every((n) => n.channelId == channel.id), isTrue);
      });

      test('getNotes with cursor pagination works', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        // Create multiple notes
        await endpoints.chat.createNote(sessionBuilder, channel.id!, 'Note 1');
        await endpoints.chat.createNote(sessionBuilder, channel.id!, 'Note 2');
        final note3 = await endpoints.chat.createNote(sessionBuilder, channel.id!, 'Note 3');

        // Get notes before note3
        final notes = await endpoints.chat.getNotes(
          sessionBuilder,
          channel.id!,
          beforeId: note3.id,
          limit: 10,
        );

        // Should not include note3
        expect(notes.any((n) => n.id == note3.id), isFalse);
        // Should have earlier notes
        expect(notes.length, greaterThanOrEqualTo(2));
      });

      test('updateNote changes content', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Original content',
        );

        final updated = await endpoints.chat.updateNote(
          sessionBuilder,
          note.id!,
          'Updated content',
        );

        expect(updated.content, 'Updated content');
        expect(updated.id, note.id);
      });

      test('updateNote rejects empty content', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Original content',
        );

        expect(
          () => endpoints.chat.updateNote(sessionBuilder, note.id!, ''),
          throwsException,
        );
      });

      test('deleteNote removes note from database', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'To delete',
        );

        await endpoints.chat.deleteNote(sessionBuilder, note.id!);

        final notes = await endpoints.chat.getNotes(sessionBuilder, channel.id!, limit: 50);
        expect(notes.any((n) => n.id == note.id), isFalse);
      });
    });

    group('Cascade delete', () {
      test('deleting channel cascades to notes', () async {
        // Create two channels (need at least 2 to allow deletion)
        await endpoints.chat.createChannel(sessionBuilder, 'Keep', emoji: '✅');
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Channel with notes',
          emoji: '📝',
        );
        await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Note in channel',
        );

        // Delete the channel
        await endpoints.chat.deleteChannel(sessionBuilder, channel.id!);

        // Notes should be gone (cascade delete)
        final notes = await endpoints.chat.getNotes(
          sessionBuilder,
          channel.id!,
          limit: 50,
        );
        expect(notes, isEmpty);
      });
    });
  });
}
