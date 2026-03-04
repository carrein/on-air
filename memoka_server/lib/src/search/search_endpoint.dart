import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/note_query.dart';

/// Endpoint for full-text and fuzzy subsequence search across notes.
class SearchEndpoint extends Endpoint {
  /// Escapes a string for safe use in a SQL single-quoted literal.
  static String _escapeSql(String input) {
    return input.replaceAll(r'\', r'\\').replaceAll("'", "''");
  }

  /// Keeps only alphanumeric characters for safe tsquery usage.
  static String _sanitizeFtsWord(String word) {
    return word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  static final _regexSpecial = RegExp(r'[.*+?^${}()|[\]\\]');

  /// Builds an unanchored subsequence regex: "Qck" -> "Q.*c.*k".
  static String _buildSubseqPattern(String word) {
    final escaped = word
        .split('')
        .map((c) {
          return _regexSpecial.hasMatch(c) ? '\\$c' : c;
        })
        .join('.*');
    return escaped;
  }

  /// Searches notes using hybrid FTS prefix + unanchored subsequence matching.
  ///
  /// FTS prefix handles exact prefix matches (fast, GIN-indexed).
  /// Subsequence handles fuzzy matches like "Qck" -> "Quick" or "ick" -> "Quick"
  /// by checking if query chars appear in order within any content word.
  /// Content is split on non-alphanumeric boundaries so punctuation and markdown
  /// syntax act as word separators. Multi-word queries use OR logic.
  /// Results ranked by score DESC, then recency DESC as tiebreaker.
  Future<List<SearchResult>> searchNotes(
    Session session,
    String query, {
    int? channelId,
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final truncated = trimmed.length > 200
        ? trimmed.substring(0, 200)
        : trimmed;
    final words = truncated
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return [];

    // FTS prefix: word1:* | word2:*
    final ftsTerms = words
        .map(_sanitizeFtsWord)
        .where((w) => w.isNotEmpty)
        .map((w) => '${_escapeSql(w)}:*')
        .toList();
    final hasFts = ftsTerms.isNotEmpty;
    final ftsExpr = ftsTerms.join(' | ');

    // Anchored subsequence: each query word checked against individual
    // content words via case-insensitive regex.
    final subseqClauses = words
        .map((w) {
          final pattern = _buildSubseqPattern(w);
          return "cw ~* '${_escapeSql(pattern)}'";
        })
        .join(' OR ');

    final ftsFilter = hasFts
        ? "ns.search_vector @@ to_tsquery('simple', '$ftsExpr')"
        : 'FALSE';
    final ftsRank = hasFts
        ? "ts_rank(ns.search_vector, to_tsquery('simple', '$ftsExpr'))"
        : '0';
    final snippetExpr = hasFts
        ? "ts_headline('simple', n.content, to_tsquery('simple', '$ftsExpr'), "
              "'MaxWords=35,MinWords=15,MaxFragments=1,StartSel=<b>,StopSel=</b>')"
        : "substring(n.content FROM 1 FOR 100)";

    final sql =
        '''
      WITH fts AS (
        SELECT n.id, $ftsRank AS rank
        FROM notes n
        JOIN note_search ns ON ns.note_id = n.id
        JOIN channels c ON c.id = n."channelId"
        WHERE $ftsFilter
          AND n.archived = false AND n."deletedAt" IS NULL
          AND c.archived = false AND c."deletedAt" IS NULL
      ),
      subseq AS (
        SELECT n.id
        FROM notes n
        JOIN channels c ON c.id = n."channelId"
        WHERE EXISTS (
          SELECT 1 FROM regexp_split_to_table(n.content, '[^a-zA-Z0-9]+') AS cw
          WHERE length(cw) > 0 AND ($subseqClauses)
        )
          AND n.archived = false AND n."deletedAt" IS NULL
          AND c.archived = false AND c."deletedAt" IS NULL
      )
      SELECT DISTINCT
        n.id AS "noteId",
        n."channelId",
        c.name AS "channelName",
        c.emoji AS "channelEmoji",
        $snippetExpr AS snippet,
        n."createdAt",
        COALESCE(fts.rank, 0) * 0.7
          + CASE WHEN subseq.id IS NOT NULL THEN 0.3 ELSE 0.0 END
          + CASE WHEN n."channelId" = ${channelId ?? -1} THEN 0.15 ELSE 0.0 END AS score
      FROM notes n
      JOIN channels c ON c.id = n."channelId"
      LEFT JOIN fts ON fts.id = n.id
      LEFT JOIN subseq ON subseq.id = n.id
      WHERE (fts.id IS NOT NULL OR subseq.id IS NOT NULL)
        AND n.archived = false AND n."deletedAt" IS NULL
        AND c.archived = false AND c."deletedAt" IS NULL
      ORDER BY score DESC, n."createdAt" DESC
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
