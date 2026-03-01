// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editing_note_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the ID of the note currently being edited.
/// null = create mode, non-null = edit mode

@ProviderFor(EditingNote)
final editingNoteProvider = EditingNoteProvider._();

/// Manages the ID of the note currently being edited.
/// null = create mode, non-null = edit mode
final class EditingNoteProvider extends $NotifierProvider<EditingNote, int?> {
  /// Manages the ID of the note currently being edited.
  /// null = create mode, non-null = edit mode
  EditingNoteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editingNoteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editingNoteHash();

  @$internal
  @override
  EditingNote create() => EditingNote();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int?>(value),
    );
  }
}

String _$editingNoteHash() => r'69f9f2ebde0a96a1325f2a9b01b4dac4c34d3350';

/// Manages the ID of the note currently being edited.
/// null = create mode, non-null = edit mode

abstract class _$EditingNote extends $Notifier<int?> {
  int? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int?, int?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int?, int?>,
              int?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
