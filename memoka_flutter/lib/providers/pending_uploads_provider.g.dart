// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_uploads_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pendingUploadsHash() => r'142f5896c82133517402f7ad58e5c794d18017e6';

/// Manages optimistic uploads with progress tracking and retry.
///
/// Copied from [PendingUploads].
@ProviderFor(PendingUploads)
final pendingUploadsProvider =
    NotifierProvider<PendingUploads, List<PendingUpload>>.internal(
      PendingUploads.new,
      name: r'pendingUploadsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$pendingUploadsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PendingUploads = Notifier<List<PendingUpload>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
