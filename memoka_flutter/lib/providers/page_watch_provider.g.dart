// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_watch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the PageWatch state for a specific note.
/// Returns null when the note has no watch.

@ProviderFor(PageWatchNotifier)
final pageWatchProvider = PageWatchNotifierFamily._();

/// Provides the PageWatch state for a specific note.
/// Returns null when the note has no watch.
final class PageWatchNotifierProvider
    extends $AsyncNotifierProvider<PageWatchNotifier, PageWatch?> {
  /// Provides the PageWatch state for a specific note.
  /// Returns null when the note has no watch.
  PageWatchNotifierProvider._({
    required PageWatchNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'pageWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pageWatchNotifierHash();

  @override
  String toString() {
    return r'pageWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PageWatchNotifier create() => PageWatchNotifier();

  @override
  bool operator ==(Object other) {
    return other is PageWatchNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pageWatchNotifierHash() => r'ef5a7e9bdf4737cfccb808563a8b90db2e7ae1ed';

/// Provides the PageWatch state for a specific note.
/// Returns null when the note has no watch.

final class PageWatchNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PageWatchNotifier,
          AsyncValue<PageWatch?>,
          PageWatch?,
          FutureOr<PageWatch?>,
          int
        > {
  PageWatchNotifierFamily._()
    : super(
        retry: null,
        name: r'pageWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the PageWatch state for a specific note.
  /// Returns null when the note has no watch.

  PageWatchNotifierProvider call(int noteId) =>
      PageWatchNotifierProvider._(argument: noteId, from: this);

  @override
  String toString() => r'pageWatchProvider';
}

/// Provides the PageWatch state for a specific note.
/// Returns null when the note has no watch.

abstract class _$PageWatchNotifier extends $AsyncNotifier<PageWatch?> {
  late final _$args = ref.$arg as int;
  int get noteId => _$args;

  FutureOr<PageWatch?> build(int noteId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<PageWatch?>, PageWatch?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PageWatch?>, PageWatch?>,
              AsyncValue<PageWatch?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
