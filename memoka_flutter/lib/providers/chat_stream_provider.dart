import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../main.dart';

part 'chat_stream_provider.g.dart';

/// Provides the WebSocket stream for real-time chat events.
/// Automatically reconnects with exponential backoff if the connection drops.
@riverpod
Stream<ChatEvent> chatStream(Ref ref) async* {
  var delay = 1;
  const maxDelay = 30;

  while (true) {
    try {
      await for (final event in client.chat.chat()) {
        delay = 1; // Reset backoff on successful event
        yield event;
      }
    } catch (_) {
      // Stream errored — will reconnect below
    }

    // Stream ended (timeout or error) — wait and reconnect
    await Future.delayed(Duration(seconds: delay));
    delay = (delay * 2).clamp(1, maxDelay);
  }
}
