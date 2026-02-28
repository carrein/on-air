import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Shared query helper for loading notes with their media attachments
/// via a single LEFT JOIN (avoids N+1 queries).
class NoteQuery {
  /// The common SELECT + LEFT JOIN fragment for notes with attachments.
  static const _selectWithAttachments = '''
    SELECT
      n.*,
      COALESCE(
        json_agg(
          json_build_object(
            'id', ma.id,
            'noteId', ma."noteId",
            'channelId', ma."channelId",
            'filePath', ma."filePath",
            'originalFilename', ma."originalFilename",
            'mimeType', ma."mimeType",
            'fileSize', ma."fileSize",
            'width', ma.width,
            'height', ma.height,
            'thumbnailPath', ma."thumbnailPath",
            'compressed', ma.compressed,
            'animated', ma.animated,
            'contentHash', ma."contentHash",
            'uploadedAt', ma."uploadedAt"
          ) ORDER BY ma.id
        ) FILTER (WHERE ma.id IS NOT NULL),
        '[]'::json
      ) as attachments_json
    FROM notes n
    LEFT JOIN media_attachments ma ON ma."noteId" = n.id
  ''';

  /// Loads notes matching [whereClause] with their attachments.
  ///
  /// The WHERE clause should reference columns via the `n.` alias.
  /// Optional [orderBy] defaults to `n."createdAt" DESC`.
  /// Optional [limit] appends a LIMIT clause.
  static Future<List<Note>> findWithAttachments(
    Session session, {
    required String whereClause,
    String orderBy = 'n."createdAt" DESC',
    int? limit,
  }) async {
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final result = await session.db.unsafeQuery('''
      $_selectWithAttachments
      WHERE $whereClause
      GROUP BY n.id
      ORDER BY $orderBy
      $limitClause
    ''');

    return _parseRows(result);
  }

  /// Parses raw query rows into Note objects with attachments.
  static List<Note> _parseRows(DatabaseResult result) {
    final notes = <Note>[];
    for (final row in result) {
      final note = Note.fromJson(row.toColumnMap());
      final attachmentsJson = row.toColumnMap()['attachments_json'];
      if (attachmentsJson != null && attachmentsJson != '[]') {
        final attachmentsList = attachmentsJson as List;
        note.attachments = attachmentsList
            .map(
              (json) => MediaAttachment.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      notes.add(note);
    }
    return notes;
  }
}
