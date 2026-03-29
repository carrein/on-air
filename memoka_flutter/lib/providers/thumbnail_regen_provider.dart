import 'dart:async';

import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../main.dart';

part 'thumbnail_regen_provider.g.dart';

/// State of the thumbnail regeneration job as seen by the client.
///
/// [progress] is null when no job has been started or observed this session.
/// When non-null, [ThumbnailRegenProgress.isRunning] distinguishes in-progress
/// from completed.
@Riverpod(keepAlive: true)
class ThumbnailRegen extends _$ThumbnailRegen {
  Timer? _pollTimer;

  @override
  ThumbnailRegenProgress? build() {
    ref.onDispose(() => _pollTimer?.cancel());
    // Check if a job is already running on the server (e.g. started from
    // another session or a previous app open).
    _syncFromServer();
    return null;
  }

  /// Starts the regen job on the server, records the total, and begins
  /// polling for progress. Throws on failure so the UI can show an error.
  Future<void> start() async {
    final total = await client.settings.startThumbnailRegen();
    if (total == 0) {
      state = ThumbnailRegenProgress(
        total: 0,
        processed: 0,
        failed: 0,
        isRunning: false,
      );
      return;
    }
    state = ThumbnailRegenProgress(
      total: total,
      processed: 0,
      failed: 0,
      isRunning: true,
    );
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _poll(),
    );
  }

  Future<void> _poll() async {
    try {
      final progress = await client.settings.getRegenProgress();
      state = progress;
      if (!progress.isRunning) {
        _pollTimer?.cancel();
      }
    } catch (_) {
      // Network hiccup — keep polling, don't reset state.
    }
  }

  /// On provider creation, check if the server already has an active job
  /// (handles app restarts mid-job or navigating back to settings).
  Future<void> _syncFromServer() async {
    try {
      final progress = await client.settings.getRegenProgress();
      if (progress.isRunning) {
        state = progress;
        _startPolling();
      }
    } catch (_) {}
  }
}
