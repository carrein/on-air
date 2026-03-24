// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channels_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the list of channels with local-first caching and real-time updates.

@ProviderFor(Channels)
final channelsProvider = ChannelsProvider._();

/// Manages the list of channels with local-first caching and real-time updates.
final class ChannelsProvider
    extends $AsyncNotifierProvider<Channels, List<Channel>> {
  /// Manages the list of channels with local-first caching and real-time updates.
  ChannelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelsHash();

  @$internal
  @override
  Channels create() => Channels();
}

String _$channelsHash() => r'71e5542148a22234d89bddafed6110de9cedbefb';

/// Manages the list of channels with local-first caching and real-time updates.

abstract class _$Channels extends $AsyncNotifier<List<Channel>> {
  FutureOr<List<Channel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Channel>>, List<Channel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Channel>>, List<Channel>>,
              AsyncValue<List<Channel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
