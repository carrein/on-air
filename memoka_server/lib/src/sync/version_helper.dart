import 'package:serverpod/serverpod.dart';

/// Atomically increments the global version counter and returns the new value.
///
/// MUST be called inside the same database transaction as the entity mutation
/// so the version stamp and the entity change are committed atomically.
///
/// Example usage inside a transaction:
/// ```dart
/// final result = await session.db.transaction((tx) async {
///   final newVersion = await incrementGlobalVersion(session, transaction: tx);
///   channel.version = newVersion;
///   return Channel.db.updateRow(session, channel, transaction: tx);
/// });
/// ```
Future<int> incrementGlobalVersion(
  Session session, {
  Transaction? transaction,
}) async {
  final result = await session.db.unsafeQuery(
    'UPDATE "sync_state" SET "globalVersion" = "globalVersion" + 1 RETURNING "globalVersion"',
    transaction: transaction,
  );
  return result.first.toColumnMap()['globalVersion'] as int;
}

/// Reads the current global version without incrementing it.
Future<int> readGlobalVersion(Session session) async {
  final result = await session.db.unsafeQuery(
    'SELECT "globalVersion" FROM "sync_state" WHERE "id" = 1',
  );
  return result.first.toColumnMap()['globalVersion'] as int;
}
