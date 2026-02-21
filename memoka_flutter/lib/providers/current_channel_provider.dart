import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'channels_provider.dart';

part 'current_channel_provider.g.dart';

/// Direction of the most recent channel switch: -1 = previous, 1 = next.
/// Used by ChatView to animate the slide direction.
final channelSwitchDirectionProvider = StateProvider<int>((ref) => 1);

/// Stores the channel ID to return to when backing out of Archive.
final previousChannelProvider = StateProvider<int?>((ref) => null);

/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.
@riverpod
class CurrentChannel extends _$CurrentChannel {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChannelId = prefs.getInt('lastOpenedChannelId');

    // Use channelsProvider which has local-first caching built in.
    final channels = await ref.watch(channelsProvider.future);

    if (channels.isEmpty) {
      throw Exception('No channels available. Please create a channel first.');
    }

    // If we have a saved channel ID, check if it still exists
    if (savedChannelId != null) {
      final channelExists = channels.any((c) => c.id == savedChannelId);
      if (channelExists) {
        return savedChannelId;
      }
    }

    // Fallback to the first available channel (newest by updatedAt)
    // Channels are sorted by pinned status and updatedAt in getChannels()
    final firstChannel = channels.first;
    await prefs.setInt('lastOpenedChannelId', firstChannel.id!);
    return firstChannel.id!;
  }

  Future<void> switchChannel(int channelId) async {
    state = AsyncValue.data(channelId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastOpenedChannelId', channelId);
  }
}
