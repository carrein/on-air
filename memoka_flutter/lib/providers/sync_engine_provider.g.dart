// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pull-then-push sync engine driven by connectivity transitions.
///
/// On each reconnect:
///  1. Pull phase — fetch server changes since lastSyncGlobalVersion and
///     reconcile with the local cache.
///  2. Push phase — send all dirty local entities to the server.
///  3. Invalidate UI providers so fresh state is rendered.

@ProviderFor(SyncEngine)
final syncEngineProvider = SyncEngineProvider._();

/// Pull-then-push sync engine driven by connectivity transitions.
///
/// On each reconnect:
///  1. Pull phase — fetch server changes since lastSyncGlobalVersion and
///     reconcile with the local cache.
///  2. Push phase — send all dirty local entities to the server.
///  3. Invalidate UI providers so fresh state is rendered.
final class SyncEngineProvider extends $NotifierProvider<SyncEngine, bool> {
  /// Pull-then-push sync engine driven by connectivity transitions.
  ///
  /// On each reconnect:
  ///  1. Pull phase — fetch server changes since lastSyncGlobalVersion and
  ///     reconcile with the local cache.
  ///  2. Push phase — send all dirty local entities to the server.
  ///  3. Invalidate UI providers so fresh state is rendered.
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  SyncEngine create() => SyncEngine();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncEngineHash() => r'ee6458369e4e8cd280f49f2c14246c12ba0b8c31';

/// Pull-then-push sync engine driven by connectivity transitions.
///
/// On each reconnect:
///  1. Pull phase — fetch server changes since lastSyncGlobalVersion and
///     reconcile with the local cache.
///  2. Push phase — send all dirty local entities to the server.
///  3. Invalidate UI providers so fresh state is rendered.

abstract class _$SyncEngine extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
