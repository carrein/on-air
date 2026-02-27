import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';
import 'version_helper.dart';

/// Endpoint for state-based reconciliation sync.
///
/// Pull phase: client fetches all entities changed since its last known version.
/// Push phase: client sends dirty local entities; server validates and applies.
class SyncEndpoint extends Endpoint {
  /// Returns all channels and notes changed since [sinceVersion].
  ///
  /// Includes tombstoned entities (deletedAt != null) so clients can remove them.
  /// Pass sinceVersion = 0 for a full sync (first launch / fresh install).
  Future<SyncPullResponse> syncPull(
    Session session,
    int sinceVersion,
  ) async {
    // Channels changed since sinceVersion (includes archived, tombstoned)
    final channels = await Channel.db.find(
      session,
      where: (t) => t.version > sinceVersion,
    );

    // Notes changed since sinceVersion with media attachments via LEFT JOIN
    final noteRows = await session.db.unsafeQuery('''
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
      WHERE n.version > $sinceVersion
      GROUP BY n.id
    ''');

    final notes = <Note>[];
    for (final row in noteRows) {
      final note = Note.fromJson(row.toColumnMap());
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

    final currentGlobalVersion = await readGlobalVersion(session);

    return SyncPullResponse(
      globalVersion: currentGlobalVersion,
      channels: channels,
      notes: notes,
    );
  }

  /// Processes a batch of local dirty entities and applies them to the server.
  ///
  /// Each change is processed in its own transaction — partial apply is supported.
  /// Returns per-entity results: applied / rejected / already_applied.
  Future<SyncPushResponse> syncPush(
    Session session,
    List<SyncChange> changes,
  ) async {
    // Sort changes for deterministic ordering: entity type first, then ID
    final sorted = List<SyncChange>.from(changes)
      ..sort((a, b) {
        final typeCmp = a.entityType.compareTo(b.entityType);
        if (typeCmp != 0) return typeCmp;
        final aId = a.tempId ?? _extractId(a.entityJson) ?? 0;
        final bId = b.tempId ?? _extractId(b.entityJson) ?? 0;
        return aId.compareTo(bId);
      });

    final results = <SyncResult>[];
    for (final change in sorted) {
      final result = await _processChange(session, change);
      results.add(result);
    }

    final currentGlobalVersion = await readGlobalVersion(session);

    return SyncPushResponse(
      globalVersion: currentGlobalVersion,
      results: results,
    );
  }

  Future<SyncResult> _processChange(Session session, SyncChange change) async {
    try {
      if (change.entityType == 'channel') {
        return await _processChannelChange(session, change);
      } else if (change.entityType == 'note') {
        return await _processNoteChange(session, change);
      } else {
        return SyncResult(
          status: 'rejected',
          reason: 'Unknown entityType: ${change.entityType}',
          entityType: change.entityType,
          tempId: change.tempId,
        );
      }
    } catch (e) {
      return SyncResult(
        status: 'rejected',
        reason: e.toString(),
        entityType: change.entityType,
        tempId: change.tempId,
      );
    }
  }

  Future<SyncResult> _processChannelChange(
    Session session,
    SyncChange change,
  ) async {
    final entityMap = jsonDecode(change.entityJson) as Map<String, dynamic>;
    final isCreate = change.baseVersion == 0 && change.tempId != null;

    if (isCreate) {
      // Idempotency check
      if (change.clientMutationId != null) {
        final existing = await Channel.db.findFirstRow(
          session,
          where: (c) => c.clientMutationId.equals(change.clientMutationId!),
        );
        if (existing != null) {
          return SyncResult(
            status: 'already_applied',
            tempId: change.tempId,
            serverId: existing.id,
            entityType: 'channel',
            entityJson: jsonEncode(existing.toJson()),
          );
        }
      }

      // Validate input
      final name = (entityMap['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        return SyncResult(
          status: 'rejected',
          reason: 'Channel name cannot be empty',
          entityType: 'channel',
          tempId: change.tempId,
        );
      }
      if (name.length > 100) {
        return SyncResult(
          status: 'rejected',
          reason: 'Channel name too long (max 100 characters)',
          entityType: 'channel',
          tempId: change.tempId,
        );
      }

      final emoji = (entityMap['emoji'] as String?) ?? 'chatCircle';

      // Assign position at end
      final existing = await Channel.db.find(
        session,
        where: (t) => t.archived.equals(false) & t.deletedAt.equals(null),
        orderBy: (t) => t.position,
        orderDescending: true,
        limit: 1,
      );
      final nextPosition = existing.isNotEmpty
          ? existing.first.position + 1.0
          : 1.0;

      final saved = await session.db.transaction((tx) async {
        final newVersion = await incrementGlobalVersion(
          session,
          transaction: tx,
        );
        final channel = Channel(
          name: name,
          emoji: emoji,
          position: nextPosition,
          sortOrder: nextPosition.toInt(),
          clientMutationId: change.clientMutationId,
          version: newVersion,
        );
        return Channel.db.insertRow(session, channel, transaction: tx);
      });

      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(type: 'channelCreated', channel: saved),
      );

      return SyncResult(
        status: 'applied',
        tempId: change.tempId,
        serverId: saved.id,
        entityType: 'channel',
        entityJson: jsonEncode(saved.toJson()),
      );
    }

    // Update or delete
    final serverId = _extractId(change.entityJson);
    if (serverId == null) {
      return SyncResult(
        status: 'rejected',
        reason: 'Missing server ID for update/delete',
        entityType: 'channel',
        tempId: change.tempId,
      );
    }

    final channel = await Channel.db.findById(session, serverId);
    if (channel == null) {
      return SyncResult(
        status: 'rejected',
        reason: 'Channel not found',
        entityType: 'channel',
      );
    }

    // Version check
    if (channel.version != change.baseVersion) {
      return SyncResult(
        status: 'rejected',
        reason:
            'Version mismatch (server: ${channel.version}, client: ${change.baseVersion})',
        entityType: 'channel',
        entityJson: jsonEncode(channel.toJson()),
      );
    }

    if (change.deleted) {
      // Tombstone delete
      final activeCount = await Channel.db.count(
        session,
        where: (t) =>
            t.archived.equals(false) &
            t.isSystemChannel.equals(false) &
            t.deletedAt.equals(null),
      );
      if (!channel.archived && channel.deletedAt == null && activeCount <= 1) {
        return SyncResult(
          status: 'rejected',
          reason: 'Cannot delete the last remaining channel',
          entityType: 'channel',
          entityJson: jsonEncode(channel.toJson()),
        );
      }

      final now = DateTime.now();
      await session.db.transaction((tx) async {
        final newVersion = await incrementGlobalVersion(
          session,
          transaction: tx,
        );
        channel.deletedAt = now;
        channel.version = newVersion;
        await Channel.db.updateRow(session, channel, transaction: tx);
        await session.db.unsafeQuery(
          'UPDATE "notes" SET "deletedAt" = \'${now.toIso8601String()}\', "version" = $newVersion WHERE "channelId" = $serverId',
          transaction: tx,
        );
      });

      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(type: 'channelDeleted', channelId: serverId),
      );

      return SyncResult(
        status: 'applied',
        entityType: 'channel',
        entityJson: jsonEncode(channel.toJson()),
      );
    }

