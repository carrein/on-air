// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesHash() => r'15981e9c689dbc0f183e4a757c8e047956601838';

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

abstract class _$Notes extends BuildlessAutoDisposeAsyncNotifier<List<Note>> {
  late final int channelId;

  FutureOr<List<Note>> build(int channelId);
}

/// Manages notes for a specific channel with pagination and real-time updates.
///
/// Copied from [Notes].
@ProviderFor(Notes)
const notesProvider = NotesFamily();

/// Manages notes for a specific channel with pagination and real-time updates.
///
/// Copied from [Notes].
class NotesFamily extends Family<AsyncValue<List<Note>>> {
  /// Manages notes for a specific channel with pagination and real-time updates.
  ///
  /// Copied from [Notes].
  const NotesFamily();

  /// Manages notes for a specific channel with pagination and real-time updates.
  ///
  /// Copied from [Notes].
  NotesProvider call(int channelId) {
    return NotesProvider(channelId);
  }

  @override
  NotesProvider getProviderOverride(covariant NotesProvider provider) {
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
  String? get name => r'notesProvider';
}

/// Manages notes for a specific channel with pagination and real-time updates.
///
/// Copied from [Notes].
class NotesProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Notes, List<Note>> {
  /// Manages notes for a specific channel with pagination and real-time updates.
  ///
  /// Copied from [Notes].
  NotesProvider(int channelId)
    : this._internal(
        () => Notes()..channelId = channelId,
        from: notesProvider,
        name: r'notesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$notesHash,
        dependencies: NotesFamily._dependencies,
        allTransitiveDependencies: NotesFamily._allTransitiveDependencies,
        channelId: channelId,
      );

  NotesProvider._internal(
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
  FutureOr<List<Note>> runNotifierBuild(covariant Notes notifier) {
    return notifier.build(channelId);
  }

  @override
  Override overrideWith(Notes Function() create) {
    return ProviderOverride(
      origin: this,
      override: NotesProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<Notes, List<Note>> createElement() {
    return _NotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NotesProvider && other.channelId == channelId;
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
mixin NotesRef on AutoDisposeAsyncNotifierProviderRef<List<Note>> {
  /// The parameter `channelId` of this provider.
  int get channelId;
}

class _NotesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<Notes, List<Note>>
    with NotesRef {
  _NotesProviderElement(super.provider);

  @override
  int get channelId => (origin as NotesProvider).channelId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
