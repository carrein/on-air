// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_panel_visible_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaPanelVisibleHash() =>
    r'cdfbb1207a4633ead1e8c9fab6308c7930edf3f7';

/// Manages the visibility state of the media panel on mobile/tablet devices.
/// On desktop, the panel is always visible and this state is not used.
///
/// Copied from [MediaPanelVisible].
@ProviderFor(MediaPanelVisible)
final mediaPanelVisibleProvider =
    AutoDisposeNotifierProvider<MediaPanelVisible, bool>.internal(
      MediaPanelVisible.new,
      name: r'mediaPanelVisibleProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mediaPanelVisibleHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MediaPanelVisible = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
