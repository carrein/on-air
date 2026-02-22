import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'chat_stream_provider.dart';
import 'connection_provider.dart';

part 'channels_provider.g.dart';

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

    // Refetch when connectivity is restored to catch missed WebSocket events.
    ref.listen(connectionProvider, (prev, next) {
      if (prev != ConnectionState.connected &&
          next == ConnectionState.connected) {
        _refetchAndCache();
      }
    });

    // 1. Load from cache and emit immediately
    final cached = await db.getCachedChannels();
    if (cached.isNotEmpty) {
      state = AsyncData(cached);
    }

    // 2. Always try to fetch from server; fall back to cache if unreachable.
    // Do not gate on _isOnline — the WebSocket may not have connected yet
    // at startup, and channels must load regardless.
    try {
      final serverChannels = await client.chat.getChannels();
      await db.cacheChannels(serverChannels);
      return serverChannels;
    } catch (_) {
      return state.valueOrNull ?? [];
    }
  }

  bool get _isOnline =>
      ref.read(connectionProvider) == ConnectionState.connected;

  /// Returns true for network-level failures (server unreachable, timeout).
  /// These should fall back to the offline queue rather than surfacing an error.
  bool _isNetworkError(Object e) =>
      e is ServerpodClientException && e.statusCode == -1;

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

  Future<Channel> createChannel(
    String name, {
    String emoji = 'chatCircle',
  }) async {
    if (_isOnline) {
      try {
        final channel = await client.chat.createChannel(name, emoji: emoji);
        final current = state.valueOrNull ?? [];
        final updated = [...current, channel];
        state = AsyncData(updated);
        final db = ref.read(appDatabaseProvider);
        await db.cacheChannels(updated);
        return channel;
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Network error — fall through to offline path
      }
    }

    // Offline: enqueue mutation and add provisional channel
    final db = ref.read(appDatabaseProvider);
    await db.enqueueMutation(
      'createChannel',
      null,
      jsonEncode({'name': name, 'emoji': emoji}),
    );

    final current = state.valueOrNull ?? [];
    final maxSort = current.fold<int>(
      0,
      (m, c) => c.sortOrder > m ? c.sortOrder : m,
    );
    final provisional = Channel(
      id: _nextProvisionalId--,
      name: name,
      emoji: emoji,
      sortOrder: maxSort + 1,
    );
    final updated = [...current, provisional];
    state = AsyncData(updated);

    // Persist to cache so provisional channels survive page refresh.
    await db.cacheChannels(updated);
    return provisional;
  }

  Future<void> updateChannel(
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) async {
    if (_isOnline) {
      try {
        await client.chat.updateChannel(
          id,
          name: name,
          emoji: emoji,
          pinned: pinned,
        );
        // Optimistic local update + cache so changes survive hard refresh
        final current = state.valueOrNull ?? [];
        final updated = current.map((c) {
          if (c.id != id) return c;
          return c.copyWith(
            name: name ?? c.name,
            emoji: emoji ?? c.emoji,
            pinned: pinned ?? c.pinned,
          );
        }).toList();
        state = AsyncData(updated);
        final db = ref.read(appDatabaseProvider);
        await db.cacheChannels(updated);
        return;
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Network error — fall through to offline path
      }
    }

    // Offline: enqueue
    final db = ref.read(appDatabaseProvider);
    final payload = <String, dynamic>{'id': id};
    if (name != null) payload['name'] = name;
    if (emoji != null) payload['emoji'] = emoji;
    if (pinned != null) payload['pinned'] = pinned;
    await db.enqueueMutation('updateChannel', id, jsonEncode(payload));

    // Optimistic local update
    final current = state.valueOrNull ?? [];
    final updated = current.map((c) {
      if (c.id != id) return c;
      return c.copyWith(
        name: name ?? c.name,
        emoji: emoji ?? c.emoji,
        pinned: pinned ?? c.pinned,
      );
    }).toList();
    state = AsyncData(updated);

    // Persist to cache so changes survive page refresh.
    await db.cacheChannels(updated);
  }

  Future<void> deleteChannel(int id) async {
    if (_isOnline) {
      try {
        await client.chat.deleteChannel(id);
      } catch (e) {
        if (e.toString().contains('last remaining channel')) {
          throw Exception(
            'Cannot delete the last channel. Create another channel first.',
          );
        }
        if (!_isNetworkError(e)) rethrow;
        // Network error — fall through to enqueue
        final db = ref.read(appDatabaseProvider);
        await db.enqueueMutation(
          'deleteChannel',
          null,
          jsonEncode({'id': id}),
        );
      }
    } else {
      final db = ref.read(appDatabaseProvider);
      await db.enqueueMutation(
        'deleteChannel',
        null,
        jsonEncode({'id': id}),
      );
    }

    final current = state.valueOrNull ?? [];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncData(updated);
    final db = ref.read(appDatabaseProvider);
    await db.cacheChannels(updated);
  }

  Future<void> reorderChannels(List<int> channelIds) async {
    // Optimistically update local state to prevent flicker
    final current = state.valueOrNull;
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
    if (_isOnline) {
      try {
        await client.chat.reorderChannels(channelIds);
      } catch (e) {
        if (!_isNetworkError(e)) rethrow;
        // Network error — fall through to enqueue
        await db.enqueueMutation(
          'reorderChannels',
          null,
          jsonEncode({'channelIds': channelIds}),
        );
      }
    } else {
      await db.enqueueMutation(
        'reorderChannels',
        null,
        jsonEncode({'channelIds': channelIds}),
      );
    }
    if (reordered != null) {
      await db.cacheChannels(reordered);
    }
  }

  Future<void> archiveChannel(int id) async {
    if (_isOnline) {
      try {
        await client.chat.archiveChannel(id);
      } catch (e) {
        if (e.toString().contains('last remaining channel')) {
          throw Exception(
            'Cannot archive the last channel. Create another channel first.',
          );
        }
        if (!_isNetworkError(e)) rethrow;
        // Network error — fall through to enqueue
        final db = ref.read(appDatabaseProvider);
        await db.enqueueMutation('archiveChannel', id, jsonEncode({'id': id}));
        // Optimistic local removal
        final current = state.valueOrNull ?? [];
        final updated = current.where((c) => c.id != id).toList();
        state = AsyncData(updated);
        await db.cacheChannels(updated);
        return;
      }
      // Online success: remove from local state + cache
      final current = state.valueOrNull ?? [];
      final updated = current.where((c) => c.id != id).toList();
      state = AsyncData(updated);
      final db = ref.read(appDatabaseProvider);
      await db.cacheChannels(updated);
      return;
    }

    // Offline: enqueue
    final db = ref.read(appDatabaseProvider);
    await db.enqueueMutation('archiveChannel', id, jsonEncode({'id': id}));

    // Remove from local state and persist to cache
    final current = state.valueOrNull ?? [];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncData(updated);
    await db.cacheChannels(updated);
  }
}
