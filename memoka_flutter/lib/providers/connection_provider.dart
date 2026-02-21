import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../main.dart' show getWebServerUrl;

part 'connection_provider.g.dart';

enum ConnectionState { connected, disconnected, connecting }

/// Monitors connectivity using connectivity_plus + periodic healthcheck probe.
/// Polls the server every 5 seconds to detect both server going down and
/// coming back up, since killing/restarting the server process doesn't
/// trigger OS-level network change events.
@Riverpod(keepAlive: true)
Stream<ConnectionState> connectionStream(Ref ref) {
  late StreamController<ConnectionState> controller;
  Timer? pollTimer;
  ConnectionState lastState = ConnectionState.disconnected;

  void startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final result = await _probe();
      if (result != lastState) {
        lastState = result;
        controller.add(result);
      }
    });
  }

  controller = StreamController<ConnectionState>(
    onListen: () async {
      // Initial check
      lastState = await _probe();
      controller.add(lastState);

      // Always poll — detects server down AND server recovery.
      startPolling();

      // Also react immediately to OS network changes (e.g. airplane mode).
      final sub = Connectivity().onConnectivityChanged.listen((results) async {
        if (results.contains(ConnectivityResult.none)) {
          if (lastState != ConnectionState.disconnected) {
            lastState = ConnectionState.disconnected;
            controller.add(ConnectionState.disconnected);
          }
        } else {
          // Network restored — probe immediately instead of waiting for poll.
          final result = await _probe();
          if (result != lastState) {
            lastState = result;
            controller.add(result);
          }
        }
      });

      ref.onDispose(() {
        pollTimer?.cancel();
        sub.cancel();
        controller.close();
      });
    },
  );

  return controller.stream;
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
