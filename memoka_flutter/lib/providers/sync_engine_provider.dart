import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'channels_provider.dart';
import 'connection_provider.dart';

part 'sync_engine_provider.g.dart';

/// Pull-then-push sync engine driven by connectivity transitions.
///
/// On each reconnect:
///  1. Pull phase — fetch server changes since lastSyncGlobalVersion and
///     reconcile with the local cache.
///  2. Push phase — send all dirty local entities to the server.
///  3. Invalidate UI providers so fresh state is rendered.
@Riverpod(keepAlive: true)
class SyncEngine extends _$SyncEngine {
  @override
  bool build() {
    ref.listen(connectionProvider, (prev, next) {
      if (prev != ConnectionState.connected &&
          next == ConnectionState.connected) {
        _sync();
      }
    });
    return false; // isSyncing
  }

  Future<void> _sync() async {
    if (state) return; // already running
    state = true;

    try {
      await _pullPhase();
      await _pushPhase();
    } catch (_) {
      // Network error during sync — will retry on next connect transition.
    } finally {
      state = false;
    }

    // Reload channels from the local cache without going through AsyncLoading.
    // ref.invalidate() would cause channelsAsync.valueOrNull to return null for
    // one frame, collapsing the navbar Row and producing a ghost-icon flicker.
    await ref.read(channelsProvider.notifier).refreshFromCache();
  }

  Future<void> _pullPhase() async {
    final db = ref.read(appDatabaseProvider);
    final sinceVersion = await db.getGlobalVersion();

    final response = await client.sync.syncPull(sinceVersion);

    // Fetch dirty IDs once upfront (avoids N queries in the loop).
    final dirtyChannelIds = {
      for (final r in await db.getDirtyChannels()) r.id,
    };
    final dirtyNoteIds = {
      for (final r in await db.getDirtyNotes()) r.id,
    };

    // Reconcile channels
    for (final serverChannel in response.channels) {
      final isDirty = dirtyChannelIds.contains(serverChannel.id);
      if (serverChannel.deletedAt != null) {
        if (!isDirty) {
          await db.deleteCachedChannel(serverChannel.id!);
        } else {
          await db.updateChannelBaseVersion(
            serverChannel.id!,
            serverChannel.version,
          );
        }
      } else {
        if (isDirty) {
          await db.updateChannelBaseVersion(
            serverChannel.id!,
            serverChannel.version,
          );
        } else {
          await db.upsertChannelFromServer(serverChannel);
        }
      }
    }

    // Reconcile notes
    for (final serverNote in response.notes) {
      final isDirty = dirtyNoteIds.contains(serverNote.id);
      if (serverNote.deletedAt != null) {
        if (!isDirty) {
          await db.deleteCachedNote(serverNote.id!);
        } else {
          await db.updateNoteBaseVersion(serverNote.id!, serverNote.version);
        }
      } else {
        if (isDirty) {
          await db.updateNoteBaseVersion(serverNote.id!, serverNote.version);
        } else {
          await db.upsertNoteFromServer(serverNote);
        }
      }
    }

    await db.setGlobalVersion(response.globalVersion);
  }

  Future<void> _pushPhase() async {
    final db = ref.read(appDatabaseProvider);

    final dirtyChannels = await db.getDirtyChannels();
    final dirtyNotes = await db.getDirtyNotes();

    if (dirtyChannels.isEmpty && dirtyNotes.isEmpty) return;

    final changes = <SyncChange>[
      for (final row in dirtyChannels) _buildChannelChange(row),
      for (final row in dirtyNotes) _buildNoteChange(row),
    ];

    final response = await client.sync.syncPush(changes);

    for (final result in response.results) {
      if (result.entityType == 'channel') {
        await _applyChannelResult(db, result);
      } else if (result.entityType == 'note') {
        await _applyNoteResult(db, result);
      }
    }

    await db.setGlobalVersion(response.globalVersion);
  }

  SyncChange _buildChannelChange(CachedChannel row) {
    final entityMap = jsonDecode(row.json) as Map<String, dynamic>;
    entityMap['id'] = row.id;

    return SyncChange(
      entityType: 'channel',
      entityJson: jsonEncode(entityMap),
      baseVersion: row.version,
      tempId: row.isNew ? row.id : null,
      clientMutationId: row.clientMutationId,
      deleted: row.deletedLocally,
    );
  }

