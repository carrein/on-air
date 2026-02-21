import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../main.dart' show getWebServerUrl;

part 'connection_provider.g.dart';

enum ConnectionState { connected, disconnected, connecting }

/// Monitors connectivity using connectivity_plus + server healthcheck probe.
@Riverpod(keepAlive: true)
Stream<ConnectionState> connectionStream(Ref ref) async* {
  // Initial check
  yield await _probe();

  // React to network changes
  await for (final results in Connectivity().onConnectivityChanged) {
    if (results.contains(ConnectivityResult.none)) {
      yield ConnectionState.disconnected;
    } else {
      yield ConnectionState.connecting;
      yield await _probe();
    }
  }
}

/// Probe the server healthcheck endpoint to confirm reachability.
Future<ConnectionState> _probe() async {
  try {
    final url = Uri.parse('${getWebServerUrl()}/healthcheck');
    final response = await http.get(url).timeout(const Duration(seconds: 4));
    return response.statusCode == 200
        ? ConnectionState.connected
        : ConnectionState.disconnected;
  } catch (_) {
    return ConnectionState.disconnected;
  }
}
