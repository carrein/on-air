import 'dart:async';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';
import 'link_preview_service.dart';

/// Endpoint for managing channels and notes with real-time updates.
class ChatEndpoint extends Endpoint {
  /// Returns all channels sorted by pinned first, then sortOrder, then updatedAt.
  Future<List<Channel>> getChannels(Session session) async {
    final channels = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(false),
    );

    // Sort: pinned first, then by sortOrder ascending, then by updatedAt descending
    channels.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      final orderCmp = a.sortOrder.compareTo(b.sortOrder);
      if (orderCmp != 0) return orderCmp;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return channels;
  }

  /// Returns notes for a channel with cursor-based pagination.
  /// Uses [beforeId] for loading older messages (scroll up behavior).
  /// Efficiently loads attachments with LEFT JOIN to prevent N+1 queries.
  Future<List<Note>> getNotes(
    Session session,
    int channelId, {
    int? beforeId,
    int limit = 50,
  }) async {
    // Build SQL query with LEFT JOIN to load attachments
    final beforeClause = beforeId != null ? 'AND n.id < $beforeId' : '';

    final result = await session.db.unsafeQuery('''
      SELECT
        n.*,
        COALESCE(
          json_agg(
            json_build_object(
              'id', ma.id,
              'noteId', ma."noteId",
              'channelId', ma."channelId",
              'filePath', ma."filePath",
              'originalFilename', ma."originalFilename",
              'mimeType', ma."mimeType",
              'fileSize', ma."fileSize",
              'width', ma.width,
              'height', ma.height,
              'thumbnailPath', ma."thumbnailPath",
              'compressed', ma.compressed,
              'animated', ma.animated,
              'contentHash', ma."contentHash",
              'uploadedAt', ma."uploadedAt"
            ) ORDER BY ma.id
          ) FILTER (WHERE ma.id IS NOT NULL),
          '[]'::json
        ) as attachments_json
      FROM notes n
      LEFT JOIN media_attachments ma ON ma."noteId" = n.id
      WHERE n."channelId" = $channelId AND n.archived = false $beforeClause
      GROUP BY n.id
      ORDER BY n."createdAt" DESC
      LIMIT $limit
    ''');

    // Parse results into Note objects
    final notes = <Note>[];
    for (final row in result) {
      final note = Note.fromJson(row.toColumnMap());

      // Parse attachments from JSON
      final attachmentsJson = row.toColumnMap()['attachments_json'];
      if (attachmentsJson != null && attachmentsJson != '[]') {
        final attachmentsList = attachmentsJson as List;
        note.attachments = attachmentsList
            .map(
              (json) => MediaAttachment.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      notes.add(note);
    }

    return notes;
  }

  /// Creates a new channel and broadcasts the event.
  Future<Channel> createChannel(
    Session session,
    String name, {
    String emoji = 'chatCircle',
  }) async {
    // Input validation
    if (name.trim().isEmpty) {
      throw Exception('Channel name cannot be empty');
    }
    if (name.length > 100) {
      throw Exception('Channel name too long (max 100 characters)');
    }
    if (emoji.length > 30) {
      throw Exception('Icon key too long (max 30 characters)');
    }

    // Assign sortOrder as max + 1 so new channels appear at the bottom
    final existing = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(false),
      orderBy: (t) => t.sortOrder,
      orderDescending: true,
      limit: 1,
    );
    final nextOrder = existing.isNotEmpty ? existing.first.sortOrder + 1 : 0;

    final channel = Channel(
      name: name.trim(),
      emoji: emoji,
      sortOrder: nextOrder,
    );
    final saved = await Channel.db.insertRow(session, channel);

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'channelCreated',
        channel: saved,
      ),
    );

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

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'channelUpdated',
        channel: updated,
      ),
    );

    return updated;
  }

  /// Reorders channels within a group (pinned or unpinned).
  /// Accepts an ordered list of channel IDs; assigns sortOrder = index.
  Future<void> reorderChannels(
    Session session,
    List<int> channelIds,
  ) async {
    for (var i = 0; i < channelIds.length; i++) {
      final channel = await Channel.db.findById(session, channelIds[i]);
      if (channel == null) continue;
      channel.sortOrder = i;
      await Channel.db.updateRow(session, channel);
    }

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(type: 'channelUpdated'),
    );
  }

  /// Deletes a channel and cascades to delete its notes and media files.
  /// Rejects if it's the last remaining active (non-archived) channel.
  Future<void> deleteChannel(Session session, int id) async {
    final channel = await Channel.db.findById(session, id);

    // Only check "last channel" for active (non-archived) channels
    if (channel != null && !channel.archived) {
      final activeCount = await Channel.db.count(
        session,
        where: (t) =>
            t.archived.equals(false) & t.isSystemChannel.equals(false),
      );
      if (activeCount <= 1) {
        throw Exception('Cannot delete the last remaining channel');
      }
    }

    // Delete media files for this channel
    final mediaDir = Directory('${ServerConstants.mediaBaseDir}/channels/$id');
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
      session.log('Deleted media directory for channel $id');
    }

    // Delete from database (cascade will handle notes and attachments)
    await Channel.db.deleteWhere(session, where: (t) => t.id.equals(id));

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'channelDeleted',
        channelId: id,
      ),
    );
  }

  /// Creates a new note and broadcasts the event.
  /// Also updates the channel's updatedAt timestamp.
  /// Asynchronously fetches link preview if URL is detected in content.
  /// [clientMutationId] is an optional idempotency key for offline-created notes.
  /// If a note with this key already exists, it is returned without creating a duplicate.
  Future<Note> createNote(
    Session session,
    int channelId,
    String content, {
    String? clientMutationId,
  }) async {
    // Input validation
    if (content.trim().isEmpty) {
      throw Exception('Note content cannot be empty');
    }
    if (content.length > 200000) {
      throw Exception('Note content too long (max 200,000 characters)');
    }

    // Idempotency: if this mutation was already applied, return the existing note.
    if (clientMutationId != null) {
      final existing = await Note.db.findFirstRow(
        session,
        where: (n) => n.clientMutationId.equals(clientMutationId),
      );
      if (existing != null) return existing;
    }

    final note = Note(
      channelId: channelId,
      content: content.trim(),
      clientMutationId: clientMutationId,
    );
    final saved = await Note.db.insertRow(session, note);

    // Update channel's updatedAt timestamp
    final channel = await Channel.db.findById(session, channelId);
    if (channel != null) {
      channel.updatedAt = DateTime.now();
      await Channel.db.updateRow(session, channel);
    }

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteCreated',
        note: saved,
      ),
    );

    // Fetch link preview asynchronously (don't await)
    unawaited(_fetchLinkPreviewAsync(session, saved));

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
      if (preview == null) {
        session.log('Failed to fetch link preview for: $url');
        return;
      }

      // Update note with preview
      note.linkPreview = preview;
      note.updatedAt = DateTime.now();
      final updated = await Note.db.updateRow(session, note);

      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(
          type: 'noteLinkPreviewReady',
          note: updated,
        ),
      );
    } catch (e, stackTrace) {
      // Log error but don't fail
      session.log(
        'Error fetching link preview: $e\n$stackTrace',
        level: LogLevel.error,
      );
    }
  }

  /// Updates a note's content (last-write-wins strategy).
  Future<Note> updateNote(Session session, int id, String content) async {
    // Input validation
    if (content.trim().isEmpty) {
      throw Exception('Note content cannot be empty');
    }
    if (content.length > 200000) {
      throw Exception('Note content too long (max 200,000 characters)');
    }

    final note = await Note.db.findById(session, id);
    if (note == null) {
      throw Exception('Note not found');
    }

    note.content = content.trim();
    note.updatedAt = DateTime.now();

    final updated = await Note.db.updateRow(session, note);

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteUpdated',
        note: updated,
      ),
    );

    return updated;
  }

  /// Deletes a note - archives it if in a regular channel, permanently deletes if in Archive.
  Future<void> deleteNote(Session session, int id) async {
    final note = await Note.db.findById(session, id);
    if (note == null) {
      throw Exception('Note not found');
    }

    // Check if already archived
    if (note.archived) {
      // PERMANENT DELETE from Archive
      await _permanentlyDeleteNote(session, note);
    } else {
      // SOFT DELETE - mark as archived
      await _archiveNote(session, note);
    }
  }

  /// Archives a note by marking it as archived (soft delete).
  Future<void> _archiveNote(Session session, Note note) async {
    note.archived = true;
    note.archivedAt = DateTime.now();
    note.updatedAt = DateTime.now();
    await Note.db.updateRow(session, note);

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteArchived',
        noteId: note.id!,
        channelId: note.channelId,
      ),
    );
  }

  /// Permanently deletes a note, its media attachments, and broadcasts the event.
  Future<void> _permanentlyDeleteNote(Session session, Note note) async {
    // Get all media attachments for this note
    final attachments = await MediaAttachment.db.find(
      session,
      where: (t) => t.noteId.equals(note.id!),
    );

    // Delete media files from disk
    for (final attachment in attachments) {
      try {
        // Delete main file
        final mainFile = File(
          '${ServerConstants.mediaBaseDir}/${attachment.filePath}',
        );
        if (await mainFile.exists()) {
          await mainFile.delete();
          session.log('Deleted media file: ${attachment.filePath}');
        }

        // Delete thumbnail if exists
        if (attachment.thumbnailPath != null) {
          final thumbnailFile = File(
            '${ServerConstants.mediaBaseDir}/channels/${attachment.channelId}/${attachment.thumbnailPath}',
          );
          if (await thumbnailFile.exists()) {
            await thumbnailFile.delete();
            session.log('Deleted thumbnail: ${attachment.thumbnailPath}');
          }
        }
      } catch (e) {
        session.log(
          'Failed to delete media files for attachment ${attachment.id}: $e',
          level: LogLevel.error,
        );
      }
    }

    // Delete from database (cascade will delete attachment records)
    await Note.db.deleteWhere(session, where: (t) => t.id.equals(note.id!));

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteDeleted',
        noteId: note.id!,
        channelId: note.channelId,
      ),
    );
  }

  /// Restores a note from Archive back to its channel.
  Future<void> restoreNote(Session session, int id) async {
    final note = await Note.db.findById(session, id);
    if (note == null) {
      throw Exception('Note not found');
    }

    // Can only restore archived notes
    if (!note.archived) {
      throw Exception('Note is not archived');
    }

    // Verify channel still exists
    final channel = await Channel.db.findById(session, note.channelId);
    if (channel == null) {
      throw Exception('Original channel no longer exists');
    }

    note.archived = false;
    note.archivedAt = null;
    note.updatedAt = DateTime.now();
    await Note.db.updateRow(session, note);

    final restoredNote = await Note.db.findById(session, note.id!);
    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteRestored',
        noteId: note.id!,
        channelId: note.channelId,
        note: restoredNote,
      ),
    );
  }

  /// Archives a channel (soft delete). Notes stay with the channel.
  Future<void> archiveChannel(Session session, int id) async {
    final channel = await Channel.db.findById(session, id);
    if (channel == null) {
      throw Exception('Channel not found');
    }
    if (channel.isSystemChannel) {
      throw Exception('Cannot archive a system channel');
    }
    if (channel.archived) {
      throw Exception('Channel is already archived');
    }

    // Prevent archiving the last active channel
    final activeCount = await Channel.db.count(
      session,
      where: (t) => t.archived.equals(false) & t.isSystemChannel.equals(false),
    );
    if (activeCount <= 1) {
      throw Exception('Cannot archive the last remaining channel');
    }

    channel.archived = true;
    channel.archivedAt = DateTime.now();
    channel.pinned = false;
    await Channel.db.updateRow(session, channel);

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'channelArchived',
        channelId: id,
      ),
    );
  }

  /// Restores an archived channel back to the sidebar.
  Future<Channel> restoreChannel(Session session, int id) async {
    final channel = await Channel.db.findById(session, id);
    if (channel == null) {
      throw Exception('Channel not found');
    }
    if (!channel.archived) {
      throw Exception('Channel is not archived');
    }

    // Check name conflict with active channels
    final existing = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(false) & t.name.equals(channel.name),
    );
    if (existing.isNotEmpty) {
      channel.name = '${channel.name} (Restored)';
    }

    channel.archived = false;
    channel.archivedAt = null;
    channel.pinned = false;
    channel.updatedAt = DateTime.now();
    final updated = await Channel.db.updateRow(session, channel);

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'channelRestored',
        channel: updated,
      ),
    );

    return updated;
  }

  /// Returns a mixed list of archived notes and archived channels,
  /// sorted by archivedAt descending (newest first).
  Future<List<ArchiveItem>> getArchiveItems(
    Session session, {
    int limit = 50,
  }) async {
    // Fetch archived notes
    final archivedNotes = await Note.db.find(
      session,
      where: (t) => t.archived.equals(true),
      orderBy: (t) => t.archivedAt,
      orderDescending: true,
      limit: limit,
    );

    // Fetch archived channels
    final archivedChannels = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(true),
      orderBy: (t) => t.archivedAt,
      orderDescending: true,
      limit: limit,
    );

    // Build mixed list
    final items = <ArchiveItem>[];

    for (final note in archivedNotes) {
      items.add(
        ArchiveItem(
          type: 'note',
          note: note,
          archivedAt: note.archivedAt ?? note.updatedAt,
        ),
      );
    }

    for (final channel in archivedChannels) {
      items.add(
        ArchiveItem(
          type: 'channel',
          channel: channel,
          archivedAt: channel.archivedAt ?? channel.updatedAt,
        ),
      );
    }

    // Sort by archivedAt descending
    items.sort((a, b) => b.archivedAt.compareTo(a.archivedAt));

    // Limit total items
    if (items.length > limit) {
      return items.sublist(0, limit);
    }

    return items;
  }

  /// Returns the count of notes in an archived channel (for confirmation dialog).
  Future<int> getArchivedChannelNoteCount(
    Session session,
    int channelId,
  ) async {
    return await Note.db.count(
      session,
      where: (t) => t.channelId.equals(channelId),
    );
  }

  /// Streaming endpoint for real-time updates.
  /// Subscribes to all chat events (channel and note changes).
  Stream<ChatEvent> chat(Session session) async* {
    final stream = session.messages.createStream<ChatEvent>(
      ServerConstants.chatEventsChannel,
    );

    await for (final event in stream) {
      yield event;
    }
  }
}
