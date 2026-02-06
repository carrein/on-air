import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../main.dart';
import 'chat_stream_provider.dart';

part 'notes_provider.g.dart';

/// Manages notes for a specific channel with pagination and real-time updates.
@riverpod
class Notes extends _$Notes {
  List<Note> _notes = [];
  int? _oldestNoteId;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<Note>> build(int channelId) async {
    // Listen to chat stream for real-time note updates
    ref.listen(chatStreamProvider, (_, event) {
      event.whenData((chatEvent) {
        _handleChatEvent(chatEvent, channelId);
      });
    });

    return _loadInitialNotes(channelId);
  }

  Future<List<Note>> _loadInitialNotes(int channelId) async {
    final notes = await client.chat.getNotes(channelId, limit: 50);
    _notes = notes;

    if (notes.isNotEmpty) {
      _oldestNoteId = notes.last.id;
    }

    _hasMore = notes.length == 50;
    return notes;
  }

  void _handleChatEvent(ChatEvent event, int channelId) {
    final currentState = state.value;
    if (currentState == null) return;

    switch (event.type) {
      case 'noteCreated':
        if (event.note?.channelId == channelId) {
          // Skip if already added via optimistic update
          if (currentState.any((n) => n.id == event.note!.id)) break;
          _notes = [event.note!, ...currentState];
          state = AsyncValue.data(_notes);
        }
        break;

      case 'noteUpdated':
      case 'noteLinkPreviewReady':  // Handle preview ready same as update
        if (event.note?.channelId == channelId) {
          _notes = currentState
              .map((n) => n.id == event.note!.id ? event.note! : n)
              .toList();
          state = AsyncValue.data(_notes);
        }
        break;

      case 'noteDeleted':
        if (event.channelId == channelId) {
          _notes = currentState.where((n) => n.id != event.noteId).toList();
          state = AsyncValue.data(_notes);
        }
        break;
    }
  }

  Future<void> loadMore() async {
    // Prevent concurrent loadMore calls
    if (!_hasMore || _oldestNoteId == null || _isLoadingMore) return;

    _isLoadingMore = true;
    try {
      final moreNotes = await client.chat.getNotes(
        channelId,
        beforeId: _oldestNoteId,
        limit: 50,
      );

      if (moreNotes.isNotEmpty) {
        _notes = [..._notes, ...moreNotes];
        _oldestNoteId = moreNotes.last.id;
        _hasMore = moreNotes.length == 50;
        state = AsyncValue.data(_notes);
      } else {
        _hasMore = false;
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> createNote(String content) async {
    final note = await client.chat.createNote(channelId, content);
    // Optimistic update — don't wait for WebSocket
    final current = state.value ?? [];
    if (!current.any((n) => n.id == note.id)) {
      _notes = [note, ...current];
      state = AsyncValue.data(_notes);
    }
  }

  Future<void> updateNote(int id, String content) async {
    final updated = await client.chat.updateNote(id, content);
    // Optimistic update — don't wait for WebSocket
    final current = state.value ?? [];
    _notes = current.map((n) => n.id == id ? updated : n).toList();
    state = AsyncValue.data(_notes);
  }

  Future<void> deleteNote(int id) async {
    await client.chat.deleteNote(id);
    // Optimistic update — don't wait for WebSocket
    final current = state.value ?? [];
    _notes = current.where((n) => n.id != id).toList();
    state = AsyncValue.data(_notes);
  }
}
