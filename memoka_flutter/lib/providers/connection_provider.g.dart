// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tracks server connectivity via the WebSocket lifecycle and OS network events.
///
/// - WebSocket connected (first event received) → [connected]
/// - WebSocket dropped / stream error → [disconnected]
/// - OS reports no network (airplane mode) → [disconnected]
/// - OS reports network restored while disconnected → kicks WebSocket reconnect

@ProviderFor(Connection)
final connectionProvider = ConnectionProvider._();

/// Tracks server connectivity via the WebSocket lifecycle and OS network events.
///
/// - WebSocket connected (first event received) → [connected]
/// - WebSocket dropped / stream error → [disconnected]
/// - OS reports no network (airplane mode) → [disconnected]
/// - OS reports network restored while disconnected → kicks WebSocket reconnect
final class ConnectionProvider
    extends $NotifierProvider<Connection, ConnectionState> {
  /// Tracks server connectivity via the WebSocket lifecycle and OS network events.
  ///
  /// - WebSocket connected (first event received) → [connected]
  /// - WebSocket dropped / stream error → [disconnected]
  /// - OS reports no network (airplane mode) → [disconnected]
  /// - OS reports network restored while disconnected → kicks WebSocket reconnect
  ConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionHash();

  @$internal
  @override
  Connection create() => Connection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionState>(value),
    );
  }
}

String _$connectionHash() => r'dedc20cf33ba3aabac3d0c0f98f7e16a9381b3ff';

/// Tracks server connectivity via the WebSocket lifecycle and OS network events.
///
/// - WebSocket connected (first event received) → [connected]
/// - WebSocket dropped / stream error → [disconnected]
/// - OS reports no network (airplane mode) → [disconnected]
/// - OS reports network restored while disconnected → kicks WebSocket reconnect

abstract class _$Connection extends $Notifier<ConnectionState> {
  ConnectionState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConnectionState, ConnectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectionState, ConnectionState>,
              ConnectionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
