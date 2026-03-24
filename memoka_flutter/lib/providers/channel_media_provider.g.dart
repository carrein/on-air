// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides all media and links for a specific channel.
/// Synchronously derives from notesProvider so the MediaPanel never sees
/// a loading->data flicker when notes change.

@ProviderFor(channelMediaData)
final channelMediaDataProvider = ChannelMediaDataFamily._();

/// Provides all media and links for a specific channel.
/// Synchronously derives from notesProvider so the MediaPanel never sees
/// a loading->data flicker when notes change.

final class ChannelMediaDataProvider
    extends $FunctionalProvider<ChannelMedia, ChannelMedia, ChannelMedia>
    with $Provider<ChannelMedia> {
  /// Provides all media and links for a specific channel.
  /// Synchronously derives from notesProvider so the MediaPanel never sees
  /// a loading->data flicker when notes change.
  ChannelMediaDataProvider._({
    required ChannelMediaDataFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'channelMediaDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$channelMediaDataHash();

  @override
  String toString() {
    return r'channelMediaDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChannelMedia> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChannelMedia create(Ref ref) {
    final argument = this.argument as int;
    return channelMediaData(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChannelMedia value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChannelMedia>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelMediaDataProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$channelMediaDataHash() => r'b7f1208217f06f104fe40cf663494ca2513d1949';

/// Provides all media and links for a specific channel.
/// Synchronously derives from notesProvider so the MediaPanel never sees
/// a loading->data flicker when notes change.

final class ChannelMediaDataFamily extends $Family
    with $FunctionalFamilyOverride<ChannelMedia, int> {
  ChannelMediaDataFamily._()
    : super(
        retry: null,
        name: r'channelMediaDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides all media and links for a specific channel.
  /// Synchronously derives from notesProvider so the MediaPanel never sees
  /// a loading->data flicker when notes change.

  ChannelMediaDataProvider call(int channelId) =>
      ChannelMediaDataProvider._(argument: channelId, from: this);

  @override
  String toString() => r'channelMediaDataProvider';
}
