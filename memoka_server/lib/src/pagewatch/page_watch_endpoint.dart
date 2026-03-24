import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';

/// Endpoint for managing page watches on notes.
class PageWatchEndpoint extends Endpoint {
  /// URL regex — uses the shared pattern from ServerConstants.
  static final _urlPattern = ServerConstants.urlPattern;

  /// Creates a page watch for a note. The note must contain exactly one URL.
  Future<PageWatch> createWatch(Session session, int noteId) async {
    // Validate note exists
    final noteRows = await session.db.unsafeQuery(
      'SELECT "id", "channelId", "content" FROM "notes" '
      'WHERE "id" = $noteId AND "deletedAt" IS NULL AND "archived" = false',
    );
    if (noteRows.isEmpty) {
      throw Exception('Note not found');
    }

    final cols = noteRows.first.toColumnMap();
    final channelId = cols['channelId'] as int;
    final content = cols['content'] as String;

    // Extract URLs
    final urls = _urlPattern
        .allMatches(content)
        .map((m) => m.group(0)!)
        .toList();
    if (urls.isEmpty) {
      throw Exception('Note does not contain a URL');
    }
    if (urls.length > 1) {
      throw Exception(
        'Note contains multiple URLs — only single-URL notes can be watched',
      );
    }

    final url = urls.first;

    // Upsert — re-enable if exists but was disabled
    final existing = await session.db.unsafeQuery(
      'SELECT "id" FROM "page_watches" WHERE "noteId" = $noteId',
    );

    final now = DateTime.now().toIso8601String();

    if (existing.isNotEmpty) {
      // Re-enable existing watch
      await session.db.unsafeQuery(
        'UPDATE "page_watches" SET '
        '"enabled" = true, '
        '"consecutiveFailures" = 0, '
        '"lastError" = NULL, '
        '"hasUnacknowledgedChange" = false, '
        '"url" = \'${ServerConstants.escapeSql(url)}\', '
        '"updatedAt" = \'$now\' '
        'WHERE "noteId" = $noteId',
      );
    } else {
      await session.db.unsafeQuery(
        'INSERT INTO "page_watches" '
        '("noteId", "channelId", "url", "createdAt", "updatedAt") '
        'VALUES ($noteId, $channelId, \'${ServerConstants.escapeSql(url)}\', \'$now\', \'$now\')',
      );
    }

    return _getWatchByNoteId(session, noteId);
  }

  /// Deletes a page watch for a note.
  Future<void> deleteWatch(Session session, int noteId) async {
    await session.db.unsafeQuery(
      'DELETE FROM "page_watches" WHERE "noteId" = $noteId',
    );
  }

  /// Returns the page watch for a note, or null if not watching.
  Future<PageWatch?> getWatch(Session session, int noteId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "page_watches" WHERE "noteId" = $noteId',
    );
    if (rows.isEmpty) return null;
    return _rowToPageWatch(rows.first.toColumnMap());
  }

  /// Returns all page watches for a channel.
  Future<List<PageWatch>> getWatches(Session session, int channelId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "page_watches" WHERE "channelId" = $channelId',
    );
    return rows.map((r) => _rowToPageWatch(r.toColumnMap())).toList();
  }

  /// Acknowledges a content change (clears the pink dot).
  Future<void> acknowledgeChange(Session session, int noteId) async {
    final now = DateTime.now().toIso8601String();
    await session.db.unsafeQuery(
      'UPDATE "page_watches" SET '
      '"hasUnacknowledgedChange" = false, '
      '"updatedAt" = \'$now\' '
      'WHERE "noteId" = $noteId',
    );
  }

  // -- Helpers --

  Future<PageWatch> _getWatchByNoteId(Session session, int noteId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "page_watches" WHERE "noteId" = $noteId',
    );
    return _rowToPageWatch(rows.first.toColumnMap());
  }

  static PageWatch _rowToPageWatch(Map<String, dynamic> cols) {
    return PageWatch(
      noteId: cols['noteId'] as int? ?? 0,
      channelId: cols['channelId'] as int? ?? 0,
      url: cols['url'] as String? ?? '',
      contentHash: cols['contentHash'] as String?,
      lastCheckedAt: cols['lastCheckedAt'] as DateTime?,
      enabled: cols['enabled'] as bool? ?? true,
      consecutiveFailures: cols['consecutiveFailures'] as int? ?? 0,
      lastError: cols['lastError'] as String?,
      hasUnacknowledgedChange:
          cols['hasUnacknowledgedChange'] as bool? ?? false,
      createdAt: cols['createdAt'] as DateTime? ?? DateTime.now(),
      updatedAt: cols['updatedAt'] as DateTime? ?? DateTime.now(),
    );
  }
}
