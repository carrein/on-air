import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_page_provider.g.dart';

enum SettingsPage {
  main,
}

/// Provider to track which settings page is currently displayed
@riverpod
class CurrentSettingsPage extends _$CurrentSettingsPage {
  @override
  SettingsPage build() {
    return SettingsPage.main;
  }

  void showMain() {
    state = SettingsPage.main;
  }
}
