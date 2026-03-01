import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../main.dart';
import '../utils/health_ping.dart';
import 'connection_provider.dart';

part 'chat_stream_provider.g.dart';

/// Provides the WebSocket stream for real-time chat events.
///
/// On each reconnect attempt:
///   1. Pings the health endpoint to confirm server reachability.
///   2. If reachable, marks [connectionProvider] as connected and opens
///      the WebSocket stream.
///   3. If unreachable or the stream drops, marks disconnected and retries
///      with exponential backoff (max 10s).
///
/// A [cancelled] flag (set via [Ref.onDispose]) ensures the old generator
/// terminates cleanly when the provider is invalidated, preventing stale
/// setDisconnected/setConnected calls from racing with the new instance.
@Riverpod(keepAlive: true)
Stream<ChatEvent> chatStream(Ref ref) async* {
  var cancelled = false;
  ref.onDispose(() => cancelled = true);

  var delay = 1;
  const maxDelay = 10;
  var isFirstAttempt = true;

  while (!cancelled) {
    // Only show "connecting" on initial app startup (not yet disconnected).
    // Skip if already disconnected (e.g. tab refocus while server is down)
    // to avoid hiding the offline banner during a doomed health ping.
    if (isFirstAttempt) {
      if (ref.read(connectionProvider) != ConnectionState.disconnected) {
        ref.read(connectionProvider.notifier).setConnecting();
      }
      isFirstAttempt = false;
    }

    try {
      if (kIsWeb) {
        await webHealthPing('${getWebServerUrl()}/healthcheck');
      } else {
        await client.health.ping().timeout(const Duration(seconds: 4));
      }
      if (cancelled) break;
      ref.read(connectionProvider.notifier).setConnected();

      // Yield one event-loop turn so FlutterConnectivityMonitor's listener
      // (subscribed at Client creation) can flip hasConnection=true before we
      // attempt to open the WebSocket.
      await Future.delayed(Duration.zero);
      if (cancelled) break;

      await for (final event in client.chat.chat()) {
        if (cancelled) break;
        delay = 1;
        yield event;
      }
    } catch (_) {
      // Ping failed or WebSocket dropped — fall through to setDisconnected.
    }

    if (cancelled) break;
    ref.read(connectionProvider.notifier).setDisconnected();
    await Future.delayed(Duration(seconds: delay));
    delay = (delay * 2).clamp(1, maxDelay);
  }
}
