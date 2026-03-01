import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'chat_stream_provider.dart';
import 'provider_utils.dart';

part 'channels_provider.g.dart';

/// Error substring returned by the server when the last channel cannot be
/// deleted or archived. Must match [ServerConstants.lastChannelError].
const _kLastChannelError = 'last remaining channel';

/// Manages the list of channels with local-first caching and real-time updates.
@riverpod
class Channels extends _$Channels {
  /// Negative IDs for provisional offline-created channels.
  /// Use timestamp-based starting point so IDs are unique across app restarts
  /// (avoids primary key conflicts in the cache tables).
  static int _nextProvisionalId = -DateTime.now().millisecondsSinceEpoch;

  @override
  Future<List<Channel>> build() async {
    final db = ref.read(appDatabaseProvider);

    // Listen to chat stream for real-time updates
    ref.listen(chatStreamProvider, (_, event) {
      event.whenData((chatEvent) {
        if (chatEvent.type == 'channelCreated' ||
            chatEvent.type == 'channelDeleted' ||
            chatEvent.type == 'channelUpdated' ||
            chatEvent.type == 'channelArchived' ||
            chatEvent.type == 'channelRestored') {
          _refetchAndCache();
        }
      });
    });

    // 1. Load from cache and emit immediately
    final cached = await db.getCachedChannels();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    // 2. Always try to fetch from server; fall back to cache if unreachable.
    // Do not gate on isOnline(ref) — the WebSocket may not have connected yet
    // at startup, and channels must load regardless.
    try {
      final serverChannels = await client.chat.getChannels().timeout(
        const Duration(seconds: 5),
      );
      await db.cacheChannels(serverChannels);
      return serverChannels;
    } catch (_) {
      return state.value ?? [];
    }
  }

  Future<void> _refetchAndCache() async {
    try {
      final channels = await client.chat.getChannels();
      final db = ref.read(appDatabaseProvider);
      await db.cacheChannels(channels);
      state = AsyncData(channels);
    } catch (_) {
      // Keep current state on error
    }
  }

  /// Reload state directly from the local SQLite cache without a server round-trip.
  ///
  /// Used by the sync engine after a pull+push cycle so that the UI reflects
  /// the reconciled cache without ever entering [AsyncLoading] state
  /// (which would cause the navbar to flicker).
  Future<void> refreshFromCache() async {
    final db = ref.read(appDatabaseProvider);
    final cached = await db.getCachedChannels();
    state = AsyncData(cached);
  }

  Future<Channel> createChannel(
    String name, {
    String emoji = 'chatCircle',
  }) async {
    if (isOnline(ref)) {
      try {
        final channel = await client.chat.createChannel(name, emoji: emoji);
        final current = state.value ?? [];
        final updated = [...current, channel];
        state = AsyncData(updated);
        final db = ref.read(appDatabaseProvider);
        await db.cacheChannels(updated);
        return channel;
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Network error — fall through to offline path
      }
    }

    // Offline: write provisional channel as dirty+isNew to cache
    final db = ref.read(appDatabaseProvider);
    final mutationId = const Uuid().v4();
    final current = state.value ?? [];
    final maxSort = current.fold<int>(
      0,
      (m, c) => c.sortOrder > m ? c.sortOrder : m,
    );
    final provisionalId = _nextProvisionalId--;
    final provisional = Channel(
      id: provisionalId,
      name: name,
      emoji: emoji,
      sortOrder: maxSort + 1,
    );
    final provisionalJson = jsonEncode(provisional.toJson());

    await db.insertOfflineChannel(provisionalId, provisionalJson, mutationId);

    final updated = [...current, provisional];
    state = AsyncData(updated);
    return provisional;
  }

