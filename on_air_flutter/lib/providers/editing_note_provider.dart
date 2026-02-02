import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'editing_note_provider.g.dart';

/// Manages the ID of the note currently being edited.
/// null = create mode, non-null = edit mode
@riverpod
class EditingNote extends _$EditingNote {
  @override
  int? build() => null;

  void startEditing(int noteId) {
    state = noteId;
  }

  void cancelEditing() {
    state = null;
  }
}
