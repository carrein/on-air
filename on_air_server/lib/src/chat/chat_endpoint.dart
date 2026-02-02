import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'link_preview_service.dart';

/// Endpoint for managing channels and notes with real-time updates.
class ChatEndpoint extends Endpoint {
  /// Returns all channels sorted by last modified (newest first).
  /// Pinned channels appear at the top, also sorted by last modified.
  Future<List<Channel>> getChannels(Session session) async {
    final channels = await Channel.db.find(
      session,
      orderBy: (t) => t.updatedAt,
      orderDescending: true,
    );

    // Sort pinned channels first, then by updatedAt
    channels.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return channels;
  }

  /// Returns notes for a channel with cursor-based pagination.
  /// Uses [beforeId] for loading older messages (scroll up behavior).
  Future<List<Note>> getNotes(
    Session session,
    int channelId, {
    int? beforeId,
    int limit = 50,
  }) async {
    // If beforeId is provided, filter for notes with id < beforeId
    if (beforeId != null) {
      final notes = await Note.db.find(
        session,
        where: (t) => t.channelId.equals(channelId),
        orderBy: (t) => t.id,
        orderDescending: true,
      );
      // Filter in memory for id < beforeId
      return notes.where((n) => n.id! < beforeId).take(limit).toList();
    }

    // No cursor, return latest notes
    return await Note.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Creates a new channel and broadcasts the event.
  Future<Channel> createChannel(
    Session session,
    String name, {
    String emoji = '💬',
  }) async {
    if (name.trim().isEmpty) {
      throw Exception('Channel name cannot be empty');
    }

    final channel = Channel(name: name, emoji: emoji);
    final saved = await Channel.db.insertRow(session, channel);

    // Broadcast creation event (only if Redis is available)
    try {
      await session.messages.postMessage(
        'chat_events',
        ChatEvent(
          type: 'channelCreated',
          channel: saved,
        ),
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }

    return saved;
  }

  /// Updates a channel's name, emoji, or pinned status.
  Future<Channel> updateChannel(
    Session session,
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) async {
    final channel = await Channel.db.findById(session, id);
    if (channel == null) {
      throw Exception('Channel not found');
    }

    if (name != null) {
      if (name.trim().isEmpty) {
        throw Exception('Channel name cannot be empty');
      }
      channel.name = name;
    }

    if (emoji != null) {
      channel.emoji = emoji;
    }

    if (pinned != null) {
      channel.pinned = pinned;
    }

    channel.updatedAt = DateTime.now();
    final updated = await Channel.db.updateRow(session, channel);

    // Broadcast update event
    try {
      await session.messages.postMessage(
        'chat_events',
        ChatEvent(
          type: 'channelUpdated',
          channel: updated,
        ),
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }

    return updated;
  }

  /// Deletes a channel and cascades to delete its notes.
  /// Rejects if it's the last remaining channel.
  Future<void> deleteChannel(Session session, int id) async {
    final count = await Channel.db.count(session);

    if (count <= 1) {
      throw Exception('Cannot delete the last remaining channel');
    }

    await Channel.db.deleteWhere(session, where: (t) => t.id.equals(id));

    // Broadcast deletion event (only if Redis is available)
    try {
      await session.messages.postMessage(
        'chat_events',
        ChatEvent(
          type: 'channelDeleted',
          channelId: id,
        ),
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }
  }

  /// Creates a new note and broadcasts the event.
  /// Also updates the channel's updatedAt timestamp.
  /// Asynchronously fetches link preview if URL is detected in content.
  Future<Note> createNote(
    Session session,
    int channelId,
    String content,
  ) async {
    if (content.trim().isEmpty) {
      throw Exception('Note content cannot be empty');
    }

    final note = Note(
      channelId: channelId,
      content: content,
    );
    final saved = await Note.db.insertRow(session, note);

    // Update channel's updatedAt timestamp
    final channel = await Channel.db.findById(session, channelId);
    if (channel != null) {
      channel.updatedAt = DateTime.now();
      await Channel.db.updateRow(session, channel);
    }

    // Broadcast creation event (only if Redis is available)
    try {
      await session.messages.postMessage(
        'chat_events',
        ChatEvent(
          type: 'noteCreated',
          note: saved,
        ),
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }

    // Fetch link preview asynchronously (don't await)
    _fetchLinkPreviewAsync(session, saved);

    return saved;
  }

  /// Fetch link preview metadata asynchronously and broadcast update.
  Future<void> _fetchLinkPreviewAsync(Session session, Note note) async {
    try {
      // Extract first URL from content
      final url = LinkPreviewService.extractFirstUrl(note.content);
      if (url == null) return;

      // Fetch preview metadata
      final preview = await LinkPreviewService.fetchPreview(url);
      if (preview == null) return;

      // Update note with preview
      note.linkPreview = preview;
      note.updatedAt = DateTime.now();
      final updated = await Note.db.updateRow(session, note);

      // Broadcast preview ready event
      try {
        await session.messages.postMessage(
          'chat_events',
          ChatEvent(
            type: 'noteLinkPreviewReady',
            note: updated,
          ),
          global: true,
        );
      } catch (_) {
        // Redis not available, skip broadcasting
      }
    } catch (e) {
      // Log error but don't fail
      print('Failed to fetch link preview: $e');
    }
  }

  /// Updates a note's content (last-write-wins strategy).
  Future<Note> updateNote(Session session, int id, String content) async {
    if (content.trim().isEmpty) {
      throw Exception('Note content cannot be empty');
    }

    final note = await Note.db.findById(session, id);
    if (note == null) {
      throw Exception('Note not found');
    }

    note.content = content;
    note.updatedAt = DateTime.now();

    final updated = await Note.db.updateRow(session, note);

    // Broadcast update event (only if Redis is available)
    try {
      await session.messages.postMessage(
        'chat_events',
        ChatEvent(
          type: 'noteUpdated',
          note: updated,
        ),
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }

    return updated;
  }

  /// Deletes a note and broadcasts the event.
  Future<void> deleteNote(Session session, int id) async {
    final note = await Note.db.findById(session, id);
    if (note == null) {
      throw Exception('Note not found');
    }

    await Note.db.deleteWhere(session, where: (t) => t.id.equals(id));

    // Broadcast deletion event (only if Redis is available)
    try {
      await session.messages.postMessage(
        'chat_events',
        ChatEvent(
          type: 'noteDeleted',
          noteId: id,
          channelId: note.channelId,
        ),
        global: true,
      );
    } catch (_) {
      // Redis not available (e.g., in test mode), skip broadcasting
    }
  }

  /// Streaming endpoint for real-time updates.
  /// Subscribes to all chat events (channel and note changes).
  Stream<ChatEvent> chat(Session session) async* {
    final stream = session.messages.createStream<ChatEvent>('chat_events');

    await for (final event in stream) {
      yield event;
    }
  }
}
