// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatStreamHash() => r'7b86f862790d883690072f6f4ec0e1008fd6d375';

/// Provides the WebSocket stream for real-time chat events.
///
/// On each reconnect attempt:
///   1. Pings the health endpoint to confirm server reachability.
///   2. If reachable, marks [connectionProvider] as connected and opens
///      the WebSocket stream.
///   3. If unreachable or the stream drops, marks disconnected and retries
///      with exponential backoff (max 10s).
///
/// A [cancelled] flag (set via [Ref.onDispose]) ensures the old generator
/// terminates cleanly when the provider is invalidated, preventing stale
/// setDisconnected/setConnected calls from racing with the new instance.
///
/// Copied from [chatStream].
@ProviderFor(chatStream)
final chatStreamProvider = StreamProvider<ChatEvent>.internal(
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
typedef ChatStreamRef = StreamProviderRef<ChatEvent>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
