import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'drafts_provider.g.dart';

/// Manages per-channel draft content (memory-only, not persisted).
@riverpod
class Drafts extends _$Drafts {
  @override
  Map<int, String> build() => {};

  String getDraft(int channelId) => state[channelId] ?? '';

  void saveDraft(int channelId, String content) {
    if (content.isEmpty) {
      final newState = Map<int, String>.from(state);
      newState.remove(channelId);
      state = newState;
    } else {
      state = {...state, channelId: content};
    }
  }

  void clearDraft(int channelId) {
    final newState = Map<int, String>.from(state);
    newState.remove(channelId);
    state = newState;
  }
}