  SyncChange _buildNoteChange(CachedNote row) {
    final entityMap = jsonDecode(row.json) as Map<String, dynamic>;
    entityMap['id'] = row.id;

    return SyncChange(
      entityType: 'note',
      entityJson: jsonEncode(entityMap),
      baseVersion: row.version,
      tempId: row.isNew ? row.id : null,
      clientMutationId: row.clientMutationId,
      deleted: row.deletedLocally,
    );
  }

  Future<void> _applyChannelResult(AppDatabase db, SyncResult result) async {
    if (result.status == 'applied' || result.status == 'already_applied') {
      if (result.tempId != null && result.serverId != null) {
        // Offline create: temp ID → server ID mapping
        final serverVersion = _extractVersion(result.entityJson);
        await db.replaceTemporaryChannelId(
          result.tempId!,
          result.serverId!,
          result.entityJson ?? '{}',
          serverVersion,
        );
      } else {
        final id = result.serverId ?? _extractIdFromJson(result.entityJson);
        if (id != null) {
          final serverVersion = _extractVersion(result.entityJson);
          await db.clearChannelDirty(id, serverVersion);
        }
      }
    } else if (result.status == 'rejected') {
      // Accept server version — overwrite local dirty state
      final id =
          result.serverId ??
          result.tempId ??
          _extractIdFromJson(result.entityJson);

      if (id == null) return;

      if (result.entityJson != null) {
        final serverVersion = _extractVersion(result.entityJson);
        await db.clearChannelDirty(id, serverVersion);
        // Overwrite JSON with server state
        await (db.update(
          db.cachedChannels,
        )..where((t) => t.id.equals(id))).write(
          CachedChannelsCompanion(
            json: Value(result.entityJson!),
            version: Value(serverVersion),
            dirty: const Value(false),
            deletedLocally: const Value(false),
            isNew: const Value(false),
          ),
        );
      } else {
        // Server has no record of this entity — remove locally
        await db.deleteCachedChannel(id);
      }
    }
  }

  Future<void> _applyNoteResult(AppDatabase db, SyncResult result) async {
    if (result.status == 'applied' || result.status == 'already_applied') {
      if (result.tempId != null && result.serverId != null) {
        final serverVersion = _extractVersion(result.entityJson);
        int channelId = 0;
        DateTime createdAt = DateTime.now();
        if (result.entityJson != null) {
          final map = jsonDecode(result.entityJson!) as Map<String, dynamic>;
          channelId = (map['channelId'] as int?) ?? 0;
          final raw = map['createdAt'];
          if (raw is String) createdAt = DateTime.tryParse(raw) ?? createdAt;
        }
        await db.replaceTemporaryNoteId(
          result.tempId!,
          result.serverId!,
          result.entityJson ?? '{}',
          serverVersion,
          channelId,
          createdAt,
        );
      } else {
        final id = result.serverId ?? _extractIdFromJson(result.entityJson);
        if (id != null) {
          final serverVersion = _extractVersion(result.entityJson);
          await db.clearNoteDirty(id, serverVersion);
        }
      }
    } else if (result.status == 'rejected') {
      final id =
          result.serverId ??
          result.tempId ??
          _extractIdFromJson(result.entityJson);

      if (id == null) return;

      if (result.entityJson != null) {
        final serverVersion = _extractVersion(result.entityJson);
        await db.clearNoteDirty(id, serverVersion);
        await (db.update(db.cachedNotes)..where((t) => t.id.equals(id))).write(
          CachedNotesCompanion(
            json: Value(result.entityJson!),
            version: Value(serverVersion),
            dirty: const Value(false),
            deletedLocally: const Value(false),
            isNew: const Value(false),
          ),
        );
      } else {
        await db.deleteCachedNote(id);
      }
    }
  }

  int _extractVersion(String? json) {
    if (json == null) return 0;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return (map['version'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  int? _extractIdFromJson(String? json) {
    if (json == null) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final id = map['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      return null;
    } catch (_) {
      return null;
    }
  }
}