    // Regular update — apply fields from entityJson
    final name = (entityMap['name'] as String?)?.trim();
    if (name != null) {
      if (name.isEmpty) {
        return SyncResult(
          status: 'rejected',
          reason: 'Channel name cannot be empty',
          entityType: 'channel',
          entityJson: jsonEncode(channel.toJson()),
        );
      }
      channel.name = name;
    }
    if (entityMap.containsKey('emoji')) {
      channel.emoji = entityMap['emoji'] as String? ?? channel.emoji;
    }
    if (entityMap.containsKey('pinned')) {
      channel.pinned = entityMap['pinned'] as bool? ?? channel.pinned;
    }
    if (entityMap.containsKey('archived')) {
      channel.archived = entityMap['archived'] as bool? ?? channel.archived;
      if (channel.archived) {
        channel.archivedAt =
            DateTime.tryParse(
              entityMap['archivedAt'] as String? ?? '',
            ) ??
            DateTime.now();
      } else {
        channel.archivedAt = null;
      }
    }
    if (entityMap.containsKey('position')) {
      channel.position =
          (entityMap['position'] as num?)?.toDouble() ?? channel.position;
    }

    channel.updatedAt = DateTime.now();

    final updated = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      channel.version = newVersion;
      return Channel.db.updateRow(session, channel, transaction: tx);
    });

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(type: 'channelUpdated', channel: updated),
    );

    return SyncResult(
      status: 'applied',
      entityType: 'channel',
      entityJson: jsonEncode(updated.toJson()),
    );
  }

  Future<SyncResult> _processNoteChange(
    Session session,
    SyncChange change,
  ) async {
    final entityMap = jsonDecode(change.entityJson) as Map<String, dynamic>;
    final isCreate = change.baseVersion == 0 && change.tempId != null;

    if (isCreate) {
      // Idempotency check
      if (change.clientMutationId != null) {
        final existing = await Note.db.findFirstRow(
          session,
          where: (n) => n.clientMutationId.equals(change.clientMutationId!),
        );
        if (existing != null) {
          return SyncResult(
            status: 'already_applied',
            tempId: change.tempId,
            serverId: existing.id,
            entityType: 'note',
            entityJson: jsonEncode(existing.toJson()),
          );
        }
      }

      final content = (entityMap['content'] as String?)?.trim() ?? '';
      if (content.isEmpty) {
        return SyncResult(
          status: 'rejected',
          reason: 'Note content cannot be empty',
          entityType: 'note',
          tempId: change.tempId,
        );
      }
      if (content.length > 200000) {
        return SyncResult(
          status: 'rejected',
          reason: 'Note content too long (max 200,000 characters)',
          entityType: 'note',
          tempId: change.tempId,
        );
      }

      final channelId = entityMap['channelId'] as int?;
      if (channelId == null) {
        return SyncResult(
          status: 'rejected',
          reason: 'Missing channelId',
          entityType: 'note',
          tempId: change.tempId,
        );
      }

      final saved = await session.db.transaction((tx) async {
        final newVersion = await incrementGlobalVersion(
          session,
          transaction: tx,
        );
        final note = Note(
          channelId: channelId,
          content: content,
          clientMutationId: change.clientMutationId,
          version: newVersion,
        );
        final savedNote = await Note.db.insertRow(
          session,
          note,
          transaction: tx,
        );

        // Update channel updatedAt + version
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
        ChatEvent(type: 'noteCreated', note: saved),
      );

      return SyncResult(
        status: 'applied',
        tempId: change.tempId,
        serverId: saved.id,
        entityType: 'note',
        entityJson: jsonEncode(saved.toJson()),
      );
    }

    // Update or delete
    final serverId = _extractId(change.entityJson);
    if (serverId == null) {
      return SyncResult(
        status: 'rejected',
        reason: 'Missing server ID for update/delete',
        entityType: 'note',
        tempId: change.tempId,
      );
    }

    final note = await Note.db.findById(session, serverId);
    if (note == null) {
      return SyncResult(
        status: 'rejected',
        reason: 'Note not found',
        entityType: 'note',
      );
    }

    // Version check
    if (note.version != change.baseVersion) {
      return SyncResult(
        status: 'rejected',
        reason:
            'Version mismatch (server: ${note.version}, client: ${change.baseVersion})',
        entityType: 'note',
        entityJson: jsonEncode(note.toJson()),
      );
    }

    if (change.deleted) {
      // Tombstone permanent delete
      final now = DateTime.now();
      note.deletedAt = now;
      note.updatedAt = now;

      await session.db.transaction((tx) async {
        final newVersion = await incrementGlobalVersion(
          session,
          transaction: tx,
        );
        note.version = newVersion;
        await Note.db.updateRow(session, note, transaction: tx);
      });

      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(
          type: 'noteDeleted',
          noteId: serverId,
          channelId: note.channelId,
        ),
      );

      return SyncResult(
        status: 'applied',
        entityType: 'note',
        entityJson: jsonEncode(note.toJson()),
      );
    }

    // Regular update
    final content = (entityMap['content'] as String?)?.trim();
    if (content != null) {
      if (content.isEmpty) {
        return SyncResult(
          status: 'rejected',
          reason: 'Note content cannot be empty',
          entityType: 'note',
          entityJson: jsonEncode(note.toJson()),
        );
      }
      if (content.length > 200000) {
        return SyncResult(
          status: 'rejected',
          reason: 'Note content too long',
          entityType: 'note',
          entityJson: jsonEncode(note.toJson()),
        );
      }
      note.content = content;
    }
    if (entityMap.containsKey('archived')) {
      note.archived = entityMap['archived'] as bool? ?? note.archived;
      if (note.archived) {
        note.archivedAt =
            DateTime.tryParse(
              entityMap['archivedAt'] as String? ?? '',
            ) ??
            DateTime.now();
      } else {
        note.archivedAt = null;
      }
    }
    note.updatedAt = DateTime.now();

    final updated = await session.db.transaction((tx) async {
      final newVersion = await incrementGlobalVersion(session, transaction: tx);
      note.version = newVersion;
      return Note.db.updateRow(session, note, transaction: tx);
    });

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(type: 'noteUpdated', note: updated),
    );

    return SyncResult(
      status: 'applied',
      entityType: 'note',
      entityJson: jsonEncode(updated.toJson()),
    );
  }

  int? _extractId(String entityJson) {
    try {
      final map = jsonDecode(entityJson) as Map<String, dynamic>;
      final id = map['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      return null;
    } catch (_) {
      return null;
    }
  }
}
