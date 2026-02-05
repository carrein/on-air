// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_sidebar_visible_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$mediaSidebarVisibleHash() =>
    r'cdfbb1207a4633ead1e8c9fab6308c7930edf3f7';

/// Manages the visibility state of the media sidebar on mobile/tablet devices.
/// On desktop, the sidebar is always visible and this state is not used.
///
/// Copied from [MediaSidebarVisible].
@ProviderFor(MediaSidebarVisible)
final mediaSidebarVisibleProvider =
    AutoDisposeNotifierProvider<MediaSidebarVisible, bool>.internal(
      MediaSidebarVisible.new,
      name: r'mediaSidebarVisibleProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mediaSidebarVisibleHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MediaSidebarVisible = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
