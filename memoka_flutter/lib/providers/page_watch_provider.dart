import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../main.dart';

part 'page_watch_provider.g.dart';

/// Provides the PageWatch state for a specific note.
/// Returns null when the note has no watch.
@riverpod
class PageWatchNotifier extends _$PageWatchNotifier {
  @override
  Future<PageWatch?> build(int noteId) async {
    return client.pageWatch.getWatch(noteId);
  }

  /// Creates or re-enables a watch. Returns the watch on success.
  Future<PageWatch?> enableWatch() async {
    state = const AsyncLoading();
    try {
      final watch = await client.pageWatch.createWatch(arg);
      state = AsyncData(watch);
      return watch;
    } catch (e) {
      // Restore previous state on error
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  /// Deletes the watch.
  Future<void> disableWatch() async {
    await client.pageWatch.deleteWatch(arg);
    state = const AsyncData(null);
  }

  /// Toggles the watch on/off. Returns true if now watching.
  Future<bool> toggleWatch() async {
    final current = state.value;
    if (current != null && current.enabled) {
      await disableWatch();
      return false;
    } else {
      await enableWatch();
      return true;
    }
  }

  /// Acknowledges a content change (clears the pink dot).
  Future<void> acknowledgeChange() async {
    await client.pageWatch.acknowledgeChange(arg);
    final current = state.value;
    if (current != null) {
      state = AsyncData(
        PageWatch(
          noteId: current.noteId,
          channelId: current.channelId,
          url: current.url,
          contentHash: current.contentHash,
          lastCheckedAt: current.lastCheckedAt,
          enabled: current.enabled,
          consecutiveFailures: current.consecutiveFailures,
          lastError: current.lastError,
          hasUnacknowledgedChange: false,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Force refresh from server (called when WebSocket event arrives).
  Future<void> refresh() async {
    final watch = await client.pageWatch.getWatch(arg);
    state = AsyncData(watch);
  }

  /// The noteId argument for this provider instance.
  int get arg => noteId;
}
