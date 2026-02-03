// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_channel_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentChannelHash() => r'065b1d624ce1d243f3cc4671c05228edbc3ae2a4';

/// Manages the currently active channel ID.
/// Persists to shared preferences for restoration on app restart.
///
/// Copied from [CurrentChannel].
@ProviderFor(CurrentChannel)
final currentChannelProvider =
    AutoDisposeAsyncNotifierProvider<CurrentChannel, int>.internal(
      CurrentChannel.new,
      name: r'currentChannelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$currentChannelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CurrentChannel = AutoDisposeAsyncNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
