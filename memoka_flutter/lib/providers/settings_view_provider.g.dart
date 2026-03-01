// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider to track whether settings view is currently displayed

@ProviderFor(SettingsVisibility)
final settingsVisibilityProvider = SettingsVisibilityProvider._();

/// Provider to track whether settings view is currently displayed
final class SettingsVisibilityProvider
    extends $NotifierProvider<SettingsVisibility, bool> {
  /// Provider to track whether settings view is currently displayed
  SettingsVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsVisibilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsVisibilityHash();

  @$internal
  @override
  SettingsVisibility create() => SettingsVisibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$settingsVisibilityHash() =>
    r'8631c5192677aa1f5088d9c358294257cd129e71';

/// Provider to track whether settings view is currently displayed

abstract class _$SettingsVisibility extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
