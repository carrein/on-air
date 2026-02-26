// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dirty_sync_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dirtySyncCountHash() => r'3e9e340432211bd90e9de1e3208768d3b6a4c79b';

/// Watches the count of dirty (unsynced) entities for the sync indicator.
/// Replaces the old pendingMutationCount which watched the PendingMutations table.
///
/// Copied from [dirtySyncCount].
@ProviderFor(dirtySyncCount)
final dirtySyncCountProvider = AutoDisposeStreamProvider<int>.internal(
  dirtySyncCount,
  name: r'dirtySyncCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dirtySyncCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DirtySyncCountRef = AutoDisposeStreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
