import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/note_query.dart';

/// Endpoint for full-text, substring, and typo-tolerant search across notes.
class SearchEndpoint extends Endpoint {
  /// Escapes a string for safe use in a SQL single-quoted literal.
  static String _escapeSql(String input) {
    return input.replaceAll(r'\', r'\\').replaceAll("'", "''");
  }

  /// Escapes ILIKE wildcard characters (%, _) so they match literally.
  static String _escapeIlike(String input) {
    return input
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  /// Keeps only alphanumeric characters for safe tsquery usage.
  static String _sanitizeFtsWord(String word) {
    return word.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Searches notes using prefix, substring, and typo-tolerant matching.
  ///
  /// Per-term matching strategies (cascading, first match wins):
  /// 1. FTS prefix (score 1.0) — GIN-indexed tsvector prefix match
  /// 2. ILIKE substring (score 0.6) — contiguous match anywhere in content
  /// 3. word_similarity >= 0.3 (score 0.2 + ws*0.2) — typo tolerance, >= 3 chars
  ///
  /// Multi-word queries use AND logic — all terms must match a note.
  /// Final score = avg(per-term scores) + channel boost (0.15).
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

    // Build per-term WHERE fragments (ANDed) and CASE score expressions.
    final whereFragments = <String>[];
    final scoreExprs = <String>[];

    for (final word in words) {
      final escaped = _escapeSql(word);
      final ilikeEscaped = _escapeSql(_escapeIlike(word));
      final ftsWord = _sanitizeFtsWord(word);

      // FTS prefix condition (only if sanitized word is non-empty)
      final ftsCondition = ftsWord.isNotEmpty
          ? "ns.search_vector @@ to_tsquery('simple', '${_escapeSql(ftsWord)}:*')"
          : 'FALSE';

      // ILIKE substring condition
      final ilikeCondition = "n.content ILIKE '%$ilikeEscaped%'";

      // word_similarity condition (only for terms >= 3 chars)
      final wsCondition = word.length >= 3
          ? "word_similarity('$escaped', n.content) >= 0.3"
          : 'FALSE';

      // WHERE: term must match via at least one strategy
      whereFragments.add('($ftsCondition OR $ilikeCondition OR $wsCondition)');

      // CASE scoring: cascading, first match wins
      final scoreParts = <String>[];
      if (ftsWord.isNotEmpty) {
        scoreParts.add('WHEN $ftsCondition THEN 1.0');
      }
      scoreParts.add('WHEN $ilikeCondition THEN 0.6');
      if (word.length >= 3) {
        scoreParts.add(
          "WHEN $wsCondition THEN 0.2 + word_similarity('$escaped', n.content) * 0.2",
        );
      }
      scoreParts.add('ELSE 0.0');
      scoreExprs.add('(CASE ${scoreParts.join(' ')} END)');
    }

    final whereClause = whereFragments.join(' AND ');
    final avgScore = scoreExprs.length == 1
        ? scoreExprs.first
        : '(${scoreExprs.join(' + ')}) / ${scoreExprs.length}';

    // For snippets, use OR-mode tsquery so ts_headline highlights all terms.
    final ftsTerms = words
        .map(_sanitizeFtsWord)
        .where((w) => w.isNotEmpty)
        .map((w) => '${_escapeSql(w)}:*')
        .toList();
    final hasFts = ftsTerms.isNotEmpty;
    final snippetFtsExpr = ftsTerms.join(' | ');
    final snippetExpr = hasFts
        ? "ts_headline('simple', n.content, to_tsquery('simple', '$snippetFtsExpr'), "
              "'MaxWords=35,MinWords=15,MaxFragments=1,StartSel=<b>,StopSel=</b>')"
        : "substring(n.content FROM 1 FOR 100)";

    final sql =
        '''
      SELECT DISTINCT
        n.id AS "noteId",
        n."channelId",
        c.name AS "channelName",
        c.emoji AS "channelEmoji",
        $snippetExpr AS snippet,
        n."createdAt",
        ($avgScore
          + CASE WHEN n."channelId" = ${channelId ?? -1} THEN 0.15 ELSE 0.0 END)::double precision AS score
      FROM notes n
      JOIN channels c ON c.id = n."channelId"
      JOIN note_search ns ON ns.note_id = n.id
      WHERE $whereClause
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
