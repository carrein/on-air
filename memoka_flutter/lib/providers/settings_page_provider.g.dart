// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_page_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentSettingsPageHash() =>
    r'80aa603ce1c2ea11d178550ae178fbb199ce204d';

/// Provider to track which settings page is currently displayed
///
/// Copied from [CurrentSettingsPage].
@ProviderFor(CurrentSettingsPage)
final currentSettingsPageProvider =
    AutoDisposeNotifierProvider<CurrentSettingsPage, SettingsPage>.internal(
      CurrentSettingsPage.new,
      name: r'currentSettingsPageProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentSettingsPageHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentSettingsPage = AutoDisposeNotifier<SettingsPage>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
