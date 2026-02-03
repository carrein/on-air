import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

part 'current_channel_provider.g.dart';

/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.
@riverpod
class CurrentChannel extends _$CurrentChannel {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    final savedChannelId = prefs.getInt('lastOpenedChannelId');

    // Fetch available channels to validate saved ID
    final channels = await client.chat.getChannels();

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
