import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

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
}
