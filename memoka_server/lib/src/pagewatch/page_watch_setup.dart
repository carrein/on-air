import 'package:serverpod/serverpod.dart';

/// Ensures the page_watches table exists in the database.
/// Called once on server startup. Idempotent — safe to run repeatedly.
///
/// Like note_search, this is an untracked table (no .spy.yaml with table:)
/// to avoid Serverpod's schema validator issues.
class PageWatchSetup {
  static Future<void> ensurePageWatchTable(Session session) async {
    final check = await session.db.unsafeQuery(
      "SELECT 1 FROM information_schema.tables "
      "WHERE table_name = 'page_watches'",
    );
    if (check.isNotEmpty) {
      // Table exists — ensure newer columns are present
      await _addColumnIfMissing(session, 'etag', 'text');
      await _addColumnIfMissing(session, 'lastModified', 'text');
      return;
    }

    session.log('Setting up page_watches table...');

    await session.db.unsafeQuery('''
      CREATE TABLE IF NOT EXISTS "page_watches" (
        "id" bigserial PRIMARY KEY,
        "noteId" bigint NOT NULL REFERENCES "notes"("id") ON DELETE CASCADE,
        "channelId" bigint NOT NULL REFERENCES "channels"("id") ON DELETE CASCADE,
        "url" text NOT NULL,
        "contentHash" text,
        "lastCheckedAt" timestamptz,
        "enabled" boolean NOT NULL DEFAULT true,
        "consecutiveFailures" int NOT NULL DEFAULT 0,
        "lastError" text,
        "hasUnacknowledgedChange" boolean NOT NULL DEFAULT false,
        "etag" text,
        "lastModified" text,
        "createdAt" timestamptz NOT NULL DEFAULT now(),
        "updatedAt" timestamptz NOT NULL DEFAULT now(),
        CONSTRAINT "page_watches_note_unique" UNIQUE ("noteId")
      )
    ''');

    await session.db.unsafeQuery('''
      CREATE INDEX IF NOT EXISTS "page_watches_enabled_idx"
        ON "page_watches" ("enabled") WHERE "enabled" = true
    ''');

    session.log('page_watches table created successfully.');
  }

  static Future<void> _addColumnIfMissing(
    Session session,
    String column,
    String type,
  ) async {
    final exists = await session.db.unsafeQuery(
      "SELECT 1 FROM information_schema.columns "
      "WHERE table_name = 'page_watches' AND column_name = '$column'",
    );
    if (exists.isEmpty) {
      await session.db.unsafeQuery(
        'ALTER TABLE "page_watches" ADD COLUMN "$column" $type',
      );
      session.log('Added column "$column" to page_watches');
    }
  }
}
