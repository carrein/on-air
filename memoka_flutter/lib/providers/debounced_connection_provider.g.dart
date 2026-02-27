// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debounced_connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$debouncedConnectionHash() =>
    r'0e1704c34c98584e27d253b5095bfd283c27a8dd';

/// Debounced view of [connectionProvider] that delays the transition to
/// [ConnectionState.disconnected] by [_debounce].
///
/// Prevents a brief "Offline" flash when the app resumes from background
/// and the health ping hasn't completed yet. Transitions to [connected]
/// and [connecting] are immediate (no delay hiding good news).
///
/// Copied from [DebouncedConnection].
@ProviderFor(DebouncedConnection)
final debouncedConnectionProvider =
    NotifierProvider<DebouncedConnection, ConnectionState>.internal(
      DebouncedConnection.new,
      name: r'debouncedConnectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$debouncedConnectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DebouncedConnection = Notifier<ConnectionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
