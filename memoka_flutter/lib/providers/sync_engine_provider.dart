import 'dart:convert';

import 'package:memoka_client/memoka_client.dart' show ServerpodClientException;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'channels_provider.dart';
import 'chat_stream_provider.dart';
import 'connection_provider.dart';
import 'notes_provider.dart';

part 'sync_engine_provider.g.dart';

/// Drains the pending mutation queue when connectivity is restored.
@Riverpod(keepAlive: true)
class SyncEngine extends _$SyncEngine {
  @override
  bool build() {
    ref.listen(connectionProvider, (prev, next) {
      if (prev != ConnectionState.connected &&
          next == ConnectionState.connected) {
        _drain();
      }
    });
    return false; // isDraining
  }

  Future<void> _drain() async {
    if (state) return; // already draining
    state = true;

    final db = ref.read(appDatabaseProvider);
    final affectedChannelIds = <int>{};
    final mutations = await db.getPendingMutations();

    // Collect all affected channel IDs upfront so notes are always
    // invalidated after drain, even if individual mutations fail.
    for (final m in mutations) {
      if (m.channelId != null) affectedChannelIds.add(m.channelId!);
    }

    var networkError = false;
    for (final m in mutations) {
      try {
        final payload = jsonDecode(m.payload) as Map<String, dynamic>;

        switch (m.type) {
          case 'createNote':
            final channelId = m.channelId!;
            final content = payload['content'] as String;
            final mutationId = payload['clientMutationId'] as String?;
            await client.chat.createNote(
              channelId,
              content,
              clientMutationId: mutationId,
            );
            break;

          case 'createChannel':
            final name = payload['name'] as String;
            final emoji = payload['emoji'] as String;
            await client.chat.createChannel(name, emoji: emoji);
            break;

          case 'deleteNote':
            final noteId = payload['noteId'] as int;
            await client.chat.deleteNote(noteId);
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
        // Network error (server unreachable) — stop drain and force a
        // reconnect cycle so the drain retries on next connection.
        // Without this, the connection stays "up" and drain never retries.
        if (e is ServerpodClientException && e.statusCode == -1) {
          networkError = true;
          break;
        }

        // Server error (4xx/5xx, e.g. "Note not found") — the mutation won't
        // succeed on retry either, so discard it and continue draining.
        await db.deleteMutation(m.id);
      }
    }

    state = false;

    if (networkError) {
      // Force a full reconnect so drain retries when the connection is
      // re-established. The cancelled flag in chatStreamProvider ensures
      // the old generator exits cleanly.
      ref.invalidate(chatStreamProvider);
      return;
    }

    // Always invalidate to force a fresh server fetch after reconnect.
    ref.invalidate(channelsProvider);
    for (final channelId in affectedChannelIds) {
      ref.invalidate(notesProvider(channelId));
    }
  }
}
