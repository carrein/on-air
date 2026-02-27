// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingsVisibilityHash() =>
    r'b0eec6884ae088e10facc966b6a3b76cd819ddb8';

/// Provider to track whether settings view is currently displayed
///
/// Copied from [SettingsVisibility].
@ProviderFor(SettingsVisibility)
final settingsVisibilityProvider =
    AutoDisposeNotifierProvider<SettingsVisibility, bool>.internal(
      SettingsVisibility.new,
      name: r'settingsVisibilityProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$settingsVisibilityHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SettingsVisibility = AutoDisposeNotifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
