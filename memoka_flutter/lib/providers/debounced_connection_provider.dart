import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'connection_provider.dart';

part 'debounced_connection_provider.g.dart';

/// Debounced view of [connectionProvider] that delays the transition to
/// [ConnectionState.disconnected] by [_debounce].
///
/// Prevents a brief "Offline" flash when the app resumes from background
/// and the health ping hasn't completed yet. Transitions to [connected]
/// and [connecting] are immediate (no delay hiding good news).
@Riverpod(keepAlive: true)
class DebouncedConnection extends _$DebouncedConnection {
  static const _debounce = Duration(seconds: 3);
  Timer? _timer;

  @override
  ConnectionState build() {
    final raw = ref.watch(connectionProvider);

    ref.onDispose(() => _timer?.cancel());

    if (raw == ConnectionState.disconnected) {
      // On first build, state is uninitialized — fall through to disconnected
      // immediately. On subsequent rebuilds, start the debounce timer and
      // preserve the previous state until it fires.
      final ConnectionState previous;
      try {
        previous = state;
      } catch (_) {
        // First build — no previous state to preserve.
        return ConnectionState.disconnected;
      }

      _timer?.cancel();
      _timer = Timer(_debounce, () {
        if (state != ConnectionState.disconnected) {
          state = ConnectionState.disconnected;
        }
      });
      return previous;
    }

    // Connected or connecting — cancel timer and propagate immediately.
    _timer?.cancel();
    return raw;
  }
}
