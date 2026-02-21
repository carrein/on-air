import 'dart:convert';

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
    final db = ref.read(appDatabaseProvider);
    if (db == null) return; // web — no persistent queue
    if (state) return; // already draining
    state = true;

    final mutations = await db.getPendingMutations();
    final affectedChannelIds = <int>{};

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
        }

        await db.deleteMutation(m.id);
      } catch (_) {
        // Stop drain on first failure — retry on next reconnect
        break;
      }
    }

    state = false;

    // Invalidate affected providers to pull fresh server state
    ref.invalidate(channelsProvider);
    for (final channelId in affectedChannelIds) {
      ref.invalidate(notesProvider(channelId));
    }
  }
}
