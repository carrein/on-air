// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_uploads_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages optimistic uploads with progress tracking and retry.

@ProviderFor(PendingUploads)
final pendingUploadsProvider = PendingUploadsProvider._();

/// Manages optimistic uploads with progress tracking and retry.
final class PendingUploadsProvider
    extends $NotifierProvider<PendingUploads, List<PendingUpload>> {
  /// Manages optimistic uploads with progress tracking and retry.
  PendingUploadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingUploadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingUploadsHash();

  @$internal
  @override
  PendingUploads create() => PendingUploads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PendingUpload> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PendingUpload>>(value),
    );
  }
}

String _$pendingUploadsHash() => r'f3111ed0f95b30a488bc650aa7cf2bee5b1bf89d';

/// Manages optimistic uploads with progress tracking and retry.

abstract class _$PendingUploads extends $Notifier<List<PendingUpload>> {
  List<PendingUpload> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<PendingUpload>, List<PendingUpload>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PendingUpload>, List<PendingUpload>>,
              List<PendingUpload>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
