import 'package:serverpod/serverpod.dart';

/// Lightweight endpoint used by the Flutter client to confirm server
/// reachability before opening the WebSocket stream.
class HealthEndpoint extends Endpoint {
  Future<bool> ping(Session session) async => true;
}
