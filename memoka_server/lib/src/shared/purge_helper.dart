import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../sync/version_helper.dart';
import 'constants.dart';

/// Shared tombstone logic used by both ChatEndpoint (user-initiated deletes)
/// and ArchivePurgeService (retention-based auto-purge).
class PurgeHelper {
  /// Tombstones a single note: deletes media files from disk, sets deletedAt,
  /// increments globalVersion, and broadcasts noteDeleted.
  static Future<void> tombstoneNote(Session session, Note note) async {
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

  /// Tombstones a channel: deletes media directory, tombstones all notes,
  /// tombstones channel row, increments globalVersion, and broadcasts channelDeleted.
  /// Set [skipLastChannelCheck] to true when called from auto-purge (already archived).
  static Future<void> tombstoneChannel(
    Session session,
    int channelId, {
    bool skipLastChannelCheck = false,
  }) async {
    final channel = await Channel.db.findById(session, channelId);

    if (!skipLastChannelCheck) {
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
    }

    // Delete media files for this channel
    final mediaDir = Directory(
      '${ServerConstants.mediaBaseDir}/channels/$channelId',
    );
    if (await mediaDir.exists()) {
      await mediaDir.delete(recursive: true);
      session.log('Deleted media directory for channel $channelId');
    }

    // Tombstone: set deletedAt on channel + all its notes
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
        'UPDATE "notes" SET "deletedAt" = \'${now.toIso8601String()}\', "version" = $newVersion WHERE "channelId" = $channelId',
        transaction: tx,
      );
    });

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'channelDeleted',
        channelId: channelId,
      ),
    );
  }
}
