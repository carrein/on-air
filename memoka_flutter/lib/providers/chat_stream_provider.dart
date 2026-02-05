import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../main.dart';

part 'chat_stream_provider.g.dart';

/// Provides the WebSocket stream for real-time chat events.
@riverpod
Stream<ChatEvent> chatStream(ChatStreamRef ref) {
  return client.chat.chat();
}
