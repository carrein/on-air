import 'package:flutter/foundation.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../main.dart';

part 'archive_retention_provider.g.dart';

/// Manages the archive retention setting (days). 0 = never purge.
@riverpod
class ArchiveRetention extends _$ArchiveRetention {
  @override
  Future<int> build() async {
    try {
      final settings = await client.settings.getSettings();
      return settings.archiveRetentionDays;
    } catch (e) {
      debugPrint('ArchiveRetention.build failed: $e');
      return 0;
    }
  }

  Future<void> updateRetention(int days) async {
    state = AsyncData(days);
    try {
      await client.settings.updateSettings(
        AppSettings(archiveRetentionDays: days),
      );
    } catch (e) {
      debugPrint('ArchiveRetention.updateRetention failed: $e');
      // Revert on failure
      ref.invalidateSelf();
    }
  }
}