  Future<void> updateChannel(
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) async {
    // Optimistic local update FIRST — prevents flicker from the WebSocket
    // echo that arrives while the network call is in flight.
    final previous = state.value ?? [];
    final updated = previous.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        name: name ?? c.name,
        emoji: emoji ?? c.emoji,
        pinned: pinned ?? c.pinned,
      );
    }).toList();
    state = AsyncData(updated);

    if (isOnline(ref)) {
      try {
        await client.chat.updateChannel(
          id,
          name: name,
          emoji: emoji,
          pinned: pinned,
        );
        final db = ref.read(appDatabaseProvider);
        await db.cacheChannels(updated);
        return;
      } catch (e) {
        if (!isNetworkError(e)) {
          // Revert optimistic update on non-network error
          state = AsyncData(previous);
          rethrow;
        }
        // Network error — fall through to offline path
      }
    }

    // Offline: persist as dirty
    final db = ref.read(appDatabaseProvider);
    final channel = updated.firstWhere(
      (c) => c.id == id,
      orElse: () => throw StateError('Channel $id not found'),
    );
    await db.upsertChannelDirty(channel);
  }

  Future<void> deleteChannel(int id) async {
    if (isOnline(ref)) {
      try {
        await client.chat.deleteChannel(id);
      } catch (e) {
        if (e.toString().contains(_kLastChannelError)) {
          throw Exception(
            'Cannot delete the last channel. Create another channel first.',
          );
        }
        if (!isNetworkError(e)) rethrow;
        // Network error — fall through to offline mark
        final db = ref.read(appDatabaseProvider);
        await db.markChannelDeletedLocally(id);
      }
    } else {
      final db = ref.read(appDatabaseProvider);
      await db.markChannelDeletedLocally(id);
    }

    final current = state.value ?? [];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncData(updated);
  }

  Future<void> reorderChannels(List<int> channelIds) async {
    // Optimistically update local state to prevent flicker
    final current = state.value;
    List<Channel>? reordered;
    if (current != null) {
      final idToChannel = {for (final c in current) c.id: c};
      reordered = <Channel>[];
      for (var i = 0; i < channelIds.length; i++) {
        final ch = idToChannel[channelIds[i]];
        if (ch != null) {
          reordered.add(ch.copyWith(sortOrder: i));
        }
      }
      for (final ch in current) {
        if (!channelIds.contains(ch.id)) {
          reordered.add(ch);
        }
      }
      reordered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = AsyncData(reordered);
    }

    final db = ref.read(appDatabaseProvider);
    if (isOnline(ref)) {
      try {
        await client.chat.reorderChannels(channelIds);
        // Server apply succeeded — update cache with fresh server data
        if (reordered != null) await db.cacheChannels(reordered);
        return;
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Network error — fall through to offline mark
      }
    }

    // Offline: mark each reordered channel as dirty
    if (reordered != null) {
      for (final ch in reordered.where((c) => channelIds.contains(c.id))) {
        await db.upsertChannelDirty(ch);
      }
    }
  }

  Future<void> archiveChannel(int id) async {
    if (isOnline(ref)) {
      try {
        await client.chat.archiveChannel(id);
      } catch (e) {
        if (e.toString().contains(_kLastChannelError)) {
          throw Exception(
            'Cannot archive the last channel. Create another channel first.',
          );
        }
        if (!isNetworkError(e)) rethrow;
        // Network error — mark as dirty offline
        await _archiveChannelOffline(id);
        return;
      }
    } else {
      await _archiveChannelOffline(id);
      return;
    }

    // Online success: remove from local state
    final current = state.value ?? [];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncData(updated);
    final db = ref.read(appDatabaseProvider);
    await db.cacheChannels(updated);
  }

  Future<void> _archiveChannelOffline(int id) async {
    final current = state.value ?? [];
    final channel = current.firstWhere(
      (c) => c.id == id,
      orElse: () => throw StateError('Channel $id not found'),
    );
    final archived = channel.copyWith(
      archived: true,
      archivedAt: DateTime.now(),
    );

    final db = ref.read(appDatabaseProvider);
    await db.upsertChannelDirty(archived);

    final updated = current.where((c) => c.id != id).toList();
    state = AsyncData(updated);
  }
}
