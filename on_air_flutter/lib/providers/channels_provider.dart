import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:on_air_client/on_air_client.dart';
import '../main.dart';
import 'chat_stream_provider.dart';

part 'channels_provider.g.dart';

/// Manages the list of channels with real-time updates from WebSocket.
@riverpod
class Channels extends _$Channels {
  @override
  Future<List<Channel>> build() async {
    // Listen to chat stream for real-time updates
    ref.listen(chatStreamProvider, (_, event) {
      event.whenData((chatEvent) {
        if (chatEvent.type == 'channelCreated' ||
            chatEvent.type == 'channelDeleted' ||
            chatEvent.type == 'channelUpdated') {
          // Refetch channels when they change
          ref.invalidateSelf();
        }
      });
    });

    return client.chat.getChannels();
  }

  Future<void> createChannel(String name, {String emoji = '💬'}) async {
    await client.chat.createChannel(name, emoji: emoji);
    // WebSocket broadcast will trigger refetch via listener above
  }

  Future<void> updateChannel(
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) async {
    await client.chat.updateChannel(id, name: name, emoji: emoji, pinned: pinned);
    // WebSocket broadcast will trigger refetch via listener above
  }

  Future<void> deleteChannel(int id) async {
    await client.chat.deleteChannel(id);
    // WebSocket broadcast will trigger refetch via listener above
  }
}
