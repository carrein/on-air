import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../constants/chat_event_types.dart';
import '../local_db/database.dart';
import '../main.dart';
import 'chat_stream_provider.dart';
import 'provider_utils.dart';
import 'sync_engine_provider.dart';

part 'notes_provider.g.dart';

/// Manages notes for a specific channel with local-first caching,
/// pagination, and real-time updates.
@riverpod
class Notes extends _$Notes {
  List<Note> _notes = [];
  int? _oldestNoteId;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  /// When set, the provider is in "around note" mode (from search jump).
  /// Sync refresh will reload around this anchor instead of latest notes.
  int? _aroundNoteAnchor;

  /// Negative IDs for provisional offline-created notes.
  /// Use timestamp-based starting point so IDs are unique across app restarts
  /// (avoids primary key conflicts in the CachedNotes table).
  static int _nextProvisionalId = -DateTime.now().millisecondsSinceEpoch;

  /// Debounce timer for cache-write coalescing after rapid WebSocket events.
  Timer? _cacheWriteTimer;

  /// Schedule a debounced cache write so rapid-fire events (e.g. bulk archive)
  /// coalesce into a single DB write.
  void _scheduleCacheWrite() {
    _cacheWriteTimer?.cancel();
    _cacheWriteTimer = Timer(const Duration(milliseconds: 300), () {
      final db = ref.read(appDatabaseProvider);
      db.cacheNotes(channelId, _notes);
    });
  }

  @override
  Future<List<Note>> build(int channelId) async {
    final db = ref.read(appDatabaseProvider);

    ref.onDispose(() {
      _cacheWriteTimer?.cancel();
    });

    // Listen to chat stream for real-time note updates
    ref.listen(chatStreamProvider, (_, event) {
      event.whenData((chatEvent) {
        _handleChatEvent(chatEvent, channelId);
      });
    });

    // Reload from cache after sync completes so notes missed while the
    // WebSocket was dead are picked up.
    ref.listen(syncEngineProvider, (prev, next) {
      if (prev == true && next == false) {
        _refreshFromCache();
      }
    });

    // 1. Load from cache and emit immediately — even when empty, so the UI
    // resolves to "It's quiet in here" rather than spinning until the server
    // responds.
    final cached = await db.getCachedNotes(channelId);

    _notes = cached;
    if (cached.isNotEmpty) {
      _oldestNoteId = cached.last.id;
    }
    state = AsyncData(cached);

    // 2. Always try to fetch from server; fall back to cache if unreachable.
    try {
      if (_aroundNoteAnchor != null) {
        await loadAroundNote(_aroundNoteAnchor!);
        return _notes;
      }
      final serverNotes = await _loadInitialNotes(channelId);

      await db.cacheNotes(channelId, serverNotes);
      return serverNotes;
    } catch (e) {
      return _notes;
    }
  }

  Future<List<Note>> _loadInitialNotes(int channelId) async {
    _aroundNoteAnchor = null;
    final serverNotes = await client.chat.getNotes(channelId, limit: 50);

    // Preserve provisional notes (negative IDs) that are dirty in the cache.
    // They'll be replaced in-place by noteCreated events when sync completes.
    final pendingProvisionals = _notes
        .where((n) => (n.id ?? 0) < 0)
        .where(
          (p) =>
              !serverNotes.any((s) => s.clientMutationId == p.clientMutationId),
        )
        .toList();

    _notes = [...pendingProvisionals, ...serverNotes];
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _hasMore = serverNotes.length == 50;
    if (serverNotes.isNotEmpty) {
      _oldestNoteId = serverNotes.last.id;
    }

    return _notes;
  }

  /// Insert a note from the upload response so it appears immediately
  /// without waiting for the WebSocket event.
  void insertUploadedNote(Note note) {
    if (_notes.any((n) => n.id == note.id)) return;
    _notes = [note, ..._notes];
    state = AsyncValue.data(_notes);
    final db = ref.read(appDatabaseProvider);
    db.cacheNotes(note.channelId, _notes);
  }

