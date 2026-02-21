// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatStreamHash() => r'7c3a205d33a87d4d902fbc2cefa6f74fce6ab466';

/// Provides the WebSocket stream for real-time chat events.
/// Automatically reconnects with exponential backoff if the connection drops.
///
/// Copied from [chatStream].
@ProviderFor(chatStream)
final chatStreamProvider = AutoDisposeStreamProvider<ChatEvent>.internal(
  chatStream,
  name: r'chatStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatStreamRef = AutoDisposeStreamProviderRef<ChatEvent>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
