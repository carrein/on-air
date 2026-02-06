// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$noteSelectionHash() => r'478625133972e19583df8d0a212d87e1953df36c';

/// Manages multi-selection state for notes.
///
/// Copied from [NoteSelection].
@ProviderFor(NoteSelection)
final noteSelectionProvider =
    AutoDisposeNotifierProvider<NoteSelection, Set<int>>.internal(
      NoteSelection.new,
      name: r'noteSelectionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$noteSelectionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NoteSelection = AutoDisposeNotifier<Set<int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
