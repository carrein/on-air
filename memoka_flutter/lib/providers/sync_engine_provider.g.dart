// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_engine_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$syncEngineHash() => r'c2842207e3525b41159d0e911d0190f982da2b49';

/// Drains the pending mutation queue when connectivity is restored.
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
