// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncEngineHash() => r'0bb17366a898c596b86159b24e00f70c7ee8f05e';

/// Pull-then-push sync engine driven by connectivity transitions.
///
/// On each reconnect:
///  1. Pull phase — fetch server changes since lastSyncGlobalVersion and
///     reconcile with the local cache.
///  2. Push phase — send all dirty local entities to the server.
///  3. Invalidate UI providers so fresh state is rendered.
///
/// Copied from [SyncEngine].
@ProviderFor(SyncEngine)
final syncEngineProvider = NotifierProvider<SyncEngine, bool>.internal(
  SyncEngine.new,
  name: r'syncEngineProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$syncEngineHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SyncEngine = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
