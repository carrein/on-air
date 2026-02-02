// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editing_note_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$editingNoteHash() => r'69f9f2ebde0a96a1325f2a9b01b4dac4c34d3350';

/// Manages the ID of the note currently being edited.
/// null = create mode, non-null = edit mode
///
/// Copied from [EditingNote].
@ProviderFor(EditingNote)
final editingNoteProvider =
    AutoDisposeNotifierProvider<EditingNote, int?>.internal(
      EditingNote.new,
      name: r'editingNoteProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$editingNoteHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EditingNote = AutoDisposeNotifier<int?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
