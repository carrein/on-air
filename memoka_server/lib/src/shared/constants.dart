import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ServerConstants {
  static const String mediaBaseDir = 'data/media';

  /// Error substring thrown when attempting to delete/archive the last channel.
  /// Matched by the client for typed error detection.
  static const String lastChannelError = 'last remaining channel';

  /// Channel name used for broadcasting real-time chat events via MessageCentral.
  static const String chatEventsChannel = 'chat_events';

  /// Broadcasts a chat event via MessageCentral.
  /// Silently ignores errors (e.g., Redis not available in test mode).
  static Future<void> broadcastEvent(Session session, ChatEvent event) async {
    try {
      await session.messages.postMessage(
        chatEventsChannel,
        event,
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }
  }
}
