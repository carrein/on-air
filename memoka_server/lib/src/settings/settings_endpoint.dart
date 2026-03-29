import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../media/thumbnail_regen_service.dart';

/// Endpoint for reading and updating application settings.
class SettingsEndpoint extends Endpoint {
  /// Returns the current application settings.
  Future<AppSettings> getSettings(Session session) async {
    final result = await session.db.unsafeQuery(
      'SELECT "archiveRetentionDays" FROM "app_settings" WHERE "id" = 1',
    );
    final row = result.first.toColumnMap();
    return AppSettings(
      archiveRetentionDays: row['archiveRetentionDays'] as int,
    );
  }

  /// Updates application settings.
  Future<AppSettings> updateSettings(
    Session session,
    AppSettings settings,
  ) async {
    await session.db.unsafeQuery(
      'UPDATE "app_settings" SET "archiveRetentionDays" = ${settings.archiveRetentionDays} WHERE "id" = 1',
    );
    return settings;
  }

  /// Starts a background thumbnail regeneration job and returns the total
  /// number of attachments that will be processed.
  ///
  /// Returns immediately — progress is tracked server-side and readable via
  /// [getRegenProgress]. If a job is already running, returns its total count
  /// without starting a second job.
  Future<int> startThumbnailRegen(Session session) async {
    return ThumbnailRegenService.startBackground(session);
  }

  /// Returns the current state of the thumbnail regeneration job.
  Future<ThumbnailRegenProgress> getRegenProgress(Session session) async {
    return ThumbnailRegenProgress(
      total: ThumbnailRegenJob.total,
      processed: ThumbnailRegenJob.processed,
      failed: ThumbnailRegenJob.failed,
      isRunning: ThumbnailRegenJob.isRunning,
    );
  }
}
