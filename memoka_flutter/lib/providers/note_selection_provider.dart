import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'note_selection_provider.g.dart';

/// Manages multi-selection state for notes.
@riverpod
class NoteSelection extends _$NoteSelection {
  @override
  Set<int> build() {
    return <int>{};
  }

  /// Toggle selection of a note.
  void toggle(int noteId) {
    final current = state;
    if (current.contains(noteId)) {
      state = <int>{...current}..remove(noteId);
    } else {
      state = <int>{...current, noteId};
    }
  }

  /// Select a note.
  void select(int noteId) {
    state = <int>{...state, noteId};
  }

  /// Deselect a note.
  void deselect(int noteId) {
    state = <int>{...state}..remove(noteId);
  }

  /// Clear all selections.
  void clear() {
    state = <int>{};
  }

  /// Check if a note is selected.
  bool isSelected(int noteId) {
    return state.contains(noteId);
  }

  /// Check if in selection mode (any notes selected).
  bool get isSelectionMode => state.isNotEmpty;

  /// Get count of selected notes.
  int get count => state.length;
}
