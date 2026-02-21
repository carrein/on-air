import 'dart:convert';

import 'package:memoka_client/memoka_client.dart' show ServerpodClientException;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'channels_provider.dart';
import 'connection_provider.dart';
import 'notes_provider.dart';

part 'sync_engine_provider.g.dart';

/// Drains the pending mutation queue when connectivity is restored.
@Riverpod(keepAlive: true)
class SyncEngine extends _$SyncEngine {
  ConnectionState? _previousState;

  @override
  bool build() {
    ref.listen(connectionStreamProvider, (_, next) {
      final current = next.valueOrNull;
      if (_previousState != ConnectionState.connected &&
          current == ConnectionState.connected) {
        _drain();
      }
      _previousState = current;
    });
    return false; // isDraining
  }

  Future<void> _drain() async {
    if (state) return; // already draining
    state = true;

    final db = ref.read(appDatabaseProvider);
    final affectedChannelIds = <int>{};
    final mutations = await db.getPendingMutations();

    for (final m in mutations) {
      try {
        final payload = jsonDecode(m.payload) as Map<String, dynamic>;

        switch (m.type) {
          case 'createNote':
            final channelId = m.channelId!;
            final content = payload['content'] as String;
            await client.chat.createNote(channelId, content);
            affectedChannelIds.add(channelId);
            break;

          case 'createChannel':
            final name = payload['name'] as String;
            final emoji = payload['emoji'] as String;
            await client.chat.createChannel(name, emoji: emoji);
            break;

          case 'deleteNote':
            final noteId = payload['noteId'] as int;
            await client.chat.deleteNote(noteId);
            if (m.channelId != null) affectedChannelIds.add(m.channelId!);
            break;

          case 'updateChannel':
            final id = payload['id'] as int;
            await client.chat.updateChannel(
              id,
              name: payload['name'] as String?,
              emoji: payload['emoji'] as String?,
              pinned: payload['pinned'] as bool?,
            );
            break;

          case 'archiveChannel':
            final id = payload['id'] as int;
            await client.chat.archiveChannel(id);
            break;

          case 'updateNote':
            final noteId = payload['noteId'] as int;
            final content = payload['content'] as String;
            await client.chat.updateNote(noteId, content);
            if (m.channelId != null) affectedChannelIds.add(m.channelId!);
            break;

          case 'deleteChannel':
            final id = payload['id'] as int;
            await client.chat.deleteChannel(id);
            break;

          case 'reorderChannels':
            final ids = (payload['channelIds'] as List).cast<int>();
            await client.chat.reorderChannels(ids);
            break;
        }

        await db.deleteMutation(m.id);
      } catch (e) {
        // Network error (server unreachable) — stop drain, retry on reconnect.
        if (e is ServerpodClientException && e.statusCode == -1) break;

        // Server error (4xx/5xx, e.g. "Note not found") — the mutation won't
        // succeed on retry either, so discard it and continue draining.
        await db.deleteMutation(m.id);
      }
    }

    state = false;

    // Always invalidate to force a fresh server fetch after reconnect.
    // This also fixes the startup race where providers built before
    // connectionStreamProvider resolved its first value.
    ref.invalidate(channelsProvider);
    for (final channelId in affectedChannelIds) {
      ref.invalidate(notesProvider(channelId));
    }
  }
}
