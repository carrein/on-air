import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:memoka_flutter/local_db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Channel cache', () {
    test('cacheChannels stores and retrieves channels', () async {
      final channels = [
        Channel(id: 1, name: 'General', emoji: 'chatCircle'),
        Channel(id: 2, name: 'Work', emoji: 'briefcase'),
      ];

      await db.cacheChannels(channels);
      final result = await db.getCachedChannels();

      expect(result.length, 2);
      expect(result.map((c) => c.name), containsAll(['General', 'Work']));
    });

    test('cacheChannels replaces previous cache', () async {
      await db.cacheChannels([
        Channel(id: 1, name: 'Old', emoji: 'chatCircle'),
      ]);

      await db.cacheChannels([
        Channel(id: 2, name: 'New', emoji: 'briefcase'),
      ]);

      final result = await db.getCachedChannels();
      expect(result.length, 1);
      expect(result.first.name, 'New');
    });

    test('getCachedChannels returns empty list when no cache', () async {
      final result = await db.getCachedChannels();
      expect(result, isEmpty);
    });

    test('channel properties survive serialization roundtrip', () async {
      final channel = Channel(
        id: 42,
        name: 'Pinned Channel',
        emoji: 'pushPin',
        pinned: true,
        sortOrder: 3,
      );

      await db.cacheChannels([channel]);
      final result = await db.getCachedChannels();

      expect(result.first.id, 42);
      expect(result.first.name, 'Pinned Channel');
      expect(result.first.emoji, 'pushPin');
      expect(result.first.pinned, true);
      expect(result.first.sortOrder, 3);
    });
  });

  group('Note cache', () {
    test('cacheNotes stores and retrieves notes for a channel', () async {
      final now = DateTime.now();
      final notes = [
        Note(
          id: 1,
          channelId: 10,
          content: 'Hello',
          createdAt: now,
          updatedAt: now,
        ),
        Note(
          id: 2,
          channelId: 10,
          content: 'World',
          createdAt: now.subtract(const Duration(seconds: 1)),
          updatedAt: now,
        ),
      ];

      await db.cacheNotes(10, notes);
      final result = await db.getCachedNotes(10);

      expect(result.length, 2);
      // Should be ordered by createdAt desc
      expect(result.first.content, 'Hello');
      expect(result.last.content, 'World');
    });

    test('cacheNotes replaces existing notes for same channel', () async {
      final now = DateTime.now();
      await db.cacheNotes(10, [
        Note(
          id: 1,
          channelId: 10,
          content: 'Old',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await db.cacheNotes(10, [
        Note(
          id: 2,
          channelId: 10,
          content: 'New',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final result = await db.getCachedNotes(10);
      expect(result.length, 1);
      expect(result.first.content, 'New');
    });

    test('cacheNotes does not affect other channels', () async {
      final now = DateTime.now();
      await db.cacheNotes(10, [
        Note(
          id: 1,
          channelId: 10,
          content: 'Channel 10',
          createdAt: now,
          updatedAt: now,
        ),
      ]);
      await db.cacheNotes(20, [
        Note(
          id: 2,
          channelId: 20,
          content: 'Channel 20',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      // Replacing channel 10's notes shouldn't touch channel 20
      await db.cacheNotes(10, [
        Note(
          id: 3,
          channelId: 10,
          content: 'Replaced',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final ch10 = await db.getCachedNotes(10);
      final ch20 = await db.getCachedNotes(20);

      expect(ch10.length, 1);
      expect(ch10.first.content, 'Replaced');
      expect(ch20.length, 1);
      expect(ch20.first.content, 'Channel 20');
    });

    test('getCachedNotes respects limit', () async {
      final now = DateTime.now();
      final notes = List.generate(
        10,
        (i) => Note(
          id: i + 1,
          channelId: 10,
          content: 'Note $i',
          createdAt: now.subtract(Duration(seconds: i)),
          updatedAt: now,
        ),
      );

      await db.cacheNotes(10, notes);
      final result = await db.getCachedNotes(10, limit: 3);

      expect(result.length, 3);
    });

    test('deleteCachedNote removes a specific note', () async {
      final now = DateTime.now();
      await db.cacheNotes(10, [
        Note(
          id: 1,
          channelId: 10,
          content: 'Keep',
          createdAt: now,
          updatedAt: now,
        ),
        Note(
          id: 2,
          channelId: 10,
          content: 'Delete',
          createdAt: now.subtract(const Duration(seconds: 1)),
          updatedAt: now,
        ),
      ]);

      await db.deleteCachedNote(2);
      final result = await db.getCachedNotes(10);

      expect(result.length, 1);
      expect(result.first.id, 1);
    });
  });

  group('Pending mutations', () {
    test('enqueueMutation adds mutation and returns id', () async {
      final id = await db.enqueueMutation(
        'createNote',
        10,
        '{"content":"Hello"}',
      );

      expect(id, isPositive);
    });

    test('getPendingMutations returns mutations in order', () async {
      await db.enqueueMutation('createNote', 10, '{"content":"First"}');
      await db.enqueueMutation('createNote', 10, '{"content":"Second"}');
      await db.enqueueMutation('createChannel', null, '{"name":"New"}');

      final mutations = await db.getPendingMutations();

      expect(mutations.length, 3);
      expect(mutations[0].type, 'createNote');
      expect(mutations[1].type, 'createNote');
      expect(mutations[2].type, 'createChannel');
      // IDs should be ascending
      expect(mutations[0].id, lessThan(mutations[1].id));
      expect(mutations[1].id, lessThan(mutations[2].id));
    });

    test('deleteMutation removes specific mutation', () async {
      await db.enqueueMutation('createNote', 10, '{"content":"First"}');
      final id2 = await db.enqueueMutation(
        'createNote',
        10,
        '{"content":"Second"}',
      );
      await db.enqueueMutation('createChannel', null, '{"name":"New"}');

      await db.deleteMutation(id2);

      final mutations = await db.getPendingMutations();
      expect(mutations.length, 2);
      expect(mutations.any((m) => m.id == id2), isFalse);
    });

    test('getPendingMutations returns empty when no mutations', () async {
      final mutations = await db.getPendingMutations();
      expect(mutations, isEmpty);
    });

    test('channelId is nullable for channel-level mutations', () async {
      await db.enqueueMutation('createChannel', null, '{"name":"New"}');

      final mutations = await db.getPendingMutations();
      expect(mutations.first.channelId, isNull);
    });

    test('watchPendingCount emits count changes', () async {
      final counts = <int>[];
      final sub = db.watchPendingCount().listen(counts.add);

      // Give stream time to emit initial value
      await Future.delayed(const Duration(milliseconds: 50));

      await db.enqueueMutation('createNote', 10, '{"content":"A"}');
      await Future.delayed(const Duration(milliseconds: 50));

      await db.enqueueMutation('createNote', 10, '{"content":"B"}');
      await Future.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      // Should have emitted 0, then 1, then 2
      expect(counts.first, 0);
      expect(counts.last, 2);
    });
  });
}
