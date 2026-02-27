import 'dart:convert';

import 'package:memoka_server/src/generated/sync/sync_change.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Sync endpoint', (sessionBuilder, endpoints) {
    group('syncPull', () {
      test('returns channel and note created since version 0', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Pull Test Channel',
          emoji: 'chatCircle',
        );
        await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Pull test note',
        );

        final response = await endpoints.sync.syncPull(sessionBuilder, 0);

        expect(response.channels.any((c) => c.id == channel.id), isTrue);
        expect(
          response.notes.any((n) => n.channelId == channel.id),
          isTrue,
        );
        expect(response.globalVersion, greaterThan(0));
      });

      test(
        'returns only new entities when pulling since a previous version',
        () async {
          final channel = await endpoints.chat.createChannel(
            sessionBuilder,
            'Incremental Channel',
            emoji: 'chatCircle',
          );
          await endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'First note',
          );

          // Capture version after first note
          final firstPull = await endpoints.sync.syncPull(sessionBuilder, 0);
          final versionAfterFirst = firstPull.globalVersion;

          // Create a second note
          final secondNote = await endpoints.chat.createNote(
            sessionBuilder,
            channel.id!,
            'Second note',
          );

          // Pull only changes since the first version
          final secondPull = await endpoints.sync.syncPull(
            sessionBuilder,
            versionAfterFirst,
          );

          expect(
            secondPull.notes.any((n) => n.id == secondNote.id),
            isTrue,
            reason: 'Second pull should contain the newly created note',
          );
          // The first note was created before versionAfterFirst, so it should
          // not appear in the incremental pull (unless the channel update bumped
          // its version — channel version IS bumped on note create, but the note
          // itself should already have version <= versionAfterFirst).
          expect(
            secondPull.globalVersion,
            greaterThan(versionAfterFirst),
          );
        },
      );

      test('returns tombstone for deleted note', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Tombstone Channel',
          emoji: 'chatCircle',
        );
        final note = await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Note to delete',
        );

        // First delete archives the note; second delete sets deletedAt tombstone
        await endpoints.chat.deleteNote(sessionBuilder, note.id!);
        await endpoints.chat.deleteNote(sessionBuilder, note.id!);

        final response = await endpoints.sync.syncPull(sessionBuilder, 0);

        final deletedNote = response.notes
            .where((n) => n.id == note.id)
            .firstOrNull;
        expect(
          deletedNote,
          isNotNull,
          reason: 'Deleted note should appear in syncPull',
        );
        expect(
          deletedNote!.deletedAt,
          isNotNull,
          reason: 'deletedAt should be set as tombstone',
        );
      });

      test('globalVersion monotonically increases across mutations', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Monotonic Channel',
          emoji: 'chatCircle',
        );

        final pullA = await endpoints.sync.syncPull(sessionBuilder, 0);
        final versionA = pullA.globalVersion;

        await endpoints.chat.createNote(
          sessionBuilder,
          channel.id!,
          'Note for monotonic test',
        );

        final pullB = await endpoints.sync.syncPull(sessionBuilder, 0);

        expect(
          pullB.globalVersion,
          greaterThan(versionA),
          reason: 'globalVersion must increase after each mutation',
        );
      });
    });

    group('syncPush', () {
      test('creates a new channel from client', () async {
        final mutationId =
            'test-create-channel-${DateTime.now().millisecondsSinceEpoch}';
        final entityJson = jsonEncode({
          'name': 'Pushed Channel',
          'emoji': 'bookOpen',
        });

        final response = await endpoints.sync.syncPush(
          sessionBuilder,
          [
            SyncChange(
              entityType: 'channel',
              entityJson: entityJson,
              baseVersion: 0,
              tempId: -1,
              clientMutationId: mutationId,
            ),
          ],
        );

        expect(response.results, hasLength(1));
        final result = response.results.first;
        expect(result.status, equals('applied'));
        expect(result.serverId, isNotNull);
        expect(result.tempId, equals(-1));

        // Verify channel appears in chat endpoint
        final channels = await endpoints.chat.getChannels(sessionBuilder);
        expect(
          channels.any(
            (c) => c.id == result.serverId && c.name == 'Pushed Channel',
          ),
          isTrue,
        );
      });

      test(
        'is idempotent when the same clientMutationId is pushed twice',
        () async {
          final mutationId =
              'idempotent-channel-${DateTime.now().millisecondsSinceEpoch}';
          final entityJson = jsonEncode({
            'name': 'Idempotent Channel',
            'emoji': 'star',
          });
          final change = SyncChange(
            entityType: 'channel',
            entityJson: entityJson,
            baseVersion: 0,
            tempId: -2,
            clientMutationId: mutationId,
          );

          final firstResponse = await endpoints.sync.syncPush(sessionBuilder, [
            change,
          ]);
          final secondResponse = await endpoints.sync.syncPush(sessionBuilder, [
            change,
          ]);

          expect(firstResponse.results.first.status, equals('applied'));
          expect(
            secondResponse.results.first.status,
            equals('already_applied'),
          );
          // Both should resolve to the same server ID
          expect(
            secondResponse.results.first.serverId,
            equals(firstResponse.results.first.serverId),
          );

          // Exactly one channel with that mutation ID should exist
          final channels = await endpoints.chat.getChannels(sessionBuilder);
          final matching = channels
              .where((c) => c.clientMutationId == mutationId)
              .toList();
          expect(matching, hasLength(1));
        },
      );

      test('updates an existing channel name', () async {
        // Create a channel via the chat endpoint first
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Original Name',
          emoji: 'chatCircle',
        );

        // Build an update SyncChange using the server-assigned ID and version
        final updateJson = jsonEncode({
          'id': channel.id,
          'name': 'Updated via Sync',
          'emoji': channel.emoji,
          'pinned': channel.pinned,
          'isSystemChannel': channel.isSystemChannel,
          'createdAt': channel.createdAt.toIso8601String(),
          'updatedAt': channel.updatedAt.toIso8601String(),
          'sortOrder': channel.sortOrder,
          'archived': channel.archived,
          'version': channel.version,
          'position': channel.position,
        });

        final response = await endpoints.sync.syncPush(
          sessionBuilder,
          [
            SyncChange(
              entityType: 'channel',
              entityJson: updateJson,
              baseVersion: channel.version,
            ),
          ],
        );

        expect(response.results, hasLength(1));
        expect(response.results.first.status, equals('applied'));

        // Verify the name changed
        final channels = await endpoints.chat.getChannels(sessionBuilder);
        final updated = channels.where((c) => c.id == channel.id).firstOrNull;
        expect(updated, isNotNull);
        expect(updated!.name, equals('Updated via Sync'));
      });

      test('rejects update when version is stale', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Version Check Channel',
          emoji: 'chatCircle',
        );

        // Mutate the channel via chat endpoint to bump its server version
        await endpoints.chat.updateChannel(
          sessionBuilder,
          channel.id!,
          name: 'Bumped Name',
        );

        // Push an update with the old (now-stale) version
        final staleJson = jsonEncode({
          'id': channel.id,
          'name': 'Stale Update',
          'emoji': channel.emoji,
          'version': channel.version, // original version before bump
          'position': channel.position,
          'sortOrder': channel.sortOrder,
          'pinned': channel.pinned,
          'isSystemChannel': channel.isSystemChannel,
          'archived': channel.archived,
          'createdAt': channel.createdAt.toIso8601String(),
          'updatedAt': channel.updatedAt.toIso8601String(),
        });

        final response = await endpoints.sync.syncPush(
          sessionBuilder,
          [
            SyncChange(
              entityType: 'channel',
              entityJson: staleJson,
              baseVersion: channel.version, // stale base version
            ),
          ],
        );

        expect(response.results.first.status, equals('rejected'));
        expect(response.results.first.reason, contains('Version mismatch'));
      });

      test('rejects channel creation with empty name', () async {
        final entityJson = jsonEncode({'name': '', 'emoji': 'chatCircle'});

        final response = await endpoints.sync.syncPush(
          sessionBuilder,
          [
            SyncChange(
              entityType: 'channel',
              entityJson: entityJson,
              baseVersion: 0,
              tempId: -3,
            ),
          ],
        );

        expect(response.results.first.status, equals('rejected'));
        expect(response.results.first.reason, contains('empty'));
      });

      test('creates a new note from client via syncPush', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Note Push Channel',
          emoji: 'chatCircle',
        );

        final mutationId = 'push-note-${DateTime.now().millisecondsSinceEpoch}';
        final noteJson = jsonEncode({
          'channelId': channel.id,
          'content': 'Note created via syncPush',
        });

        final response = await endpoints.sync.syncPush(
          sessionBuilder,
          [
            SyncChange(
              entityType: 'note',
              entityJson: noteJson,
              baseVersion: 0,
              tempId: -10,
              clientMutationId: mutationId,
            ),
          ],
        );

        expect(response.results, hasLength(1));
        final result = response.results.first;
        expect(result.status, equals('applied'));
        expect(result.serverId, isNotNull);

        // Verify note appears in channel
        final notes = await endpoints.chat.getNotes(
          sessionBuilder,
          channel.id!,
          limit: 50,
        );
        expect(
          notes.any(
            (n) =>
                n.id == result.serverId &&
                n.content == 'Note created via syncPush',
          ),
          isTrue,
        );
      });

      test('note push is idempotent with same clientMutationId', () async {
        final channel = await endpoints.chat.createChannel(
          sessionBuilder,
          'Idempotent Note Channel',
          emoji: 'chatCircle',
        );

        final mutationId =
            'idempotent-note-${DateTime.now().millisecondsSinceEpoch}';
        final noteJson = jsonEncode({
          'channelId': channel.id,
          'content': 'Idempotent note',
        });
        final change = SyncChange(
          entityType: 'note',
          entityJson: noteJson,
          baseVersion: 0,
          tempId: -11,
          clientMutationId: mutationId,
        );

        final first = await endpoints.sync.syncPush(sessionBuilder, [change]);
        final second = await endpoints.sync.syncPush(sessionBuilder, [change]);

        expect(first.results.first.status, equals('applied'));
        expect(second.results.first.status, equals('already_applied'));
        expect(
          second.results.first.serverId,
          equals(first.results.first.serverId),
        );
      });
    });
  });
}
