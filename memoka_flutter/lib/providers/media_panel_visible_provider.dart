import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'media_panel_visible_provider.g.dart';

/// Manages the visibility state of the media panel.
/// Persisted to SharedPreferences so it survives hard refresh.
/// Defaults to visible on web (desktop), hidden on native (mobile).
@Riverpod(keepAlive: true)
class MediaPanelVisible extends _$MediaPanelVisible {
  static const _key = 'media_panel_visible';

  @override
  bool build() {
    _load();
    return kIsWeb;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_key);
    if (saved != null) {
      state = saved;
    }
  }

  void toggle() {
    state = !state;
    _persist();
  }

  void show() {
    state = true;
    _persist();
  }

  void hide() {
    state = false;
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, state);
  }
}
