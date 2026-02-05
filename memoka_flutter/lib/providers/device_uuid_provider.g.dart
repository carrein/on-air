// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_uuid_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceUuidHash() => r'bc065d437b3915471cb434b889657a1538899722';

/// Provides a persistent device UUID stored in shared preferences.
///
/// Copied from [deviceUuid].
@ProviderFor(deviceUuid)
final deviceUuidProvider = AutoDisposeFutureProvider<String>.internal(
  deviceUuid,
  name: r'deviceUuidProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceUuidHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceUuidRef = AutoDisposeFutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
