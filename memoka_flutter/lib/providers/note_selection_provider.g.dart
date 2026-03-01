// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages multi-selection state for notes.

@ProviderFor(NoteSelection)
final noteSelectionProvider = NoteSelectionProvider._();

/// Manages multi-selection state for notes.
final class NoteSelectionProvider
    extends $NotifierProvider<NoteSelection, Set<int>> {
  /// Manages multi-selection state for notes.
  NoteSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSelectionHash();

  @$internal
  @override
  NoteSelection create() => NoteSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<int>>(value),
    );
  }
}

String _$noteSelectionHash() => r'e555bdb701fb53124b4c1de50fd45e229c34de56';

/// Manages multi-selection state for notes.

abstract class _$NoteSelection extends $Notifier<Set<int>> {
  Set<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Set<int>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<int>, Set<int>>,
              Set<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
