// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatStreamHash() => r'de7eeb389d8506f5ea57411a5ca56de8ff3dab1c';

/// Provides the WebSocket stream for real-time chat events.
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
