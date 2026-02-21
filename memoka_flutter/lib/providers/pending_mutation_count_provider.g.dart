// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_mutation_count_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingMutationCountHash() =>
    r'7b24921c7b82ebceb189f146bd2cd562a118242e';

/// Watches the count of pending offline mutations for the sync indicator.
///
/// Copied from [pendingMutationCount].
@ProviderFor(pendingMutationCount)
final pendingMutationCountProvider = AutoDisposeStreamProvider<int>.internal(
  pendingMutationCount,
  name: r'pendingMutationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pendingMutationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PendingMutationCountRef = AutoDisposeStreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
