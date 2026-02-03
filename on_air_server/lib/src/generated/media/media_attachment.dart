/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

/// A media attachment (image) associated with a note.
abstract class MediaAttachment
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  MediaAttachment._({
    this.id,
    required this.noteId,
    required this.channelId,
    required this.filePath,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    this.width,
    this.height,
    this.duration,
    this.thumbnailPath,
    bool? compressed,
    bool? animated,
    this.contentHash,
    DateTime? uploadedAt,
  }) : compressed = compressed ?? false,
       animated = animated ?? false,
       uploadedAt = uploadedAt ?? DateTime.now();

  factory MediaAttachment({
    int? id,
    required int noteId,
    required int channelId,
    required String filePath,
    required String originalFilename,
    required String mimeType,
    required int fileSize,
    int? width,
    int? height,
    double? duration,
    String? thumbnailPath,
    bool? compressed,
    bool? animated,
    String? contentHash,
    DateTime? uploadedAt,
  }) = _MediaAttachmentImpl;

  factory MediaAttachment.fromJson(Map<String, dynamic> jsonSerialization) {
    return MediaAttachment(
      id: jsonSerialization['id'] as int?,
      noteId: jsonSerialization['noteId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      filePath: jsonSerialization['filePath'] as String,
      originalFilename: jsonSerialization['originalFilename'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      fileSize: jsonSerialization['fileSize'] as int,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
      duration: (jsonSerialization['duration'] as num?)?.toDouble(),
      thumbnailPath: jsonSerialization['thumbnailPath'] as String?,
      compressed: jsonSerialization['compressed'] as bool?,
      animated: jsonSerialization['animated'] as bool?,
      contentHash: jsonSerialization['contentHash'] as String?,
      uploadedAt: jsonSerialization['uploadedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['uploadedAt']),
    );
  }

  static final t = MediaAttachmentTable();

  static const db = MediaAttachmentRepository._();

  @override
  int? id;

  /// The ID of the note this attachment belongs to.
  int noteId;

  /// The ID of the channel this attachment belongs to (for efficient querying).
  int channelId;

  /// The file path (UUID-based filename with extension).
  String filePath;

  /// The original filename provided by the user.
  String originalFilename;

  /// The MIME type of the file.
  String mimeType;

  /// The file size in bytes.
  int fileSize;

  /// The width of the image in pixels.
  int? width;

  /// The height of the image in pixels.
  int? height;

  /// The duration of the video in seconds.
  double? duration;

  /// The path to the thumbnail image.
  String? thumbnailPath;

  /// Whether the image was compressed.
  bool compressed;

  /// Whether the image is animated (GIF).
  bool animated;

  /// Content hash (first 8 chars of SHA-256) for cache busting.
  String? contentHash;

  /// When the attachment was uploaded.
  DateTime uploadedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [MediaAttachment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MediaAttachment copyWith({
    int? id,
    int? noteId,
    int? channelId,
    String? filePath,
    String? originalFilename,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    double? duration,
    String? thumbnailPath,
    bool? compressed,
    bool? animated,
    String? contentHash,
    DateTime? uploadedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MediaAttachment',
      if (id != null) 'id': id,
      'noteId': noteId,
      'channelId': channelId,
      'filePath': filePath,
      'originalFilename': originalFilename,
      'mimeType': mimeType,
      'fileSize': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      'compressed': compressed,
      'animated': animated,
      if (contentHash != null) 'contentHash': contentHash,
      'uploadedAt': uploadedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MediaAttachment',
      if (id != null) 'id': id,
      'noteId': noteId,
      'channelId': channelId,
      'filePath': filePath,
      'originalFilename': originalFilename,
      'mimeType': mimeType,
      'fileSize': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (duration != null) 'duration': duration,
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      'compressed': compressed,
      'animated': animated,
      if (contentHash != null) 'contentHash': contentHash,
      'uploadedAt': uploadedAt.toJson(),
    };
  }

  static MediaAttachmentInclude include() {
    return MediaAttachmentInclude._();
  }

  static MediaAttachmentIncludeList includeList({
    _i1.WhereExpressionBuilder<MediaAttachmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MediaAttachmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MediaAttachmentTable>? orderByList,
    MediaAttachmentInclude? include,
  }) {
    return MediaAttachmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MediaAttachment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(MediaAttachment.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MediaAttachmentImpl extends MediaAttachment {
  _MediaAttachmentImpl({
    int? id,
    required int noteId,
    required int channelId,
    required String filePath,
    required String originalFilename,
    required String mimeType,
    required int fileSize,
    int? width,
    int? height,
    double? duration,
    String? thumbnailPath,
    bool? compressed,
    bool? animated,
    String? contentHash,
    DateTime? uploadedAt,
  }) : super._(
         id: id,
         noteId: noteId,
         channelId: channelId,
         filePath: filePath,
         originalFilename: originalFilename,
         mimeType: mimeType,
         fileSize: fileSize,
         width: width,
         height: height,
         duration: duration,
         thumbnailPath: thumbnailPath,
         compressed: compressed,
         animated: animated,
         contentHash: contentHash,
         uploadedAt: uploadedAt,
       );

  /// Returns a shallow copy of this [MediaAttachment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MediaAttachment copyWith({
    Object? id = _Undefined,
    int? noteId,
    int? channelId,
    String? filePath,
    String? originalFilename,
    String? mimeType,
    int? fileSize,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? duration = _Undefined,
    Object? thumbnailPath = _Undefined,
    bool? compressed,
    bool? animated,
    Object? contentHash = _Undefined,
    DateTime? uploadedAt,
  }) {
    return MediaAttachment(
      id: id is int? ? id : this.id,
      noteId: noteId ?? this.noteId,
      channelId: channelId ?? this.channelId,
      filePath: filePath ?? this.filePath,
      originalFilename: originalFilename ?? this.originalFilename,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
      duration: duration is double? ? duration : this.duration,
      thumbnailPath: thumbnailPath is String?
          ? thumbnailPath
          : this.thumbnailPath,
      compressed: compressed ?? this.compressed,
      animated: animated ?? this.animated,
      contentHash: contentHash is String? ? contentHash : this.contentHash,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class MediaAttachmentUpdateTable extends _i1.UpdateTable<MediaAttachmentTable> {
  MediaAttachmentUpdateTable(super.table);

  _i1.ColumnValue<int, int> noteId(int value) => _i1.ColumnValue(
    table.noteId,
    value,
  );

  _i1.ColumnValue<int, int> channelId(int value) => _i1.ColumnValue(
    table.channelId,
    value,
  );

  _i1.ColumnValue<String, String> filePath(String value) => _i1.ColumnValue(
    table.filePath,
    value,
  );

  _i1.ColumnValue<String, String> originalFilename(String value) =>
      _i1.ColumnValue(
        table.originalFilename,
        value,
      );

  _i1.ColumnValue<String, String> mimeType(String value) => _i1.ColumnValue(
    table.mimeType,
    value,
  );

  _i1.ColumnValue<int, int> fileSize(int value) => _i1.ColumnValue(
    table.fileSize,
    value,
  );

  _i1.ColumnValue<int, int> width(int? value) => _i1.ColumnValue(
    table.width,
    value,
  );

  _i1.ColumnValue<int, int> height(int? value) => _i1.ColumnValue(
    table.height,
    value,
  );

  _i1.ColumnValue<double, double> duration(double? value) => _i1.ColumnValue(
    table.duration,
    value,
  );

  _i1.ColumnValue<String, String> thumbnailPath(String? value) =>
      _i1.ColumnValue(
        table.thumbnailPath,
        value,
      );

  _i1.ColumnValue<bool, bool> compressed(bool value) => _i1.ColumnValue(
    table.compressed,
    value,
  );

  _i1.ColumnValue<bool, bool> animated(bool value) => _i1.ColumnValue(
    table.animated,
    value,
  );

  _i1.ColumnValue<String, String> contentHash(String? value) => _i1.ColumnValue(
    table.contentHash,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> uploadedAt(DateTime value) =>
      _i1.ColumnValue(
        table.uploadedAt,
        value,
      );
}

class MediaAttachmentTable extends _i1.Table<int?> {
  MediaAttachmentTable({super.tableRelation})
    : super(tableName: 'media_attachments') {
    updateTable = MediaAttachmentUpdateTable(this);
    noteId = _i1.ColumnInt(
      'noteId',
      this,
    );
    channelId = _i1.ColumnInt(
      'channelId',
      this,
    );
    filePath = _i1.ColumnString(
      'filePath',
      this,
    );
    originalFilename = _i1.ColumnString(
      'originalFilename',
      this,
    );
    mimeType = _i1.ColumnString(
      'mimeType',
      this,
    );
    fileSize = _i1.ColumnInt(
      'fileSize',
      this,
    );
    width = _i1.ColumnInt(
      'width',
      this,
    );
    height = _i1.ColumnInt(
      'height',
      this,
    );
    duration = _i1.ColumnDouble(
      'duration',
      this,
    );
    thumbnailPath = _i1.ColumnString(
      'thumbnailPath',
      this,
    );
    compressed = _i1.ColumnBool(
      'compressed',
      this,
      hasDefault: true,
    );
    animated = _i1.ColumnBool(
      'animated',
      this,
      hasDefault: true,
    );
    contentHash = _i1.ColumnString(
      'contentHash',
      this,
    );
    uploadedAt = _i1.ColumnDateTime(
      'uploadedAt',
      this,
      hasDefault: true,
    );
  }

  late final MediaAttachmentUpdateTable updateTable;

  /// The ID of the note this attachment belongs to.
  late final _i1.ColumnInt noteId;

  /// The ID of the channel this attachment belongs to (for efficient querying).
  late final _i1.ColumnInt channelId;

  /// The file path (UUID-based filename with extension).
  late final _i1.ColumnString filePath;

  /// The original filename provided by the user.
  late final _i1.ColumnString originalFilename;

  /// The MIME type of the file.
  late final _i1.ColumnString mimeType;

  /// The file size in bytes.
  late final _i1.ColumnInt fileSize;

  /// The width of the image in pixels.
  late final _i1.ColumnInt width;

  /// The height of the image in pixels.
  late final _i1.ColumnInt height;

  /// The duration of the video in seconds.
  late final _i1.ColumnDouble duration;

  /// The path to the thumbnail image.
  late final _i1.ColumnString thumbnailPath;

  /// Whether the image was compressed.
  late final _i1.ColumnBool compressed;

  /// Whether the image is animated (GIF).
  late final _i1.ColumnBool animated;

  /// Content hash (first 8 chars of SHA-256) for cache busting.
  late final _i1.ColumnString contentHash;

  /// When the attachment was uploaded.
  late final _i1.ColumnDateTime uploadedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    noteId,
    channelId,
    filePath,
    originalFilename,
    mimeType,
    fileSize,
    width,
    height,
    duration,
    thumbnailPath,
    compressed,
    animated,
    contentHash,
    uploadedAt,
  ];
}

class MediaAttachmentInclude extends _i1.IncludeObject {
  MediaAttachmentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => MediaAttachment.t;
}

class MediaAttachmentIncludeList extends _i1.IncludeList {
  MediaAttachmentIncludeList._({
    _i1.WhereExpressionBuilder<MediaAttachmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(MediaAttachment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => MediaAttachment.t;
}

class MediaAttachmentRepository {
  const MediaAttachmentRepository._();

  /// Returns a list of [MediaAttachment]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<MediaAttachment>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MediaAttachmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MediaAttachmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MediaAttachmentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<MediaAttachment>(
      where: where?.call(MediaAttachment.t),
      orderBy: orderBy?.call(MediaAttachment.t),
      orderByList: orderByList?.call(MediaAttachment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [MediaAttachment] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<MediaAttachment?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MediaAttachmentTable>? where,
    int? offset,
    _i1.OrderByBuilder<MediaAttachmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<MediaAttachmentTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<MediaAttachment>(
      where: where?.call(MediaAttachment.t),
      orderBy: orderBy?.call(MediaAttachment.t),
      orderByList: orderByList?.call(MediaAttachment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [MediaAttachment] by its [id] or null if no such row exists.
  Future<MediaAttachment?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<MediaAttachment>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [MediaAttachment]s in the list and returns the inserted rows.
  ///
  /// The returned [MediaAttachment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<MediaAttachment>> insert(
    _i1.Session session,
    List<MediaAttachment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<MediaAttachment>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [MediaAttachment] and returns the inserted row.
  ///
  /// The returned [MediaAttachment] will have its `id` field set.
  Future<MediaAttachment> insertRow(
    _i1.Session session,
    MediaAttachment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<MediaAttachment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [MediaAttachment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<MediaAttachment>> update(
    _i1.Session session,
    List<MediaAttachment> rows, {
    _i1.ColumnSelections<MediaAttachmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<MediaAttachment>(
      rows,
      columns: columns?.call(MediaAttachment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MediaAttachment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<MediaAttachment> updateRow(
    _i1.Session session,
    MediaAttachment row, {
    _i1.ColumnSelections<MediaAttachmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<MediaAttachment>(
      row,
      columns: columns?.call(MediaAttachment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [MediaAttachment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<MediaAttachment?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<MediaAttachmentUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<MediaAttachment>(
      id,
      columnValues: columnValues(MediaAttachment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [MediaAttachment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<MediaAttachment>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<MediaAttachmentUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<MediaAttachmentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<MediaAttachmentTable>? orderBy,
    _i1.OrderByListBuilder<MediaAttachmentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<MediaAttachment>(
      columnValues: columnValues(MediaAttachment.t.updateTable),
      where: where(MediaAttachment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(MediaAttachment.t),
      orderByList: orderByList?.call(MediaAttachment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [MediaAttachment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<MediaAttachment>> delete(
    _i1.Session session,
    List<MediaAttachment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<MediaAttachment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [MediaAttachment].
  Future<MediaAttachment> deleteRow(
    _i1.Session session,
    MediaAttachment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<MediaAttachment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<MediaAttachment>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<MediaAttachmentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<MediaAttachment>(
      where: where(MediaAttachment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<MediaAttachmentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<MediaAttachment>(
      where: where?.call(MediaAttachment.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