  void _handleChatEvent(ChatEvent event, int channelId) {
    final currentState = state.value;
    if (currentState == null) return;

    switch (event.type) {
      case ChatEventTypes.noteCreated:
        if (event.note?.channelId == channelId) {
          final incoming = event.note!;
          // Replace provisional note that matches by clientMutationId (offline path)
          if (incoming.clientMutationId != null) {
            final idx = _notes.indexWhere(
              (n) => n.clientMutationId == incoming.clientMutationId,
            );
            if (idx != -1) {
              _notes = [
                ..._notes.sublist(0, idx),
                incoming,
                ..._notes.sublist(idx + 1),
              ];
              state = AsyncValue.data(_notes);
              _scheduleCacheWrite();
              break;
            }
          }
          // Fallback: dedup by server ID (online-created notes)
          if (_notes.any((n) => n.id == incoming.id)) break;
          _notes = [incoming, ..._notes];
          state = AsyncValue.data(_notes);
          _scheduleCacheWrite();
        }
        break;

      case ChatEventTypes.noteArchived:
        if (event.channelId == channelId) {
          _notes = currentState.where((n) => n.id != event.noteId).toList();
          state = AsyncValue.data(_notes);
          _scheduleCacheWrite();
        }
        if (channelId == -1) {
          ref.invalidateSelf();
        }
        break;

      case ChatEventTypes.noteRestored:
        if (channelId == -1) {
          _notes = currentState.where((n) => n.id != event.noteId).toList();
          state = AsyncValue.data(_notes);
        }
        if (event.channelId == channelId && event.note != null) {
          if (currentState.any((n) => n.id == event.note!.id)) break;
          _notes = [event.note!, ...currentState];
          _sortNotes();
          state = AsyncValue.data(_notes);
          _scheduleCacheWrite();
        }
        break;

      case ChatEventTypes.noteUpdated:
      case ChatEventTypes.noteLinkPreviewReady:
        if (event.note?.channelId == channelId) {
          _notes = currentState
              .map((n) => n.id == event.note!.id ? event.note! : n)
              .toList();
          state = AsyncValue.data(_notes);
          _scheduleCacheWrite();
        }
        break;

      case ChatEventTypes.noteDeleted:
        if (event.channelId == channelId) {
          _notes = currentState.where((n) => n.id != event.noteId).toList();
          state = AsyncValue.data(_notes);
          _scheduleCacheWrite();
        }
        break;
    }
  }

  /// Reload notes from the local Drift cache without entering AsyncLoading.
  ///
  /// Called after the sync engine completes a pull+push cycle so that notes
  /// missed while the WebSocket was dead are picked up from the cache.
  /// Uses the larger of 50 (default page) or the current list size so that
  /// scroll position is preserved when the user had loaded additional pages.
  Future<void> _refreshFromCache() async {
    // In "around note" mode (search jump), skip refresh — the user is viewing
    // historical context that shouldn't be disrupted by sync.
    if (_aroundNoteAnchor != null) return;

    final db = ref.read(appDatabaseProvider);
    final limit = _notes.length > 50 ? _notes.length : 50;
    final cached = await db.getCachedNotes(channelId, limit: limit);

    _notes = cached;
    _hasMore = true;
    if (cached.isNotEmpty) {
      _oldestNoteId = cached.last.id;
    }
    state = AsyncData(cached);
  }

