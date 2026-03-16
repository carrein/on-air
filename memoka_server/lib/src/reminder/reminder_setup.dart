import 'package:serverpod/serverpod.dart';

/// Ensures the reminders table exists in the database.
/// Called once on server startup. Idempotent — safe to run repeatedly.
///
/// Like note_search and page_watches, this is an untracked table (no .spy.yaml
/// with table:) to avoid Serverpod's schema validator issues.
class ReminderSetup {
  static Future<void> ensureReminderTable(Session session) async {
    final check = await session.db.unsafeQuery(
      "SELECT 1 FROM information_schema.tables "
      "WHERE table_name = 'reminders'",
    );
    if (check.isNotEmpty) {
      // Table exists — ensure newer columns are present
      await _addColumnIfMissing(session, 'recurrenceRule', 'text');
      await _addColumnIfMissing(session, 'recurrenceEndAt', 'timestamptz');
      return;
    }

    session.log('Setting up reminders table...');

    await session.db.unsafeQuery('''
      CREATE TABLE IF NOT EXISTS "reminders" (
        "id" bigserial PRIMARY KEY,
        "noteId" bigint NOT NULL REFERENCES "notes"("id") ON DELETE CASCADE,
        "channelId" bigint NOT NULL REFERENCES "channels"("id") ON DELETE CASCADE,
        "scheduledAt" timestamptz NOT NULL,
        "noteContent" text,
        "fired" boolean NOT NULL DEFAULT false,
        "createdAt" timestamptz NOT NULL DEFAULT now(),
        "recurrenceRule" text,
        "recurrenceEndAt" timestamptz,
        CONSTRAINT "reminders_note_unique" UNIQUE ("noteId")
      )
    ''');

    await session.db.unsafeQuery('''
      CREATE INDEX IF NOT EXISTS "reminders_scheduled_idx"
        ON "reminders" ("scheduledAt") WHERE "fired" = false
    ''');

    await session.db.unsafeQuery('''
      CREATE INDEX IF NOT EXISTS "reminders_fired_idx"
        ON "reminders" ("fired") WHERE "fired" = true
    ''');

    session.log('reminders table created successfully.');
  }

  static Future<void> _addColumnIfMissing(
    Session session,
    String column,
    String type,
  ) async {
    final exists = await session.db.unsafeQuery(
      "SELECT 1 FROM information_schema.columns "
      "WHERE table_name = 'reminders' AND column_name = '$column'",
    );
    if (exists.isEmpty) {
      await session.db.unsafeQuery(
        'ALTER TABLE "reminders" ADD COLUMN "$column" $type',
      );
      session.log('Added column "$column" to reminders');
    }
  }
}
