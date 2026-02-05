// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_media_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$channelMediaDataHash() => r'7ebf7cf583f1b265fb30888b579b011d579a95a3';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ChannelMediaData
    extends BuildlessAutoDisposeAsyncNotifier<ChannelMedia> {
  late final int channelId;

  FutureOr<ChannelMedia> build(int channelId);
}

/// Provides all media and links for a specific channel.
/// Filters and transforms notes from notesProvider into organized media collections.
///
/// Copied from [ChannelMediaData].
@ProviderFor(ChannelMediaData)
const channelMediaDataProvider = ChannelMediaDataFamily();

/// Provides all media and links for a specific channel.
/// Filters and transforms notes from notesProvider into organized media collections.
///
/// Copied from [ChannelMediaData].
class ChannelMediaDataFamily extends Family<AsyncValue<ChannelMedia>> {
  /// Provides all media and links for a specific channel.
  /// Filters and transforms notes from notesProvider into organized media collections.
  ///
  /// Copied from [ChannelMediaData].
  const ChannelMediaDataFamily();

  /// Provides all media and links for a specific channel.
  /// Filters and transforms notes from notesProvider into organized media collections.
  ///
  /// Copied from [ChannelMediaData].
  ChannelMediaDataProvider call(int channelId) {
    return ChannelMediaDataProvider(channelId);
  }

  @override
  ChannelMediaDataProvider getProviderOverride(
    covariant ChannelMediaDataProvider provider,
  ) {
    return call(provider.channelId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'channelMediaDataProvider';
}

/// Provides all media and links for a specific channel.
/// Filters and transforms notes from notesProvider into organized media collections.
///
/// Copied from [ChannelMediaData].
class ChannelMediaDataProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<ChannelMediaData, ChannelMedia> {
  /// Provides all media and links for a specific channel.
  /// Filters and transforms notes from notesProvider into organized media collections.
  ///
  /// Copied from [ChannelMediaData].
  ChannelMediaDataProvider(int channelId)
    : this._internal(
        () => ChannelMediaData()..channelId = channelId,
        from: channelMediaDataProvider,
        name: r'channelMediaDataProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$channelMediaDataHash,
        dependencies: ChannelMediaDataFamily._dependencies,
        allTransitiveDependencies:
            ChannelMediaDataFamily._allTransitiveDependencies,
        channelId: channelId,
      );

  ChannelMediaDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.channelId,
  }) : super.internal();

  final int channelId;

  @override
  FutureOr<ChannelMedia> runNotifierBuild(covariant ChannelMediaData notifier) {
    return notifier.build(channelId);
  }

  @override
  Override overrideWith(ChannelMediaData Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChannelMediaDataProvider._internal(
        () => create()..channelId = channelId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        channelId: channelId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<ChannelMediaData, ChannelMedia>
  createElement() {
    return _ChannelMediaDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChannelMediaDataProvider && other.channelId == channelId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, channelId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ChannelMediaDataRef on AutoDisposeAsyncNotifierProviderRef<ChannelMedia> {
  /// The parameter `channelId` of this provider.
  int get channelId;
}

class _ChannelMediaDataProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<ChannelMediaData, ChannelMedia>
    with ChannelMediaDataRef {
  _ChannelMediaDataProviderElement(super.provider);

  @override
  int get channelId => (origin as ChannelMediaDataProvider).channelId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
