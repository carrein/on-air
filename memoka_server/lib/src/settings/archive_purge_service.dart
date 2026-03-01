import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/purge_helper.dart';

/// Reads the archive retention setting and purges expired archived items.
/// Called on startup and every hour via Timer.periodic.
class ArchivePurgeService {
  static bool _purgeInProgress = false;

  /// Runs a single purge cycle. Safe to call concurrently — re-entrant calls
  /// are silently skipped via the [_purgeInProgress] guard.
  static Future<void> runPurge(Serverpod pod) async {
    if (_purgeInProgress) return;
    _purgeInProgress = true;

    final session = await pod.createSession();
    try {
      // 1. Read retention setting
      final result = await session.db.unsafeQuery(
        'SELECT "archiveRetentionDays" FROM "app_settings" WHERE "id" = 1',
      );
      final retentionDays =
          result.first.toColumnMap()['archiveRetentionDays'] as int;

      if (retentionDays <= 0) return; // Never purge

      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      final cutoffIso = cutoff.toIso8601String();

      // 2. Purge expired notes first
      final expiredNotes = await session.db.unsafeQuery(
        'SELECT "id" FROM "notes" '
        'WHERE "archived" = true AND "deletedAt" IS NULL '
        'AND "archivedAt" < \'$cutoffIso\' '
        'ORDER BY "archivedAt" ASC',
      );

      for (final row in expiredNotes) {
        final noteId = row.toColumnMap()['id'] as int;
        try {
          final note = await Note.db.findById(session, noteId);
          if (note != null) {
            await PurgeHelper.tombstoneNote(session, note);
            session.log('Auto-purged expired note $noteId');
          }
        } catch (e) {
          session.log(
            'Failed to auto-purge note $noteId: $e',
            level: LogLevel.error,
          );
        }
      }

      // 3. Purge expired channels
      final expiredChannels = await session.db.unsafeQuery(
        'SELECT "id" FROM "channels" '
        'WHERE "archived" = true AND "deletedAt" IS NULL '
        'AND "archivedAt" < \'$cutoffIso\' '
        'ORDER BY "archivedAt" ASC',
      );

      for (final row in expiredChannels) {
        final channelId = row.toColumnMap()['id'] as int;
        try {
          await PurgeHelper.tombstoneChannel(
            session,
            channelId,
            skipLastChannelCheck: true,
          );
          session.log('Auto-purged expired channel $channelId');
        } catch (e) {
          session.log(
            'Failed to auto-purge channel $channelId: $e',
            level: LogLevel.error,
          );
        }
      }

      final totalPurged = expiredNotes.length + expiredChannels.length;
      if (totalPurged > 0) {
        session.log(
          'Archive purge complete: ${expiredNotes.length} notes, '
          '${expiredChannels.length} channels purged '
          '(retention: $retentionDays days)',
        );
      }
    } catch (e, stackTrace) {
      session.log(
        'Archive purge failed: $e\n$stackTrace',
        level: LogLevel.error,
      );
    } finally {
      await session.close();
      _purgeInProgress = false;
    }
  }
}
