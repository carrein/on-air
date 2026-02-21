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
  static int _nextProvisionalId = -1;

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

    // 1. Load from cache and emit immediately (native only)
    if (db != null) {
      final cached = await db.getCachedChannels();
      if (cached.isNotEmpty) {
        state = AsyncData(cached);
      }
    }

    // 2. Try to fetch from server
    if (_isOnline) {
      try {
        final serverChannels = await client.chat.getChannels();
        await db?.cacheChannels(serverChannels);
        return serverChannels;
      } catch (_) {
        final cached = state.valueOrNull;
        if (cached != null && cached.isNotEmpty) return cached;
        rethrow;
      }
    }

    return state.valueOrNull ?? [];
  }

  bool get _isOnline {
    final conn = ref.read(connectionStreamProvider);
    return conn.valueOrNull == ConnectionState.connected;
  }

  Future<void> _refetchAndCache() async {
    try {
      final channels = await client.chat.getChannels();
      final db = ref.read(appDatabaseProvider);
      await db?.cacheChannels(channels);
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
      final channel = await client.chat.createChannel(name, emoji: emoji);
      return channel;
    }

    // Offline: enqueue mutation and add provisional channel
    final db = ref.read(appDatabaseProvider);
    await db?.enqueueMutation(
      'createChannel',
      null,
      jsonEncode({'name': name, 'emoji': emoji}),
    );

    final provisional = Channel(
      id: _nextProvisionalId--,
      name: name,
      emoji: emoji,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, provisional]);
    return provisional;
  }

  Future<void> updateChannel(
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) async {
    if (_isOnline) {
      await client.chat.updateChannel(
        id,
        name: name,
        emoji: emoji,
        pinned: pinned,
      );
      return;
    }

    // Offline: enqueue
    final db = ref.read(appDatabaseProvider);
    final payload = <String, dynamic>{'id': id};
    if (name != null) payload['name'] = name;
    if (emoji != null) payload['emoji'] = emoji;
    if (pinned != null) payload['pinned'] = pinned;
    await db?.enqueueMutation('updateChannel', id, jsonEncode(payload));

    // Optimistic local update
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((c) {
        if (c.id != id) return c;
        return c.copyWith(
          name: name ?? c.name,
          emoji: emoji ?? c.emoji,
          pinned: pinned ?? c.pinned,
        );
      }).toList(),
    );
  }

  Future<void> deleteChannel(int id) async {
    try {
      await client.chat.deleteChannel(id);
    } catch (e) {
      if (e.toString().contains('last remaining channel')) {
        throw Exception(
          'Cannot delete the last channel. Create another channel first.',
        );
      }
      rethrow;
    }
  }

  Future<void> reorderChannels(List<int> channelIds) async {
    // Optimistically update local state to prevent flicker
    final current = state.valueOrNull;
    if (current != null) {
      final idToChannel = {for (final c in current) c.id: c};
      final reordered = <Channel>[];
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

    await client.chat.reorderChannels(channelIds);
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
        rethrow;
      }
      return;
    }

    // Offline: enqueue
    final db = ref.read(appDatabaseProvider);
    await db?.enqueueMutation('archiveChannel', id, jsonEncode({'id': id}));

    // Remove from local state
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }
}
