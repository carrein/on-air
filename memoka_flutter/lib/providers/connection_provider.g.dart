// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$connectionHash() => r'dedc20cf33ba3aabac3d0c0f98f7e16a9381b3ff';

/// Tracks server connectivity via the WebSocket lifecycle and OS network events.
///
/// - WebSocket connected (first event received) → [connected]
/// - WebSocket dropped / stream error → [disconnected]
/// - OS reports no network (airplane mode) → [disconnected]
/// - OS reports network restored while disconnected → kicks WebSocket reconnect
///
/// Copied from [Connection].
@ProviderFor(Connection)
final connectionProvider =
    NotifierProvider<Connection, ConnectionState>.internal(
      Connection.new,
      name: r'connectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$connectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Connection = Notifier<ConnectionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
