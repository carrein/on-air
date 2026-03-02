// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(chatStream)
final chatStreamProvider = ChatStreamProvider._();

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

final class ChatStreamProvider
    extends
        $FunctionalProvider<AsyncValue<ChatEvent>, ChatEvent, Stream<ChatEvent>>
    with $FutureModifier<ChatEvent>, $StreamProvider<ChatEvent> {
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
  ChatStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatStreamHash();

  @$internal
  @override
  $StreamProviderElement<ChatEvent> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<ChatEvent> create(Ref ref) {
    return chatStream(ref);
  }
}

String _$chatStreamHash() => r'658caf8279248ad15d390a14a0e6eaaae318daa4';
