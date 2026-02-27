import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'chat_stream_provider.dart';

part 'connection_provider.g.dart';

enum ConnectionState { connecting, connected, disconnected }

/// Tracks server connectivity via the WebSocket lifecycle and OS network events.
///
/// - WebSocket connected (first event received) → [connected]
/// - WebSocket dropped / stream error → [disconnected]
/// - OS reports no network (airplane mode) → [disconnected]
/// - OS reports network restored while disconnected → kicks WebSocket reconnect
@Riverpod(keepAlive: true)
class Connection extends _$Connection {
  /// Guards against rapid-fire invalidations when connectivity_plus emits
  /// multiple non-none events in quick succession (common on web).
  /// Reset to false when going offline or when setConnected() is called.
  bool _reconnectScheduled = false;

  @override
  ConnectionState build() {
    _reconnectScheduled = false;

    final sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        // Network definitely gone — reset the guard so the next online event
        // triggers a fresh reconnect attempt.
        _reconnectScheduled = false;
        if (state != ConnectionState.disconnected) {
          state = ConnectionState.disconnected;
        }
      } else if (state == ConnectionState.disconnected &&
          !_reconnectScheduled) {
        // OS says network is back — restart WebSocket immediately instead of
        // waiting for the backoff timer to expire. Guard prevents duplicate
        // invalidations if connectivity_plus emits several non-none events.
        _reconnectScheduled = true;
        ref.invalidate(chatStreamProvider);
      }
    });

    ref.onDispose(sub.cancel);

    // Start in connecting state; WebSocket lifecycle will transition to
    // connected or disconnected after the first health ping completes.
    return ConnectionState.connecting;
  }

  void setConnecting() {
    if (state != ConnectionState.connecting) {
      state = ConnectionState.connecting;
    }
  }

  void setConnected() {
    _reconnectScheduled = false;
    if (state != ConnectionState.connected) {
      state = ConnectionState.connected;
    }
  }

  void setDisconnected() {
    if (state != ConnectionState.disconnected) {
      state = ConnectionState.disconnected;
    }
  }
}
