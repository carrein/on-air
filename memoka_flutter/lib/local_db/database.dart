import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart' as proto;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

/// Cached channels table — stores full serialised Channel JSON with dirty tracking.
class CachedChannels extends Table {
  IntColumn get id => integer()();
  TextColumn get json => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get deletedLocally =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isNew => boolean().withDefault(const Constant(false))();
  TextColumn get clientMutationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached notes table — stores full serialised Note JSON with dirty tracking.
class CachedNotes extends Table {
  IntColumn get id => integer()();
  IntColumn get channelId => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get json => text()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  BoolColumn get deletedLocally =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isNew => boolean().withDefault(const Constant(false))();
  TextColumn get clientMutationId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached archive items — stores full serialised ArchiveItem JSON.
class CachedArchiveItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get json => text()();
  DateTimeColumn get archivedAt => dateTime()();
}

/// Sync metadata singleton — stores the last known globalVersion.
class SyncMeta extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get globalVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [CachedChannels, CachedNotes, CachedArchiveItems, SyncMeta],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      // Seed SyncMeta singleton row
      await customInsert(
        'INSERT OR IGNORE INTO "sync_meta" ("id", "global_version") VALUES (1, 0)',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(cachedArchiveItems);
      }
      if (from < 3) {
        // Drop PendingMutations (schema v2 table — no longer used)
        await customStatement('DROP TABLE IF EXISTS "pending_mutations"');
        // Add dirty tracking columns to CachedChannels
        await customStatement(
          'ALTER TABLE "cached_channels" ADD COLUMN "version" INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE "cached_channels" ADD COLUMN "dirty" INTEGER NOT NULL DEFAULT 0 CHECK ("dirty" IN (0, 1))',
        );
        await customStatement(
          'ALTER TABLE "cached_channels" ADD COLUMN "deleted_locally" INTEGER NOT NULL DEFAULT 0 CHECK ("deleted_locally" IN (0, 1))',
        );
        await customStatement(
          'ALTER TABLE "cached_channels" ADD COLUMN "is_new" INTEGER NOT NULL DEFAULT 0 CHECK ("is_new" IN (0, 1))',
        );
        await customStatement(
          'ALTER TABLE "cached_channels" ADD COLUMN "client_mutation_id" TEXT',
        );
        // Add dirty tracking columns to CachedNotes
        await customStatement(
          'ALTER TABLE "cached_notes" ADD COLUMN "version" INTEGER NOT NULL DEFAULT 0',
        );
        await customStatement(
          'ALTER TABLE "cached_notes" ADD COLUMN "dirty" INTEGER NOT NULL DEFAULT 0 CHECK ("dirty" IN (0, 1))',
        );
        await customStatement(
          'ALTER TABLE "cached_notes" ADD COLUMN "deleted_locally" INTEGER NOT NULL DEFAULT 0 CHECK ("deleted_locally" IN (0, 1))',
        );
        await customStatement(
          'ALTER TABLE "cached_notes" ADD COLUMN "is_new" INTEGER NOT NULL DEFAULT 0 CHECK ("is_new" IN (0, 1))',
        );
        await customStatement(
          'ALTER TABLE "cached_notes" ADD COLUMN "client_mutation_id" TEXT',
        );
        // Create SyncMeta table
        await m.createTable(syncMeta);
        await customInsert(
          'INSERT OR IGNORE INTO "sync_meta" ("id", "global_version") VALUES (1, 0)',
        );
      }
    },
  );

  // -- SyncMeta --

  Future<int> getGlobalVersion() async {
    final row = await (select(
      syncMeta,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    return row?.globalVersion ?? 0;
  }

  Future<void> setGlobalVersion(int version) async {
    await into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(
        id: const Value(1),
        globalVersion: Value(version),
      ),
    );
  }

  // -- Channel cache --

  /// Replaces the channel cache with a clean server snapshot (dirty = false).
  /// Preserves dirty rows (offline mutations not yet pushed) — only
  /// replaces non-dirty entries. Mirrors the approach in [cacheNotes].
  Future<void> cacheChannels(List<proto.Channel> channels) async {
    await transaction(() async {
      // Preserve dirty rows — only replace clean entries
      final dirtyRows = await (select(
        cachedChannels,
      )..where((t) => t.dirty.equals(true))).get();
      final dirtyIds = dirtyRows.map((r) => r.id).toSet();
      await (delete(cachedChannels)..where((t) => t.dirty.equals(false))).go();
      for (final ch in channels) {
        if (!dirtyIds.contains(ch.id)) {
          await into(cachedChannels).insert(
            CachedChannelsCompanion.insert(
              id: Value(ch.id!),
              json: jsonEncode(ch.toJson()),
              version: Value(ch.version),
              dirty: const Value(false),
            ),
          );
        }
      }
    });
  }

  Future<List<proto.Channel>> getCachedChannels() async {
    final rows = await select(cachedChannels).get();
    final channels = rows
        .where((r) => !r.deletedLocally)
        .map(
          (r) => proto.Channel.fromJson(
            jsonDecode(r.json) as Map<String, dynamic>,
          ),
        )
        .where((ch) => !ch.archived)
        .toList();
    channels.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return channels;
  }

  /// Inserts or updates a channel from server with dirty=false.
  Future<void> upsertChannelFromServer(proto.Channel ch) async {
    await into(cachedChannels).insertOnConflictUpdate(
      CachedChannelsCompanion.insert(
        id: Value(ch.id!),
        json: jsonEncode(ch.toJson()),
        version: Value(ch.version),
        dirty: const Value(false),
        deletedLocally: const Value(false),
        isNew: const Value(false),
      ),
    );
  }

  /// Inserts or updates a channel with dirty=true (local mutation).
  Future<void> upsertChannelDirty(proto.Channel ch) async {
    final existing = await (select(
      cachedChannels,
    )..where((t) => t.id.equals(ch.id!))).getSingleOrNull();
    await into(cachedChannels).insertOnConflictUpdate(
      CachedChannelsCompanion.insert(
        id: Value(ch.id!),
        json: jsonEncode(ch.toJson()),
        version: Value(existing?.version ?? 0),
        dirty: const Value(true),
        deletedLocally: const Value(false),
        isNew: Value(existing?.isNew ?? false),
        clientMutationId: Value(existing?.clientMutationId),
      ),
    );
  }

  /// Creates an offline-only provisional channel (dirty=true, isNew=true).
  Future<void> insertOfflineChannel(
    int tempId,
    String jsonData,
    String? clientMutationId,
  ) async {
    await into(cachedChannels).insertOnConflictUpdate(
      CachedChannelsCompanion.insert(
        id: Value(tempId),
        json: jsonData,
        version: const Value(0),
        dirty: const Value(true),
        deletedLocally: const Value(false),
        isNew: const Value(true),
        clientMutationId: Value(clientMutationId),
      ),
    );
  }

  /// Marks a channel as deleted locally (dirty=true, deletedLocally=true).
  Future<void> markChannelDeletedLocally(int id) async {
    final existing = await (select(
      cachedChannels,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    await (update(cachedChannels)..where((t) => t.id.equals(id))).write(
      CachedChannelsCompanion(
        dirty: const Value(true),
        deletedLocally: const Value(true),
      ),
    );
  }

  /// Returns all dirty channels (pending push).
  Future<List<CachedChannel>> getDirtyChannels() async {
    return (select(cachedChannels)..where((t) => t.dirty.equals(true))).get();
  }

  /// Clears dirty flags and updates version after successful push.
  Future<void> clearChannelDirty(int id, int newVersion) async {
    await (update(cachedChannels)..where((t) => t.id.equals(id))).write(
      CachedChannelsCompanion(
        dirty: const Value(false),
        deletedLocally: const Value(false),
        isNew: const Value(false),
        version: Value(newVersion),
      ),
    );
  }

  /// Replaces a temporary ID with the server-assigned ID after create is applied.
  Future<void> replaceTemporaryChannelId(
    int tempId,
    int serverId,
    String serverJson,
    int serverVersion,
  ) async {
    await transaction(() async {
      final existing = await (select(
        cachedChannels,
      )..where((t) => t.id.equals(tempId))).getSingleOrNull();
      if (existing == null) return;
      await (delete(cachedChannels)..where((t) => t.id.equals(tempId))).go();
      await into(cachedChannels).insertOnConflictUpdate(
        CachedChannelsCompanion.insert(
          id: Value(serverId),
          json: serverJson,
          version: Value(serverVersion),
          dirty: const Value(false),
          deletedLocally: const Value(false),
          isNew: const Value(false),
        ),
      );
    });
  }

  /// Removes a channel from the local cache entirely.
  Future<void> deleteCachedChannel(int id) async {
    await (delete(cachedChannels)..where((t) => t.id.equals(id))).go();
  }

  /// Updates the stored baseVersion for a dirty channel (used after pull
  /// discovers a newer server version while the channel is locally dirty).
  Future<void> updateChannelBaseVersion(int id, int newVersion) async {
    await (update(cachedChannels)..where((t) => t.id.equals(id))).write(
      CachedChannelsCompanion(version: Value(newVersion)),
    );
  }

  // -- Note cache --

  Future<void> cacheNotes(int chId, List<proto.Note> notes) async {
    await transaction(() async {
      // Only replace non-dirty entries for this channel (preserve dirty ones)
      final dirty =
          await (select(cachedNotes)..where(
                (t) => t.channelId.equals(chId) & t.dirty.equals(true),
              ))
              .get();
      await (delete(cachedNotes)..where(
            (t) => t.channelId.equals(chId) & t.dirty.equals(false),
          ))
          .go();
      for (final note in notes) {
        final isDirtyLocal = dirty.any((d) => d.id == note.id);
        if (!isDirtyLocal) {
          await into(cachedNotes).insert(
            CachedNotesCompanion.insert(
              id: Value(note.id!),
              channelId: note.channelId,
              createdAt: note.createdAt,
              json: jsonEncode(note.toJson()),
              version: Value(note.version),
              dirty: const Value(false),
            ),
          );
        }
      }
    });
  }

  Future<List<proto.Note>> getCachedNotes(int chId, {int limit = 50}) async {
    final query = select(cachedNotes)
      ..where(
        (t) => t.channelId.equals(chId) & t.deletedLocally.equals(false),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .map(
          (r) =>
              proto.Note.fromJson(jsonDecode(r.json) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> deleteCachedNote(int noteId) async {
    await (delete(cachedNotes)..where((t) => t.id.equals(noteId))).go();
  }

  /// Inserts or updates a note from server with dirty=false.
  Future<void> upsertNoteFromServer(proto.Note note) async {
    await into(cachedNotes).insertOnConflictUpdate(
      CachedNotesCompanion.insert(
        id: Value(note.id!),
        channelId: note.channelId,
        createdAt: note.createdAt,
        json: jsonEncode(note.toJson()),
        version: Value(note.version),
        dirty: const Value(false),
        deletedLocally: const Value(false),
        isNew: const Value(false),
      ),
    );
  }

  /// Inserts or updates a note with dirty=true (local mutation).
  Future<void> upsertNoteDirty(proto.Note note) async {
    final existing = await (select(
      cachedNotes,
    )..where((t) => t.id.equals(note.id!))).getSingleOrNull();
    await into(cachedNotes).insertOnConflictUpdate(
      CachedNotesCompanion.insert(
        id: Value(note.id!),
        channelId: note.channelId,
        createdAt: note.createdAt,
        json: jsonEncode(note.toJson()),
        version: Value(existing?.version ?? 0),
        dirty: const Value(true),
        deletedLocally: const Value(false),
        isNew: Value(existing?.isNew ?? false),
        clientMutationId: Value(existing?.clientMutationId),
      ),
    );
  }

  /// Creates an offline-only provisional note (dirty=true, isNew=true).
  Future<void> insertOfflineNote(
    int tempId,
    int channelId,
    DateTime createdAt,
    String jsonData,
    String? clientMutationId,
  ) async {
    await into(cachedNotes).insertOnConflictUpdate(
      CachedNotesCompanion.insert(
        id: Value(tempId),
        channelId: channelId,
        createdAt: createdAt,
        json: jsonData,
        version: const Value(0),
        dirty: const Value(true),
        deletedLocally: const Value(false),
        isNew: const Value(true),
        clientMutationId: Value(clientMutationId),
      ),
    );
  }

  /// Marks a note as deleted locally (dirty=true, deletedLocally=true).
  Future<void> markNoteDeletedLocally(int id) async {
    final existing = await (select(
      cachedNotes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) return;
    await (update(cachedNotes)..where((t) => t.id.equals(id))).write(
      CachedNotesCompanion(
        dirty: const Value(true),
        deletedLocally: const Value(true),
      ),
    );
  }

  /// Returns all dirty notes (pending push).
  Future<List<CachedNote>> getDirtyNotes() async {
    return (select(cachedNotes)..where((t) => t.dirty.equals(true))).get();
  }

  /// Clears dirty flags and updates version after successful push.
  Future<void> clearNoteDirty(int id, int newVersion) async {
    await (update(cachedNotes)..where((t) => t.id.equals(id))).write(
      CachedNotesCompanion(
        dirty: const Value(false),
        deletedLocally: const Value(false),
        isNew: const Value(false),
        version: Value(newVersion),
      ),
    );
  }

  /// Replaces a temporary ID with the server-assigned ID after create is applied.
  Future<void> replaceTemporaryNoteId(
    int tempId,
    int serverId,
    String serverJson,
    int serverVersion,
    int channelId,
    DateTime createdAt,
  ) async {
    await transaction(() async {
      await (delete(cachedNotes)..where((t) => t.id.equals(tempId))).go();
      await into(cachedNotes).insertOnConflictUpdate(
        CachedNotesCompanion.insert(
          id: Value(serverId),
          channelId: channelId,
          createdAt: createdAt,
          json: serverJson,
          version: Value(serverVersion),
          dirty: const Value(false),
          deletedLocally: const Value(false),
          isNew: const Value(false),
        ),
      );
    });
  }

  /// Updates the stored baseVersion for a dirty note (used after pull
  /// discovers a newer server version while the note is locally dirty).
  Future<void> updateNoteBaseVersion(int id, int newVersion) async {
    await (update(cachedNotes)..where((t) => t.id.equals(id))).write(
      CachedNotesCompanion(version: Value(newVersion)),
    );
  }

  /// Reactive stream of total dirty entity count (channels + notes).
  Stream<int> watchDirtyCount() {
    return customSelect(
      'SELECT '
      '(SELECT COUNT(*) FROM cached_channels WHERE dirty = 1) + '
      '(SELECT COUNT(*) FROM cached_notes WHERE dirty = 1) AS total',
      readsFrom: {cachedChannels, cachedNotes},
    ).watchSingle().map((row) => row.read<int>('total'));
  }

  // -- Archive cache --

  Future<void> cacheArchiveItems(List<proto.ArchiveItem> items) async {
    await transaction(() async {
      await delete(cachedArchiveItems).go();
      for (final item in items) {
        await into(cachedArchiveItems).insert(
          CachedArchiveItemsCompanion.insert(
            json: jsonEncode(item.toJson()),
            archivedAt: item.archivedAt,
          ),
        );
      }
    });
  }

  Future<List<proto.ArchiveItem>> getCachedArchiveItems() async {
    final query = select(cachedArchiveItems)
      ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)]);
    final rows = await query.get();
    return rows
        .map(
          (r) => proto.ArchiveItem.fromJson(
            jsonDecode(r.json) as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}

/// Provides the singleton [AppDatabase] instance.
/// On native: SQLite file on disk. On web: WASM SQLite backed by IndexedDB.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(
    driftDatabase(
      name: 'memoka',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );
  ref.onDispose(db.close);
  return db;
}
