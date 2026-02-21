import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../local_db/database.dart';

part 'pending_mutation_count_provider.g.dart';

/// Watches the count of pending offline mutations for the sync indicator.
@riverpod
Stream<int> pendingMutationCount(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchPendingCount();
}
