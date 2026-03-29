// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thumbnail_regen_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State of the thumbnail regeneration job as seen by the client.
///
/// [progress] is null when no job has been started or observed this session.
/// When non-null, [ThumbnailRegenProgress.isRunning] distinguishes in-progress
/// from completed.

@ProviderFor(ThumbnailRegen)
final thumbnailRegenProvider = ThumbnailRegenProvider._();

/// State of the thumbnail regeneration job as seen by the client.
///
/// [progress] is null when no job has been started or observed this session.
/// When non-null, [ThumbnailRegenProgress.isRunning] distinguishes in-progress
/// from completed.
final class ThumbnailRegenProvider
    extends $NotifierProvider<ThumbnailRegen, ThumbnailRegenProgress?> {
  /// State of the thumbnail regeneration job as seen by the client.
  ///
  /// [progress] is null when no job has been started or observed this session.
  /// When non-null, [ThumbnailRegenProgress.isRunning] distinguishes in-progress
  /// from completed.
  ThumbnailRegenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thumbnailRegenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thumbnailRegenHash();

  @$internal
  @override
  ThumbnailRegen create() => ThumbnailRegen();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThumbnailRegenProgress? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThumbnailRegenProgress?>(value),
    );
  }
}

String _$thumbnailRegenHash() => r'bab4af61855d54822240c3a4e4f32837948422c8';

/// State of the thumbnail regeneration job as seen by the client.
///
/// [progress] is null when no job has been started or observed this session.
/// When non-null, [ThumbnailRegenProgress.isRunning] distinguishes in-progress
/// from completed.

abstract class _$ThumbnailRegen extends $Notifier<ThumbnailRegenProgress?> {
  ThumbnailRegenProgress? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<ThumbnailRegenProgress?, ThumbnailRegenProgress?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThumbnailRegenProgress?, ThumbnailRegenProgress?>,
              ThumbnailRegenProgress?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
