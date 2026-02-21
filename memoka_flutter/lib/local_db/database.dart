import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart' as proto;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database.g.dart';

/// Cached channels table — stores full serialised Channel JSON.
class CachedChannels extends Table {
  IntColumn get id => integer()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached notes table — stores full serialised Note JSON, indexed by channel.
class CachedNotes extends Table {
  IntColumn get id => integer()();
  IntColumn get channelId => integer()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get json => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pending offline mutations — queued for sync when connectivity returns.
class PendingMutations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  IntColumn get channelId => integer().nullable()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [CachedChannels, CachedNotes, PendingMutations])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // -- Channel cache --

  Future<void> cacheChannels(List<proto.Channel> channels) async {
    await transaction(() async {
      await delete(cachedChannels).go();
      for (final ch in channels) {
        await into(cachedChannels).insert(
          CachedChannelsCompanion.insert(
            id: Value(ch.id!),
            json: jsonEncode(ch.toJson()),
          ),
        );
      }
    });
  }

  Future<List<proto.Channel>> getCachedChannels() async {
    final rows = await select(cachedChannels).get();
    return rows
        .map(
          (r) => proto.Channel.fromJson(
            jsonDecode(r.json) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  // -- Note cache --

  Future<void> cacheNotes(int chId, List<proto.Note> notes) async {
    await transaction(() async {
      await (delete(cachedNotes)..where((t) => t.channelId.equals(chId))).go();
      for (final note in notes) {
        await into(cachedNotes).insert(
          CachedNotesCompanion.insert(
            id: Value(note.id!),
            channelId: note.channelId,
            createdAt: note.createdAt,
            json: jsonEncode(note.toJson()),
          ),
        );
      }
    });
  }

  Future<List<proto.Note>> getCachedNotes(int chId, {int limit = 50}) async {
    final query = select(cachedNotes)
      ..where((t) => t.channelId.equals(chId))
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

  // -- Pending mutations --

  Future<int> enqueueMutation(
    String mutationType,
    int? chId,
    String payload,
  ) async {
    return into(pendingMutations).insert(
      PendingMutationsCompanion.insert(
        type: mutationType,
        channelId: Value(chId),
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<List<PendingMutation>> getPendingMutations() async {
    final query = select(pendingMutations)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  Future<void> deleteMutation(int mutationId) async {
    await (delete(
      pendingMutations,
    )..where((t) => t.id.equals(mutationId))).go();
  }

  Stream<int> watchPendingCount() {
    final cnt = pendingMutations.id.count();
    return (selectOnly(
      pendingMutations,
    )..addColumns([cnt])).map((row) => row.read(cnt) ?? 0).watchSingle();
  }
}

/// Provides the singleton [AppDatabase] instance.
/// Returns null on web (no SQLite available — cache lives in Riverpod state only).
@Riverpod(keepAlive: true)
AppDatabase? appDatabase(Ref ref) {
  if (kIsWeb) return null;
  final db = AppDatabase(driftDatabase(name: 'memoka'));
  ref.onDispose(db.close);
  return db;
}
