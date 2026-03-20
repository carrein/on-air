// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_page_watches_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides all page watches for a channel (1 RPC per channel instead of N).

@ProviderFor(channelPageWatches)
final channelPageWatchesProvider = ChannelPageWatchesFamily._();

/// Provides all page watches for a channel (1 RPC per channel instead of N).

final class ChannelPageWatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PageWatch>>,
          List<PageWatch>,
          FutureOr<List<PageWatch>>
        >
    with $FutureModifier<List<PageWatch>>, $FutureProvider<List<PageWatch>> {
  /// Provides all page watches for a channel (1 RPC per channel instead of N).
  ChannelPageWatchesProvider._({
    required ChannelPageWatchesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'channelPageWatchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelPageWatchesHash();

  @override
  String toString() {
    return r'channelPageWatchesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PageWatch>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PageWatch>> create(Ref ref) {
    final argument = this.argument as int;
    return channelPageWatches(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelPageWatchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelPageWatchesHash() =>
    r'52c99b57c14fe3bd0fcf4af20a7cc0b281a8fe88';

/// Provides all page watches for a channel (1 RPC per channel instead of N).

final class ChannelPageWatchesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PageWatch>>, int> {
  ChannelPageWatchesFamily._()
    : super(
        retry: null,
        name: r'channelPageWatchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides all page watches for a channel (1 RPC per channel instead of N).

  ChannelPageWatchesProvider call(int channelId) =>
      ChannelPageWatchesProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelPageWatchesProvider';
}
