// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages notes for a specific channel with local-first caching,
/// pagination, and real-time updates.

@ProviderFor(Notes)
final notesProvider = NotesFamily._();

/// Manages notes for a specific channel with local-first caching,
/// pagination, and real-time updates.
final class NotesProvider extends $AsyncNotifierProvider<Notes, List<Note>> {
  /// Manages notes for a specific channel with local-first caching,
  /// pagination, and real-time updates.
  NotesProvider._({
    required NotesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'notesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notesHash();

  @override
  String toString() {
    return r'notesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Notes create() => Notes();

  @override
  bool operator ==(Object other) {
    return other is NotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notesHash() => r'7fe7d3d96cda5bb79b87a8ab8fad2d4d66d9f300';

/// Manages notes for a specific channel with local-first caching,
/// pagination, and real-time updates.

final class NotesFamily extends $Family
    with
        $ClassFamilyOverride<
          Notes,
          AsyncValue<List<Note>>,
          List<Note>,
          FutureOr<List<Note>>,
          int
        > {
  NotesFamily._()
    : super(
        retry: null,
        name: r'notesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Manages notes for a specific channel with local-first caching,
  /// pagination, and real-time updates.

  NotesProvider call(int channelId) =>
      NotesProvider._(argument: channelId, from: this);

  @override
  String toString() => r'notesProvider';
}

/// Manages notes for a specific channel with local-first caching,
/// pagination, and real-time updates.

abstract class _$Notes extends $AsyncNotifier<List<Note>> {
  late final _$args = ref.$arg as int;
  int get channelId => _$args;

  FutureOr<List<Note>> build(int channelId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Note>>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Note>>, List<Note>>,
              AsyncValue<List<Note>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
