import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to request the chat view to scroll to a specific note.
/// Set the note ID to trigger scrolling, then it resets to null.
final scrollToNoteProvider = StateProvider<int?>((_) => null);
