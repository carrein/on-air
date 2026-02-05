// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drafts_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$draftsHash() => r'6633b9e4753a8033cebc60a7f7503d7a9b719369';

/// Manages per-channel draft content (memory-only, not persisted).
///
/// Copied from [Drafts].
@ProviderFor(Drafts)
final draftsProvider =
    AutoDisposeNotifierProvider<Drafts, Map<int, String>>.internal(
      Drafts.new,
      name: r'draftsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$draftsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Drafts = AutoDisposeNotifier<Map<int, String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
