import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/note_query.dart';

/// Endpoint for full-text and trigram search across notes.
class SearchEndpoint extends Endpoint {
  /// Escapes a string for safe use in a SQL single-quoted literal.
  /// Doubles single quotes and escapes backslashes.
  static String _escapeSql(String input) {
    return input.replaceAll(r'\', r'\\').replaceAll("'", "''");
  }

  /// Searches notes using hybrid FTS + trigram matching.
  ///
  /// Returns a ranked list of [SearchResult] with highlighted snippets.
  /// The query is truncated to 200 characters server-side.
  Future<List<SearchResult>> searchNotes(
    Session session,
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Truncate to 200 chars and escape for SQL
    final truncated = trimmed.length > 200
        ? trimmed.substring(0, 200)
        : trimmed;
    final safeQuery = _escapeSql(truncated);

    final sql =
        '''
      WITH fts AS (
        SELECT n.id, ts_rank(ns.search_vector, plainto_tsquery('simple', '$safeQuery')) AS rank
        FROM notes n
        JOIN note_search ns ON ns.note_id = n.id
        JOIN channels c ON c.id = n."channelId"
        WHERE ns.search_vector @@ plainto_tsquery('simple', '$safeQuery')
          AND n.archived = false AND n."deletedAt" IS NULL
          AND c.archived = false AND c."deletedAt" IS NULL
      ),
      trgm AS (
        SELECT n.id, similarity(n.content, '$safeQuery') AS sim
        FROM notes n
        JOIN channels c ON c.id = n."channelId"
        WHERE similarity(n.content, '$safeQuery') > 0.1
          AND n.archived = false AND n."deletedAt" IS NULL
          AND c.archived = false AND c."deletedAt" IS NULL
      )
      SELECT DISTINCT
        n.id AS "noteId",
        n."channelId",
        c.name AS "channelName",
        c.emoji AS "channelEmoji",
        ts_headline('simple', n.content, plainto_tsquery('simple', '$safeQuery'),
          'MaxWords=35,MinWords=15,MaxFragments=1,StartSel=<b>,StopSel=</b>') AS snippet,
        n."createdAt",
        COALESCE(fts.rank * 0.7, 0) + COALESCE(trgm.sim * 0.3, 0) AS score
      FROM notes n
      JOIN channels c ON c.id = n."channelId"
      LEFT JOIN fts ON fts.id = n.id
      LEFT JOIN trgm ON trgm.id = n.id
      WHERE (fts.id IS NOT NULL OR trgm.id IS NOT NULL)
        AND n.archived = false AND n."deletedAt" IS NULL
        AND c.archived = false AND c."deletedAt" IS NULL
      ORDER BY score DESC
      LIMIT $limit
    ''';

    final result = await session.db.unsafeQuery(sql);

    final results = <SearchResult>[];
    for (final row in result) {
      final cols = row.toColumnMap();
      results.add(
        SearchResult(
          noteId: cols['noteId'] as int,
          channelId: cols['channelId'] as int,
          channelName: cols['channelName'] as String,
          channelEmoji: cols['channelEmoji'] as String,
          snippet: cols['snippet'] as String,
          createdAt: cols['createdAt'] as DateTime,
          score: (cols['score'] as num).toDouble(),
        ),
      );
    }

    return results;
  }

  /// Loads notes centered around a specific note ID within a channel.
  ///
  /// Returns approximately [limit] notes: half before and half after
  /// the target note (by createdAt), including the target itself.
  /// Used to jump to a search result in context.
  Future<List<Note>> getNotesAroundId(
    Session session,
    int channelId,
    int noteId, {
    int limit = 25,
  }) async {
    final half = limit ~/ 2;

    // Get notes older than or equal to target (includes target)
    final older = await NoteQuery.findWithAttachments(
      session,
      whereClause:
          'n."channelId" = $channelId AND n.archived = false AND n."deletedAt" IS NULL '
          'AND n."createdAt" <= (SELECT "createdAt" FROM notes WHERE id = $noteId)',
      orderBy: 'n."createdAt" DESC',
      limit: half + 1,
    );

    // Get notes newer than target
    final newer = await NoteQuery.findWithAttachments(
      session,
      whereClause:
          'n."channelId" = $channelId AND n.archived = false AND n."deletedAt" IS NULL '
          'AND n."createdAt" > (SELECT "createdAt" FROM notes WHERE id = $noteId)',
      orderBy: 'n."createdAt" ASC',
      limit: half,
    );

    // Combine and sort by createdAt DESC (newest first)
    final all = [...newer.reversed, ...older];

    // Deduplicate by id
    final seen = <int>{};
    final deduped = all.where((n) => seen.add(n.id!)).toList();
    deduped.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return deduped;
  }
}
