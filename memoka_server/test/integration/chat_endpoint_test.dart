import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Chat endpoint', (sessionBuilder, endpoints) {
    group('Channel operations', () {
      test(
        'getChannels returns channels sorted by sortOrder ascending',
        () async {
          // Create test channels (each gets incrementing sortOrder)
          await endpoints.chat.createChannel(
            sessionBuilder,
            'First',
            emoji: '💬',
          );
          await endpoints.chat.createChannel(
            sessionBuilder,
            'Second',
            emoji: '📝',
          );

          final channels = await endpoints.chat.getChannels(sessionBuilder);

          expect(channels, isNotEmpty);
          expect(channels.length, greaterThanOrEqualTo(2));
          // First has sortOrder=0, Second has sortOrder=1
          expect(channels.first.name, 'First');
        },
      );

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

        final notes = await endpoints.chat.getNotes(
          sessionBuilder,
          channel.id!,
          limit: 50,
        );

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
        final note3 = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Note 3',
        );

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

      test('deleteNote archives note (soft delete)', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'To archive',
        );

        // First delete archives the note
        await endpoints.chat.deleteNote(sessionBuilder, note.id!);

        // Note should no longer appear in channel notes
        final notes = await endpoints.chat.getNotes(
          sessionBuilder,
          channel.id!,
          limit: 50,
        );
        expect(notes.any((n) => n.id == note.id), isFalse);

        // Note should appear in archive items
        final archiveItems = await endpoints.chat.getArchiveItems(
          sessionBuilder,
          limit: 50,
        );
        expect(archiveItems.any((item) => item.note?.id == note.id), isTrue);
      });

      test('deleteNote permanently deletes archived note', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'To permanently delete',
        );

        // First delete archives
        await endpoints.chat.deleteNote(sessionBuilder, note.id!);
        // Second delete permanently removes
        await endpoints.chat.deleteNote(sessionBuilder, note.id!);

        // Note should be gone from archive
        final archiveItems = await endpoints.chat.getArchiveItems(
          sessionBuilder,
          limit: 50,
        );
        expect(archiveItems.any((item) => item.note?.id == note.id), isFalse);
      });

      test('restoreNote moves note back to channel', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'To restore',
        );

        // Archive it
        await endpoints.chat.deleteNote(sessionBuilder, note.id!);

        // Restore it
        await endpoints.chat.restoreNote(sessionBuilder, note.id!);

        // Note should reappear in channel
        final notes = await endpoints.chat.getNotes(
          sessionBuilder,
          channel.id!,
          limit: 50,
        );
        expect(notes.any((n) => n.id == note.id), isTrue);
      });
    });

    group('Boundary / edge cases', () {
      test('createNote rejects content exceeding 200,000 characters', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Test Channel',
          emoji: '💬',
        );

        expect(
          () => endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'a' * 200001,
          ),
          throwsException,
        );
      });

      test('updateNote rejects content exceeding 200,000 characters', () async {
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
          () => endpoints.chat.updateNote(
            sessionBuilder,
            note.id!,
            'a' * 200001,
          ),
          throwsException,
        );
      });

      test('createChannel rejects emoji exceeding 30 characters', () async {
        expect(
          () => endpoints.chat.createChannel(
            sessionBuilder,
            'Test Channel',
            emoji: 'a' * 31,
          ),
          throwsException,
        );
      });

      test(
        'restoreNote throws for a note that is not archived',
        () async {
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'Test Channel',
            emoji: '💬',
          );

          // Create a note but do NOT archive it
          final note = await endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'Not archived note',
          );

          expect(
            () => endpoints.chat.restoreNote(sessionBuilder, note.id!),
            throwsException,
          );
        },
      );

      test(
        'createNote throws for a non-existent channel ID',
        () async {
          expect(
            () => endpoints.chat.createNote(
              sessionBuilder,
              999999,
              'Note for missing channel',
            ),
            throwsException,
          );
        },
      );
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
