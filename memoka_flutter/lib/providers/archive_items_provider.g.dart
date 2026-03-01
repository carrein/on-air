// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the mixed archive list (notes + channels) with real-time updates.

@ProviderFor(ArchiveItems)
final archiveItemsProvider = ArchiveItemsProvider._();

/// Manages the mixed archive list (notes + channels) with real-time updates.
final class ArchiveItemsProvider
    extends $AsyncNotifierProvider<ArchiveItems, List<ArchiveItem>> {
  /// Manages the mixed archive list (notes + channels) with real-time updates.
  ArchiveItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveItemsHash();

  @$internal
  @override
  ArchiveItems create() => ArchiveItems();
}

String _$archiveItemsHash() => r'0ed66631a73f6376150f2552dcde384ac89287f2';

/// Manages the mixed archive list (notes + channels) with real-time updates.

abstract class _$ArchiveItems extends $AsyncNotifier<List<ArchiveItem>> {
  FutureOr<List<ArchiveItem>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ArchiveItem>>, List<ArchiveItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ArchiveItem>>, List<ArchiveItem>>,
              AsyncValue<List<ArchiveItem>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
