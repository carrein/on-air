import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:universal_html/html.dart' as html;

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
    if (kIsWeb) {
      html.window.history.pushState(null, '', '/app/settings');
    }
  }

  void hide() {
    state = false;
    if (kIsWeb) {
      html.window.history.pushState(null, '', '/app/');
    }
  }

  /// Set state without pushing a history entry (used for popstate handling).
  void setWithoutPush(bool value) {
    state = value;
  }

  void toggle() {
    if (state) {
      hide();
    } else {
      show();
    }
  }
}
