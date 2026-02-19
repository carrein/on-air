import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
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
            chatEvent.type == 'channelUpdated' ||
            chatEvent.type == 'channelArchived' ||
            chatEvent.type == 'channelRestored') {
          // Refetch channels when they change
          ref.invalidateSelf();
        }
      });
    });

    return client.chat.getChannels();
  }

  Future<Channel> createChannel(String name, {String emoji = 'chatCircle'}) async {
    final channel = await client.chat.createChannel(name, emoji: emoji);
    // WebSocket broadcast will trigger refetch via listener above
    return channel;
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
    try {
      await client.chat.deleteChannel(id);
      // WebSocket broadcast will trigger refetch via listener above
    } catch (e) {
      // Provide user-friendly error messages
      if (e.toString().contains('last remaining channel')) {
        throw Exception('Cannot delete the last channel. Create another channel first.');
      }
      rethrow;
    }
  }

  Future<void> reorderChannels(List<int> channelIds) async {
    // Optimistically update local state to prevent flicker
    final current = state.valueOrNull;
    if (current != null) {
      final idToChannel = {for (final c in current) c.id: c};
      final reordered = <Channel>[];
      for (var i = 0; i < channelIds.length; i++) {
        final ch = idToChannel[channelIds[i]];
        if (ch != null) {
          reordered.add(ch.copyWith(sortOrder: i));
        }
      }
      // Add any channels not in the reorder list (other group)
      for (final ch in current) {
        if (!channelIds.contains(ch.id)) {
          reordered.add(ch);
        }
      }
      reordered.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = AsyncData(reordered);
    }

    await client.chat.reorderChannels(channelIds);
  }

  Future<void> archiveChannel(int id) async {
    try {
      await client.chat.archiveChannel(id);
      // WebSocket broadcast will trigger refetch via listener above
    } catch (e) {
      if (e.toString().contains('last remaining channel')) {
        throw Exception('Cannot archive the last channel. Create another channel first.');
      }
      rethrow;
    }
  }
}
