// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channels_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelsHash() => r'784af7b1ed47cdcd4a8106935accb8d218adc1d8';

/// Manages the list of channels with real-time updates from WebSocket.
///
/// Copied from [Channels].
@ProviderFor(Channels)
final channelsProvider =
    AutoDisposeAsyncNotifierProvider<Channels, List<Channel>>.internal(
      Channels.new,
      name: r'channelsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$channelsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Channels = AutoDisposeAsyncNotifier<List<Channel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
