import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_panel_visible_provider.g.dart';

/// Manages the visibility state of the media panel.
/// Defaults to visible on web (desktop), hidden on native (mobile).
@riverpod
class MediaPanelVisible extends _$MediaPanelVisible {
  @override
  bool build() => kIsWeb;

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
