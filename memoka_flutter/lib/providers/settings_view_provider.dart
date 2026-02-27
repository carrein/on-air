import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_view_provider.g.dart';

/// Provider to track whether settings view is currently displayed
@riverpod
class SettingsVisibility extends _$SettingsVisibility {
  @override
  bool build() {
    return false;
  }

  void show() {
    state = true;
  }

  void hide() {
    state = false;
  }

  void toggle() {
    state = !state;
  }
}
