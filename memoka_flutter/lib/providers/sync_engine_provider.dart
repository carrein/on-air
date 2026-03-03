import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'channels_provider.dart';
import 'connection_provider.dart';
import 'current_channel_provider.dart';

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
  /// Cooldown to prevent redundant syncs when multiple reconnect triggers
  /// fire in quick succession (e.g., Android lifecycle resume AND
  /// connectivity_plus both fire on wake).
  static const _syncCooldown = Duration(seconds: 2);
  DateTime? _lastSyncAt;

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

    final last = _lastSyncAt;
    if (last != null && DateTime.now().difference(last) < _syncCooldown) {
      return; // recently synced — skip redundant run
    }

    state = true;

    try {
      await _pullPhase();
      await _pushPhase();
    } catch (_) {
      // Network error during sync — will retry on next connect transition.
    } finally {
      state = false;
      _lastSyncAt = DateTime.now();
    }

    // Reload channels from the local cache without going through AsyncLoading.
    // ref.invalidate() would cause channelsAsync.value to return null for
    // one frame, collapsing the navbar Row and producing a ghost-icon flicker.
    await ref.read(channelsProvider.notifier).refreshFromCache();

    // If the app started without a server, currentChannelProvider is stuck in
    // error state. Now that channels are available, rebuild it so it selects
    // the first channel.
    if (ref.read(currentChannelProvider).hasError) {
      ref.invalidate(currentChannelProvider);
    }
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
      if (serverChannel.deletedAt != null || serverChannel.archived) {
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
      if (serverNote.deletedAt != null || serverNote.archived) {
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

    // Track which entities were deleted locally so we can remove from cache
    // instead of just clearing dirty flags.
    final deletedChannelIds = {
      for (final row in dirtyChannels)
        if (row.deletedLocally) row.id,
    };
    final deletedNoteIds = {
      for (final row in dirtyNotes)
        if (row.deletedLocally) row.id,
    };

    final response = await client.sync.syncPush(changes);

    for (final result in response.results) {
      if (result.entityType == 'channel') {
        await _applyChannelResult(db, result, deletedChannelIds);
      } else if (result.entityType == 'note') {
        await _applyNoteResult(db, result, deletedNoteIds);
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

  Future<void> _applyChannelResult(
    AppDatabase db,
    SyncResult result,
    Set<int> deletedIds,
  ) async {
    final parsed = _parseEntityJson(result.entityJson);

    if (result.status == 'applied' || result.status == 'already_applied') {
      if (result.tempId != null && result.serverId != null) {
        await db.replaceTemporaryChannelId(
          result.tempId!,
          result.serverId!,
          result.entityJson ?? '{}',
          _versionFrom(parsed),
        );
      } else {
        final id = result.serverId ?? _idFrom(parsed);
        if (id != null) {
          if (deletedIds.contains(id)) {
            await db.deleteCachedChannel(id);
          } else {
            await db.clearChannelDirty(id, _versionFrom(parsed));
          }
        }
      }
    } else if (result.status == 'rejected') {
      final id = result.serverId ?? result.tempId ?? _idFrom(parsed);
      if (id == null) return;

      if (result.entityJson != null) {
        final serverVersion = _versionFrom(parsed);
        await db.clearChannelDirty(id, serverVersion);
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
        await db.deleteCachedChannel(id);
      }
    }
  }

  Future<void> _applyNoteResult(
    AppDatabase db,
    SyncResult result,
    Set<int> deletedIds,
  ) async {
    final parsed = _parseEntityJson(result.entityJson);

    if (result.status == 'applied' || result.status == 'already_applied') {
      if (result.tempId != null && result.serverId != null) {
        int channelId = 0;
        DateTime createdAt = DateTime.now();
        if (parsed != null) {
          channelId = (parsed['channelId'] as int?) ?? 0;
          final raw = parsed['createdAt'];
          if (raw is String) createdAt = DateTime.tryParse(raw) ?? createdAt;
        }
        await db.replaceTemporaryNoteId(
          result.tempId!,
          result.serverId!,
          result.entityJson ?? '{}',
          _versionFrom(parsed),
          channelId,
          createdAt,
        );
      } else {
        final id = result.serverId ?? _idFrom(parsed);
        if (id != null) {
          if (deletedIds.contains(id)) {
            await db.deleteCachedNote(id);
          } else {
            await db.clearNoteDirty(id, _versionFrom(parsed));
          }
        }
      }
    } else if (result.status == 'rejected') {
      final id = result.serverId ?? result.tempId ?? _idFrom(parsed);
      if (id == null) return;

      if (result.entityJson != null) {
        final serverVersion = _versionFrom(parsed);
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

  /// Parse entity JSON once, returning a map for field extraction.
  Map<String, dynamic>? _parseEntityJson(String? json) {
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  int _versionFrom(Map<String, dynamic>? map) => (map?['version'] as int?) ?? 0;

  int? _idFrom(Map<String, dynamic>? map) {
    if (map == null) return null;
    final id = map['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }
}
