// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_retention_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the archive retention setting (days). 0 = never purge.

@ProviderFor(ArchiveRetention)
final archiveRetentionProvider = ArchiveRetentionProvider._();

/// Manages the archive retention setting (days). 0 = never purge.
final class ArchiveRetentionProvider
    extends $AsyncNotifierProvider<ArchiveRetention, int> {
  /// Manages the archive retention setting (days). 0 = never purge.
  ArchiveRetentionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveRetentionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveRetentionHash();

  @$internal
  @override
  ArchiveRetention create() => ArchiveRetention();
}

String _$archiveRetentionHash() => r'7ec7802569bd017deed58d46feaeb7a58b7db733';

/// Manages the archive retention setting (days). 0 = never purge.

abstract class _$ArchiveRetention extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
