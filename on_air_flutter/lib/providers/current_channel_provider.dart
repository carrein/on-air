import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'current_channel_provider.g.dart';

/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.
@riverpod
class CurrentChannel extends _$CurrentChannel {
  @override
  Future<int> build() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to channel ID 1 (General channel)
    return prefs.getInt('lastOpenedChannelId') ?? 1;
  }

  Future<void> switchChannel(int channelId) async {
    state = AsyncValue.data(channelId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastOpenedChannelId', channelId);
  }
}
