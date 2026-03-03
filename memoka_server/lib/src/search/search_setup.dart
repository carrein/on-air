import 'package:serverpod/serverpod.dart';

/// Ensures the full-text search infrastructure exists in the database.
/// Called once on server startup. Idempotent — safe to run repeatedly.
///
/// Search infra lives in a separate `note_search` table that is NOT tracked
/// by Serverpod's schema validator (no `.spy.yaml`). This avoids the fatal
/// schema mismatch that occurs when `tsvector` columns or GIN indexes exist
/// on tracked tables.
class SearchSetup {
  static Future<void> ensureSearchInfrastructure(Session session) async {
    // Check if the note_search table already exists.
    final check = await session.db.unsafeQuery(
      "SELECT 1 FROM information_schema.tables "
      "WHERE table_name = 'note_search'",
    );
    if (check.isNotEmpty) return; // Already set up

    session.log('Setting up search infrastructure...');

    // Enable trigram extension (for similarity() in search queries).
    await session.db.unsafeQuery(
      'CREATE EXTENSION IF NOT EXISTS pg_trgm',
    );

    // Create untracked search table.
    await session.db.unsafeQuery('''
      CREATE TABLE note_search (
        note_id bigint PRIMARY KEY REFERENCES notes(id) ON DELETE CASCADE,
        search_vector tsvector
      )
    ''');

    // GIN index for FTS.
    await session.db.unsafeQuery(
      'CREATE INDEX note_search_vector_idx '
      'ON note_search USING GIN (search_vector)',
    );

    // Populate for existing notes.
    await session.db.unsafeQuery('''
      INSERT INTO note_search (note_id, search_vector)
      SELECT id, to_tsvector('simple', COALESCE(content, ''))
      FROM notes
      ON CONFLICT (note_id) DO UPDATE
        SET search_vector = EXCLUDED.search_vector
    ''');

    // Trigger to auto-update note_search on notes insert/update.
    await session.db.unsafeQuery(r'''
      CREATE OR REPLACE FUNCTION notes_search_update() RETURNS trigger AS $$
      BEGIN
        INSERT INTO note_search (note_id, search_vector)
        VALUES (NEW.id, to_tsvector('simple', COALESCE(NEW.content, '')))
        ON CONFLICT (note_id) DO UPDATE
          SET search_vector = EXCLUDED.search_vector;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    ''');

    await session.db.unsafeQuery('''
      DROP TRIGGER IF EXISTS notes_search_trigger ON notes
    ''');

    await session.db.unsafeQuery('''
      CREATE TRIGGER notes_search_trigger
        AFTER INSERT OR UPDATE OF content ON notes
        FOR EACH ROW
        EXECUTE FUNCTION notes_search_update()
    ''');

    session.log('Search infrastructure created successfully.');
  }
}
