import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_provider.g.dart';

enum ConnectionState { connected, disconnected, connecting }

/// Monitors the connectivity state of the Serverpod client.
/// For MVP, always returns connected. Serverpod handles reconnection internally.
@riverpod
Stream<ConnectionState> connectionStream(ConnectionStreamRef ref) async* {
  // For now, always return connected
  // Serverpod client handles WebSocket reconnection automatically
  yield ConnectionState.connected;

  // Keep the stream alive
  await Future.delayed(const Duration(days: 365));
}
