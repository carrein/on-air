// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_panel_visible_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the visibility state of the media panel.
/// Persisted to SharedPreferences so it survives hard refresh.
/// Defaults to visible on web (desktop), hidden on native (mobile).

@ProviderFor(MediaPanelVisible)
final mediaPanelVisibleProvider = MediaPanelVisibleProvider._();

/// Manages the visibility state of the media panel.
/// Persisted to SharedPreferences so it survives hard refresh.
/// Defaults to visible on web (desktop), hidden on native (mobile).
final class MediaPanelVisibleProvider
    extends $NotifierProvider<MediaPanelVisible, bool> {
  /// Manages the visibility state of the media panel.
  /// Persisted to SharedPreferences so it survives hard refresh.
  /// Defaults to visible on web (desktop), hidden on native (mobile).
  MediaPanelVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaPanelVisibleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaPanelVisibleHash();

  @$internal
  @override
  MediaPanelVisible create() => MediaPanelVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$mediaPanelVisibleHash() => r'2230ab9eae71355c2a0faba867d7451f693bd5e9';

/// Manages the visibility state of the media panel.
/// Persisted to SharedPreferences so it survives hard refresh.
/// Defaults to visible on web (desktop), hidden on native (mobile).

abstract class _$MediaPanelVisible extends $Notifier<bool> {
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