  void _sortNotes() {
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Loads notes centered around a specific note ID (for search jump-to).
  ///
  /// Replaces the current state with ~25 notes surrounding the target,
  /// allowing the chat view to scroll to the target note in context.
  Future<void> loadAroundNote(int noteId) async {
    try {
      final notes = await client.search.getNotesAroundId(
        channelId,
        noteId,
        limit: 25,
      );
      _notes = notes;
      _hasMore = true;
      _aroundNoteAnchor = noteId;
      if (notes.isNotEmpty) {
        _oldestNoteId = notes.last.id;
      }
      state = AsyncData(_notes);
    } catch (e) {
      debugPrint('Notes.loadAroundNote failed: $e');
    }
  }

  Future<void> loadMore() async {
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
    if (isOnline(ref)) {
      try {
        final note = await client.chat.createNote(channelId, content);
        final current = state.value ?? [];
        if (!current.any((n) => n.id == note.id)) {
          _notes = [note, ...current];
          state = AsyncValue.data(_notes);
        }
        final db = ref.read(appDatabaseProvider);
        await db.cacheNotes(channelId, _notes);
        return;
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Network error — fall through to offline path
      }
    }

    // Offline: insert provisional note as dirty+isNew
    final db = ref.read(appDatabaseProvider);
    final mutationId = const Uuid().v4();
    final now = DateTime.now();
    final provisionalId = _nextProvisionalId--;
    final provisional = Note(
      id: provisionalId,
      channelId: channelId,
      content: content,
      clientMutationId: mutationId,
      createdAt: now,
      updatedAt: now,
    );

    await db.insertOfflineNote(
      provisionalId,
      channelId,
      now,
      jsonEncode(provisional.toJson()),
      mutationId,
    );

    final current = state.value ?? [];
    _notes = [provisional, ...current];
    state = AsyncValue.data(_notes);
  }

  Future<void> updateNote(int id, String content) async {
    final db = ref.read(appDatabaseProvider);

    // Provisional note (negative ID): it hasn't reached the server yet.
    // Update the cached JSON directly — no mutation queue needed.
    if (id < 0) {
      final current = state.value ?? [];
      _notes = current
          .map(
            (n) => n.id == id
                ? n.copyWith(content: content, updatedAt: DateTime.now())
                : n,
          )
          .toList();
      state = AsyncValue.data(_notes);

      // Update the cached JSON for the provisional note
      final updated = _notes.firstWhere((n) => n.id == id);
      await db.insertOfflineNote(
        id,
        channelId,
        updated.createdAt,
        jsonEncode(updated.toJson()),
        updated.clientMutationId,
      );
      return;
    }

    if (isOnline(ref)) {
      try {
        final updated = await client.chat.updateNote(id, content);
        final current = state.value ?? [];
        _notes = current.map((n) => n.id == id ? updated : n).toList();
        state = AsyncValue.data(_notes);
        await db.cacheNotes(channelId, _notes);
        return;
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Network error — fall through to offline path
      }
    }

    // Offline: update cached JSON as dirty
    final current = state.value ?? [];
    _notes = current
        .map(
          (n) => n.id == id
              ? n.copyWith(content: content, updatedAt: DateTime.now())
              : n,
        )
        .toList();
    state = AsyncValue.data(_notes);

    final updatedNote = _notes.firstWhere((n) => n.id == id);
    await db.upsertNoteDirty(updatedNote);
  }

  Future<void> deleteNote(int id) async {
    final db = ref.read(appDatabaseProvider);

    // Provisional note (negative ID): never reached the server.
    // Just remove from cache — no push needed.
    if (id < 0) {
      final current = state.value ?? [];
      _notes = current.where((n) => n.id != id).toList();
      state = AsyncValue.data(_notes);
      await db.deleteCachedNote(id);
      return;
    }

    if (isOnline(ref)) {
      try {
        await client.chat.deleteNote(id);

        await db.deleteCachedNote(id);
      } catch (e) {
        if (!isNetworkError(e)) rethrow;
        // Network error — mark as deleted locally for sync push
        await db.markNoteDeletedLocally(id);
      }
    } else {
      await db.markNoteDeletedLocally(id);
    }

    final current = state.value ?? [];
    _notes = current.where((n) => n.id != id).toList();
    state = AsyncValue.data(_notes);
  }

  /// Combines multiple notes into one. Online-only.
  /// Returns the combined note or throws on failure.
  Future<Note> combineNotes(List<int> noteIds) async {
    final combined = await client.chat.combineNotes(channelId, noteIds);

    // Remove source notes and add combined note to the front.
    // Also filter out combined.id — the WebSocket noteCreated event may
    // have already added it during the RPC await.
    final current = state.value ?? [];
    _notes = [
      combined,
      ...current.where(
        (n) => n.id != combined.id && !noteIds.contains(n.id),
      ),
    ];
    state = AsyncValue.data(_notes);

    // Update cache — use upsert (not bulk cacheNotes) to avoid UNIQUE
    // constraint race with reconnect/sync caching the same note.
    final db = ref.read(appDatabaseProvider);
    for (final id in noteIds) {
      await db.deleteCachedNote(id);
    }
    await db.upsertNoteFromServer(combined);

    return combined;
  }

  /// Explodes a note into multiple notes (reverse of combine). Online-only.
  Future<List<Note>> explodeNote(int noteId) async {
    final newNotes = await client.chat.explodeNote(noteId);

    // Remove original, add new notes (dedup against WebSocket additions)
    final current = state.value ?? [];
    final newIds = newNotes.map((n) => n.id).toSet();
    _notes = [
      ...newNotes,
      ...current.where((n) => n.id != noteId && !newIds.contains(n.id)),
    ];
    state = AsyncValue.data(_notes);

    // Update cache
    final db = ref.read(appDatabaseProvider);
    await db.deleteCachedNote(noteId);
    for (final n in newNotes) {
      await db.upsertNoteFromServer(n);
    }

    return newNotes;
  }
}
