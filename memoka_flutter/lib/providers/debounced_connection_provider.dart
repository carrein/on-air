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

    // Resolve previous state (null on first build).
    ConnectionState? previous;
    try {
      previous = state;
    } catch (_) {
      previous = null;
    }

    // Connected — always propagate immediately (clears latch + timer).
    if (raw == ConnectionState.connected) {
      _timer?.cancel();
      return ConnectionState.connected;
    }

    // Disconnected — debounce the transition.
    if (raw == ConnectionState.disconnected) {
      if (previous == null) return ConnectionState.disconnected; // first build
      if (previous == ConnectionState.disconnected)
        return previous; // already latched
      _timer?.cancel();
      _timer = Timer(_debounce, () {
        if (state != ConnectionState.disconnected) {
          state = ConnectionState.disconnected;
        }
      });
      return previous;
    }

    // Connecting — latch: if already showing disconnected, keep it.
    if (previous == ConnectionState.disconnected) {
      return ConnectionState.disconnected;
    }
    _timer?.cancel();
    return ConnectionState.connecting;
  }
}
