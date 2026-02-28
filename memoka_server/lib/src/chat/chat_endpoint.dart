import 'dart:async';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';
import '../shared/note_query.dart';
import '../sync/version_helper.dart';
import 'link_preview_service.dart';

/// Endpoint for managing channels and notes with real-time updates.
class ChatEndpoint extends Endpoint {
  /// Returns all channels sorted by pinned first, then position, then updatedAt.
  /// Excludes tombstoned channels (deletedAt IS NOT NULL).
  Future<List<Channel>> getChannels(Session session) async {
    final channels = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(false) & t.deletedAt.equals(null),
    );

    // Sort: pinned first, then by position ascending, then by updatedAt descending
    channels.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      final posCmp = a.position.compareTo(b.position);
      if (posCmp != 0) return posCmp;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return channels;
  }

  /// Returns notes for a channel with cursor-based pagination.
  /// Uses [beforeId] for loading older messages (scroll up behavior).
  /// Efficiently loads attachments with LEFT JOIN to prevent N+1 queries.
  /// Excludes tombstoned notes (deletedAt IS NOT NULL).
  Future<List<Note>> getNotes(
    Session session,
    int channelId, {
    int? beforeId,
    int limit = 50,
  }) async {
    final beforeClause = beforeId != null ? 'AND n.id < $beforeId' : '';

    return NoteQuery.findWithAttachments(
      session,
      whereClause:
          'n."channelId" = $channelId AND n.archived = false AND n."deletedAt" IS NULL $beforeClause',
      limit: limit,
    );
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

    // Assign sortOrder / position as max + 1 so new channels appear at bottom
    final existing = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(false) & t.deletedAt.equals(null),
      orderBy: (t) => t.sortOrder,
      orderDescending: true,
      limit: 1,
    );
    final nextOrder = existing.isNotEmpty ? existing.first.sortOrder + 1 : 0;
    final nextPosition = existing.isNotEmpty
        ? existing.first.position + 1.0
        : 1.0;

    final saved = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      final channel = Channel(
        name: name.trim(),
        emoji: emoji,
        sortOrder: nextOrder,
        position: nextPosition,
        version: newVersion,
      );
      return Channel.db.insertRow(session, channel, transaction: tx);
    });

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

    final updated = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      channel.version = newVersion;
      return Channel.db.updateRow(session, channel, transaction: tx);
    });

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
  /// Accepts an ordered list of channel IDs; assigns position = index + 1.
  /// Normalises all positions to 1.0, 2.0, 3.0... when any two adjacent
  /// positions differ by less than epsilon (1e-10).
  Future<void> reorderChannels(
    Session session,
    List<int> channelIds,
  ) async {
    await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      for (var i = 0; i < channelIds.length; i++) {
        final channel = await Channel.db.findById(
          session,
          channelIds[i],
          transaction: tx,
        );
        if (channel == null) continue;
        channel.sortOrder = i;
        channel.position = (i + 1).toDouble();
        channel.version = newVersion;
        await Channel.db.updateRow(session, channel, transaction: tx);
      }
    });

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(type: 'channelUpdated'),
    );
  }

  /// Tombstones a channel (sets deletedAt) instead of physically deleting it.
  /// Also tombstones all notes in the channel. Rejects if it's the last channel.
  /// Media file cleanup should happen in a background task.
  Future<void> deleteChannel(Session session, int id) async {
    final channel = await Channel.db.findById(session, id);

    // Only check "last channel" for active (non-archived, non-deleted) channels
    if (channel != null && !channel.archived && channel.deletedAt == null) {
      final activeCount = await Channel.db.count(
        session,
        where: (t) =>
            t.archived.equals(false) &
            t.isSystemChannel.equals(false) &
            t.deletedAt.equals(null),
      );
      if (activeCount <= 1) {
        throw Exception('Cannot delete the last remaining channel');
      }
    }

    // Delete media files for this channel (still immediate for disk cleanup)
    final mediaDir = Directory('${ServerConstants.mediaBaseDir}/channels/$id');
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
      session.log('Deleted media directory for channel $id');
    }

    // Tombstone: set deletedAt instead of physical delete.
    // Also tombstone all notes in this channel.
    final now = DateTime.now();
    await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);

      if (channel != null) {
        channel.deletedAt = now;
        channel.version = newVersion;
        await Channel.db.updateRow(session, channel, transaction: tx);
      }

      // Tombstone all notes in the channel
      await session.db.unsafeQuery(
        'UPDATE "notes" SET "deletedAt" = \'${now.toIso8601String()}\', "version" = $newVersion WHERE "channelId" = $id',
        transaction: tx,
      );
    });

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

    final saved = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      final note = Note(
        channelId: channelId,
        content: content.trim(),
        clientMutationId: clientMutationId,
        version: newVersion,
      );
      final savedNote = await Note.db.insertRow(session, note, transaction: tx);

      // Update channel's updatedAt + version
      final channel = await Channel.db.findById(
        session,
        channelId,
        transaction: tx,
      );
      if (channel != null) {
        channel.updatedAt = DateTime.now();
        channel.version = newVersion;
        await Channel.db.updateRow(session, channel, transaction: tx);
      }

      return savedNote;
    });

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

      // Update note with preview — bump version
      note.linkPreview = preview;
      note.updatedAt = DateTime.now();

      final updated = await session.db.transaction((tx) async {
        final newVersion = await incrementGlobalVersion(
          session,
          transaction: tx,
        );
        note.version = newVersion;
        return Note.db.updateRow(session, note, transaction: tx);
      });

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

    final updated = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      note.version = newVersion;
      return Note.db.updateRow(session, note, transaction: tx);
    });

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteUpdated',
        note: updated,
      ),
    );

    return updated;
  }

  /// Deletes a note - archives it (soft-delete) if in a regular channel,
  /// permanently tombstones it if already archived (from Archive view).
  Future<void> deleteNote(Session session, int id) async {
    final note = await Note.db.findById(session, id);
    if (note == null) {
      throw Exception('Note not found');
    }

    // Check if already archived
    if (note.archived) {
      // PERMANENT DELETE from Archive — use tombstone
      await _tombstoneNote(session, note);
    } else {
      // SOFT DELETE - mark as archived
      await _archiveNote(session, note);
    }
  }

  /// Archives a note by marking it as archived (soft delete).
  Future<void> _archiveNote(Session session, Note note) async {
    final now = DateTime.now();
    note.archived = true;
    note.archivedAt = now;
    note.updatedAt = now;

    await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      note.version = newVersion;
      await Note.db.updateRow(session, note, transaction: tx);
    });

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'noteArchived',
        noteId: note.id!,
        channelId: note.channelId,
      ),
    );
  }

  /// Tombstones a note (sets deletedAt) and cleans up media files.
  Future<void> _tombstoneNote(Session session, Note note) async {
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

    // Tombstone: set deletedAt instead of physical delete
    final now = DateTime.now();
    note.deletedAt = now;
    note.updatedAt = now;

    await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      note.version = newVersion;
      await Note.db.updateRow(session, note, transaction: tx);
    });

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

    await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      note.version = newVersion;
      await Note.db.updateRow(session, note, transaction: tx);
    });

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
      where: (t) =>
          t.archived.equals(false) &
          t.isSystemChannel.equals(false) &
          t.deletedAt.equals(null),
    );
    if (activeCount <= 1) {
      throw Exception('Cannot archive the last remaining channel');
    }

    final now = DateTime.now();
    channel.archived = true;
    channel.archivedAt = now;
    channel.pinned = false;

    await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      channel.version = newVersion;
      await Channel.db.updateRow(session, channel, transaction: tx);
    });

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
      where: (t) =>
          t.archived.equals(false) &
          t.deletedAt.equals(null) &
          t.name.equals(channel.name),
    );
    if (existing.isNotEmpty) {
      channel.name = '${channel.name} (Restored)';
    }

    channel.archived = false;
    channel.archivedAt = null;
    channel.pinned = false;
    channel.updatedAt = DateTime.now();

    final updated = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      channel.version = newVersion;
      return Channel.db.updateRow(session, channel, transaction: tx);
    });

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
  /// Excludes tombstoned entities (deletedAt IS NOT NULL).
  Future<List<ArchiveItem>> getArchiveItems(
    Session session, {
    int limit = 50,
  }) async {
    // Fetch archived notes (exclude tombstoned)
    final archivedNotes = await Note.db.find(
      session,
      where: (t) => t.archived.equals(true) & t.deletedAt.equals(null),
      orderBy: (t) => t.archivedAt,
      orderDescending: true,
      limit: limit,
    );

    // Fetch archived channels (exclude tombstoned)
    final archivedChannels = await Channel.db.find(
      session,
      where: (t) => t.archived.equals(true) & t.deletedAt.equals(null),
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
      where: (t) => t.channelId.equals(channelId) & t.deletedAt.equals(null),
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
