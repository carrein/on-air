// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionStreamHash() => r'e4e5227859ef4d083a5496001f655608344a9776';

/// Monitors the connectivity state of the Serverpod client.
/// For MVP, always returns connected. Serverpod handles reconnection internally.
///
/// Copied from [connectionStream].
@ProviderFor(connectionStream)
final connectionStreamProvider =
    AutoDisposeStreamProvider<ConnectionState>.internal(
      connectionStream,
      name: r'connectionStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectionStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectionStreamRef = AutoDisposeStreamProviderRef<ConnectionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
