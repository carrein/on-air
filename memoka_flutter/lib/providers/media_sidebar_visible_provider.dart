import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_sidebar_visible_provider.g.dart';

/// Manages the visibility state of the media sidebar on mobile/tablet devices.
/// On desktop, the sidebar is always visible and this state is not used.
@riverpod
class MediaSidebarVisible extends _$MediaSidebarVisible {
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
