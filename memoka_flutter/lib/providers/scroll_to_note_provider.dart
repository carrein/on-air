import 'package:flutter_riverpod/legacy.dart';

/// Provider to request the chat view to scroll to a specific note.
/// Set the note ID to trigger scrolling, then it resets to null.
final scrollToNoteProvider = StateProvider<int?>((_) => null);
