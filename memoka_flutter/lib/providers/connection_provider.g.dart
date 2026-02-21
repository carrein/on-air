// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionStreamHash() => r'533fea0b9b58aab5baadffb5c1baac6547e52b75';

/// Monitors connectivity using connectivity_plus + periodic healthcheck probe.
/// Polls the server every 5 seconds to detect both server going down and
/// coming back up, since killing/restarting the server process doesn't
/// trigger OS-level network change events.
///
/// Copied from [connectionStream].
@ProviderFor(connectionStream)
final connectionStreamProvider = StreamProvider<ConnectionState>.internal(
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
typedef ConnectionStreamRef = StreamProviderRef<ConnectionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
