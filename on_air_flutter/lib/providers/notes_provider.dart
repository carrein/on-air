import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:on_air_client/on_air_client.dart';
import '../main.dart';
import 'chat_stream_provider.dart';

part 'notes_provider.g.dart';

/// Manages notes for a specific channel with pagination and real-time updates.
@riverpod
class Notes extends _$Notes {
  List<Note> _notes = [];
  int? _oldestNoteId;
  bool _hasMore = true;

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
    if (!_hasMore || _oldestNoteId == null) return;

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
  }

  Future<void> createNote(String content) async {
    await client.chat.createNote(channelId, content);
    // WebSocket broadcast will trigger UI update via listener
  }

  Future<void> updateNote(int id, String content) async {
    await client.chat.updateNote(id, content);
    // WebSocket broadcast will trigger UI update via listener
  }

  Future<void> deleteNote(int id) async {
    await client.chat.deleteNote(id);
    // WebSocket broadcast will trigger UI update via listener
  }
}
