import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../local_db/database.dart';

part 'dirty_sync_count_provider.g.dart';

/// Watches the count of dirty (unsynced) entities for the sync indicator.
/// Replaces the old pendingMutationCount which watched the PendingMutations table.
@riverpod
Stream<int> dirtySyncCount(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchDirtyCount();
}
