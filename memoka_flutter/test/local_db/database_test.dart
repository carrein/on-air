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

  group('Dirty tracking', () {
    test('getDirtyChannels returns only dirty channels', () async {
      await db.cacheChannels([
        Channel(id: 1, name: 'Clean', emoji: 'chatCircle'),
      ]);
      await db.upsertChannelDirty(
        Channel(id: 2, name: 'Dirty', emoji: 'briefcase'),
      );

      final dirty = await db.getDirtyChannels();
      expect(dirty.length, 1);
      expect(dirty.first.id, 2);
    });

    test('cacheChannels preserves dirty channels', () async {
      // Create a dirty channel first
      await db.insertOfflineChannel(-1, '{"id":-1,"name":"Offline"}', 'mut1');

      // Server refresh should not destroy the dirty row
      await db.cacheChannels([
        Channel(id: 1, name: 'Server', emoji: 'chatCircle'),
      ]);

      final dirty = await db.getDirtyChannels();
      expect(dirty.length, 1);
      expect(dirty.first.id, -1);
    });

    test('markChannelDeletedLocally sets dirty and deletedLocally', () async {
      await db.cacheChannels([
        Channel(id: 1, name: 'General', emoji: 'chatCircle'),
      ]);
      await db.markChannelDeletedLocally(1);

      final dirty = await db.getDirtyChannels();
      expect(dirty.length, 1);
      expect(dirty.first.deletedLocally, true);

      // Should be excluded from getCachedChannels
      final channels = await db.getCachedChannels();
      expect(channels, isEmpty);
    });

    test('watchDirtyCount emits count changes', () async {
      final counts = <int>[];
      final sub = db.watchDirtyCount().listen(counts.add);

      await Future.delayed(const Duration(milliseconds: 50));

      await db.upsertChannelDirty(
        Channel(id: 1, name: 'Dirty', emoji: 'chatCircle'),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      final now = DateTime.now();
      await db.upsertNoteDirty(
        Note(id: 1, channelId: 1, content: 'Dirty', createdAt: now, updatedAt: now),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      await sub.cancel();

      expect(counts.first, 0);
      expect(counts.last, 2);
    });

    test('clearChannelDirty resets flags and updates version', () async {
      await db.upsertChannelDirty(
        Channel(id: 1, name: 'Dirty', emoji: 'chatCircle'),
      );
      await db.clearChannelDirty(1, 42);

      final dirty = await db.getDirtyChannels();
      expect(dirty, isEmpty);
    });
  });
}
