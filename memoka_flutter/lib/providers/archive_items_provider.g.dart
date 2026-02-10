// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_items_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$archiveItemsHash() => r'79c483c4104621ccfeb44c1cc35ce1ea710ed623';

/// Manages the mixed archive list (notes + channels) with real-time updates.
///
/// Copied from [ArchiveItems].
@ProviderFor(ArchiveItems)
final archiveItemsProvider =
    AutoDisposeAsyncNotifierProvider<ArchiveItems, List<ArchiveItem>>.internal(
      ArchiveItems.new,
      name: r'archiveItemsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$archiveItemsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ArchiveItems = AutoDisposeAsyncNotifier<List<ArchiveItem>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
