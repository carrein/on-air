// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for managing background selection

@ProviderFor(BackgroundPreference)
final backgroundPreferenceProvider = BackgroundPreferenceProvider._();

/// Provider for managing background selection
final class BackgroundPreferenceProvider
    extends $NotifierProvider<BackgroundPreference, BackgroundType> {
  /// Provider for managing background selection
  BackgroundPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundPreferenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundPreferenceHash();

  @$internal
  @override
  BackgroundPreference create() => BackgroundPreference();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundType>(value),
    );
  }
}

String _$backgroundPreferenceHash() =>
    r'80bf27538b5df57d8b8bcdc12de3b460d33ce2fa';

/// Provider for managing background selection

abstract class _$BackgroundPreference extends $Notifier<BackgroundType> {
  BackgroundType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BackgroundType, BackgroundType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BackgroundType, BackgroundType>,
              BackgroundType,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
