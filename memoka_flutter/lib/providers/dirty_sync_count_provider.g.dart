// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dirty_sync_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches the count of dirty (unsynced) entities for the sync indicator.
/// Replaces the old pendingMutationCount which watched the PendingMutations table.

@ProviderFor(dirtySyncCount)
final dirtySyncCountProvider = DirtySyncCountProvider._();

/// Watches the count of dirty (unsynced) entities for the sync indicator.
/// Replaces the old pendingMutationCount which watched the PendingMutations table.

final class DirtySyncCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Watches the count of dirty (unsynced) entities for the sync indicator.
  /// Replaces the old pendingMutationCount which watched the PendingMutations table.
  DirtySyncCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dirtySyncCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dirtySyncCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return dirtySyncCount(ref);
  }
}

String _$dirtySyncCountHash() => r'3e9e340432211bd90e9de1e3208768d3b6a4c79b';
