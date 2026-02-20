import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_panel_visible_provider.g.dart';

/// Manages the visibility state of the media panel on mobile/tablet devices.
/// On desktop, the panel is always visible and this state is not used.
@riverpod
class MediaPanelVisible extends _$MediaPanelVisible {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }
}
