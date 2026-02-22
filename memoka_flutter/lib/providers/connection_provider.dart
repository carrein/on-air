import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'chat_stream_provider.dart';

part 'connection_provider.g.dart';

enum ConnectionState { connected, disconnected }

/// Tracks server connectivity via the WebSocket lifecycle and OS network events.
///
/// - WebSocket connected (first event received) → [connected]
/// - WebSocket dropped / stream error → [disconnected]
/// - OS reports no network (airplane mode) → [disconnected]
/// - OS reports network restored while disconnected → kicks WebSocket reconnect
@Riverpod(keepAlive: true)
class Connection extends _$Connection {
  @override
  ConnectionState build() {
    final sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        if (state != ConnectionState.disconnected) {
          state = ConnectionState.disconnected;
        }
      } else if (state == ConnectionState.disconnected) {
        // OS says network is back — restart WebSocket immediately
        // instead of waiting for the backoff timer to expire.
        ref.invalidate(chatStreamProvider);
      }
    });

    ref.onDispose(sub.cancel);

    // Start disconnected; WebSocket will confirm once connected.
    return ConnectionState.disconnected;
  }

  void setConnected() {
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
