import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'chat_stream_provider.dart';
import 'connection_provider.dart';
import 'provider_utils.dart';

part 'archive_items_provider.g.dart';

/// Manages the mixed archive list (notes + channels) with real-time updates.
@riverpod
class ArchiveItems extends _$ArchiveItems {
  @override
  Future<List<ArchiveItem>> build() async {
    final db = ref.read(appDatabaseProvider);

    ref.listen(chatStreamProvider, (_, event) {
      event.whenData((chatEvent) {
        if ([
          'noteArchived',
          'noteRestored',
          'noteDeleted',
          'channelArchived',
          'channelRestored',
          'channelDeleted',
        ].contains(chatEvent.type)) {
          _refetchAndCache();
        }
      });
    });

    // Refetch when connectivity is restored.
    ref.listen(connectionProvider, (prev, next) {
      if (prev != ConnectionState.connected &&
          next == ConnectionState.connected) {
        _refetchAndCache();
      }
    });

    // 1. Load from cache and emit immediately
    final cached = await db.getCachedArchiveItems().catchError(
      (_) => <ArchiveItem>[],
    );
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    // 2. Try server; fall back to cache if unreachable.
    try {
      final items = await client.chat.getArchiveItems(limit: 50);
      try {
        await db.cacheArchiveItems(items);
      } catch (_) {
        // Cache write failed; items still returned.
      }
      return items;
    } catch (_) {
      return state.value ?? [];
    }
  }

  Future<void> _refetchAndCache() async {
    try {
      final items = await client.chat.getArchiveItems(limit: 50);
      state = AsyncData(items);
      try {
        final db = ref.read(appDatabaseProvider);
        await db.cacheArchiveItems(items);
      } catch (_) {}
    } catch (_) {
      // Keep current state on error
    }
  }

  Future<void> restoreNote(int noteId) async {
    if (isOnline(ref)) {
      try {
        await client.chat.restoreNote(noteId);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Offline: fall through — note stays in archive locally until sync
      }
    }
    // Optimistic removal from archive list
    final current = state.value ?? [];
    final updated = current
        .where((item) => !(item.type == 'note' && item.note?.id == noteId))
        .toList();
    state = AsyncValue.data(updated);
    final db = ref.read(appDatabaseProvider);
    await db.cacheArchiveItems(updated);
  }

  Future<void> deleteNote(int noteId) async {
    if (isOnline(ref)) {
      try {
        await client.chat.deleteNote(noteId);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Offline: mark note as deleted locally for sync
        final db = ref.read(appDatabaseProvider);
        await db.markNoteDeletedLocally(noteId);
      }
    } else {
      final db = ref.read(appDatabaseProvider);
      await db.markNoteDeletedLocally(noteId);
    }
    // Optimistic removal
    final current = state.value ?? [];
    final updated = current
        .where((item) => !(item.type == 'note' && item.note?.id == noteId))
        .toList();
    state = AsyncValue.data(updated);
    final db = ref.read(appDatabaseProvider);
    await db.cacheArchiveItems(updated);
  }

  Future<void> restoreChannel(int channelId) async {
    if (isOnline(ref)) {
      try {
        await client.chat.restoreChannel(channelId);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Offline: fall through
      }
    }
    final current = state.value ?? [];
    final updated = current
        .where(
          (item) => !(item.type == 'channel' && item.channel?.id == channelId),
        )
        .toList();
    state = AsyncValue.data(updated);
    final db = ref.read(appDatabaseProvider);
    await db.cacheArchiveItems(updated);
  }

  Future<void> deleteChannel(int channelId) async {
    if (isOnline(ref)) {
      try {
        await client.chat.deleteChannel(channelId);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Offline: mark channel as deleted locally for sync
        final db = ref.read(appDatabaseProvider);
        await db.markChannelDeletedLocally(channelId);
      }
    } else {
      final db = ref.read(appDatabaseProvider);
      await db.markChannelDeletedLocally(channelId);
    }
    final current = state.value ?? [];
    final updated = current
        .where(
          (item) => !(item.type == 'channel' && item.channel?.id == channelId),
        )
        .toList();
    state = AsyncValue.data(updated);
    final db = ref.read(appDatabaseProvider);
    await db.cacheArchiveItems(updated);
  }
}
