// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debounced_connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Debounced view of [connectionProvider] that delays the transition to
/// [ConnectionState.disconnected] by [_debounce].
///
/// Prevents a brief "Offline" flash when the app resumes from background
/// and the health ping hasn't completed yet. Transitions to [connected]
/// and [connecting] are immediate (no delay hiding good news).

@ProviderFor(DebouncedConnection)
final debouncedConnectionProvider = DebouncedConnectionProvider._();

/// Debounced view of [connectionProvider] that delays the transition to
/// [ConnectionState.disconnected] by [_debounce].
///
/// Prevents a brief "Offline" flash when the app resumes from background
/// and the health ping hasn't completed yet. Transitions to [connected]
/// and [connecting] are immediate (no delay hiding good news).
final class DebouncedConnectionProvider
    extends $NotifierProvider<DebouncedConnection, ConnectionState> {
  /// Debounced view of [connectionProvider] that delays the transition to
  /// [ConnectionState.disconnected] by [_debounce].
  ///
  /// Prevents a brief "Offline" flash when the app resumes from background
  /// and the health ping hasn't completed yet. Transitions to [connected]
  /// and [connecting] are immediate (no delay hiding good news).
  DebouncedConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'debouncedConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$debouncedConnectionHash();

  @$internal
  @override
  DebouncedConnection create() => DebouncedConnection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionState>(value),
    );
  }
}

String _$debouncedConnectionHash() =>
    r'9181c47d7d61bbf5cdecdbfffb6a7f46ac1608dc';

/// Debounced view of [connectionProvider] that delays the transition to
/// [ConnectionState.disconnected] by [_debounce].
///
/// Prevents a brief "Offline" flash when the app resumes from background
/// and the health ping hasn't completed yet. Transitions to [connected]
/// and [connecting] are immediate (no delay hiding good news).

abstract class _$DebouncedConnection extends $Notifier<ConnectionState> {
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
