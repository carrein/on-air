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

/// A channel that contains notes.
abstract class Channel
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Channel._({
    this.id,
    required this.name,
    String? emoji,
    bool? pinned,
    bool? isSystemChannel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? archived,
    this.archivedAt,
  }) : emoji = emoji ?? 'chatCircle',
       pinned = pinned ?? false,
       isSystemChannel = isSystemChannel ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       sortOrder = sortOrder ?? 0,
       archived = archived ?? false;

  factory Channel({
    int? id,
    required String name,
    String? emoji,
    bool? pinned,
    bool? isSystemChannel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? archived,
    DateTime? archivedAt,
  }) = _ChannelImpl;

  factory Channel.fromJson(Map<String, dynamic> jsonSerialization) {
    return Channel(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      emoji: jsonSerialization['emoji'] as String?,
      pinned: jsonSerialization['pinned'] as bool?,
      isSystemChannel: jsonSerialization['isSystemChannel'] as bool?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      sortOrder: jsonSerialization['sortOrder'] as int?,
      archived: jsonSerialization['archived'] as bool?,
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['archivedAt']),
    );
  }

  static final t = ChannelTable();

  static const db = ChannelRepository._();

  @override
  int? id;

  /// The name of the channel.
  String name;

  /// Phosphor icon key for the channel (e.g. 'chatCircle', 'bookOpen').
  String emoji;

  /// Whether the channel is pinned.
  bool pinned;

  /// Whether this is a system channel (cannot be deleted/renamed by users).
  bool isSystemChannel;

  /// When the channel was created.
  DateTime createdAt;

  /// When the channel was last updated (e.g., when a note is posted).
  DateTime updatedAt;

  /// Manual sort order within pinned/unpinned groups (lower = higher).
  int sortOrder;

  /// Whether this channel is archived (soft deleted).
  bool archived;

  /// When the channel was archived.
  DateTime? archivedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Channel copyWith({
    int? id,
    String? name,
    String? emoji,
    bool? pinned,
    bool? isSystemChannel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? archived,
    DateTime? archivedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'name': name,
      'emoji': emoji,
      'pinned': pinned,
      'isSystemChannel': isSystemChannel,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'sortOrder': sortOrder,
      'archived': archived,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'name': name,
      'emoji': emoji,
      'pinned': pinned,
      'isSystemChannel': isSystemChannel,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      'sortOrder': sortOrder,
      'archived': archived,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
    };
  }

  static ChannelInclude include() {
    return ChannelInclude._();
  }

  static ChannelIncludeList includeList({
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    ChannelInclude? include,
  }) {
    return ChannelIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Channel.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Channel.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChannelImpl extends Channel {
  _ChannelImpl({
    int? id,
    required String name,
    String? emoji,
    bool? pinned,
    bool? isSystemChannel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? archived,
    DateTime? archivedAt,
  }) : super._(
         id: id,
         name: name,
         emoji: emoji,
         pinned: pinned,
         isSystemChannel: isSystemChannel,
         createdAt: createdAt,
         updatedAt: updatedAt,
         sortOrder: sortOrder,
         archived: archived,
         archivedAt: archivedAt,
       );

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Channel copyWith({
    Object? id = _Undefined,
    String? name,
    String? emoji,
    bool? pinned,
    bool? isSystemChannel,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? sortOrder,
    bool? archived,
    Object? archivedAt = _Undefined,
  }) {
    return Channel(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      pinned: pinned ?? this.pinned,
      isSystemChannel: isSystemChannel ?? this.isSystemChannel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
    );
  }
}

class ChannelUpdateTable extends _i1.UpdateTable<ChannelTable> {
  ChannelUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> emoji(String value) => _i1.ColumnValue(
    table.emoji,
    value,
  );

  _i1.ColumnValue<bool, bool> pinned(bool value) => _i1.ColumnValue(
    table.pinned,
    value,
  );

  _i1.ColumnValue<bool, bool> isSystemChannel(bool value) => _i1.ColumnValue(
    table.isSystemChannel,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );

  _i1.ColumnValue<int, int> sortOrder(int value) => _i1.ColumnValue(
    table.sortOrder,
    value,
  );

  _i1.ColumnValue<bool, bool> archived(bool value) => _i1.ColumnValue(
    table.archived,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> archivedAt(DateTime? value) =>
      _i1.ColumnValue(
        table.archivedAt,
        value,
      );
}

class ChannelTable extends _i1.Table<int?> {
  ChannelTable({super.tableRelation}) : super(tableName: 'channels') {
    updateTable = ChannelUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    emoji = _i1.ColumnString(
      'emoji',
      this,
      hasDefault: true,
    );
    pinned = _i1.ColumnBool(
      'pinned',
      this,
      hasDefault: true,
    );
    isSystemChannel = _i1.ColumnBool(
      'isSystemChannel',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
      hasDefault: true,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
      hasDefault: true,
    );
    sortOrder = _i1.ColumnInt(
      'sortOrder',
      this,
      hasDefault: true,
    );
    archived = _i1.ColumnBool(
      'archived',
      this,
      hasDefault: true,
    );
    archivedAt = _i1.ColumnDateTime(
      'archivedAt',
      this,
    );
  }

  late final ChannelUpdateTable updateTable;

  /// The name of the channel.
  late final _i1.ColumnString name;

  /// Phosphor icon key for the channel (e.g. 'chatCircle', 'bookOpen').
  late final _i1.ColumnString emoji;

  /// Whether the channel is pinned.
  late final _i1.ColumnBool pinned;

  /// Whether this is a system channel (cannot be deleted/renamed by users).
  late final _i1.ColumnBool isSystemChannel;

  /// When the channel was created.
  late final _i1.ColumnDateTime createdAt;

  /// When the channel was last updated (e.g., when a note is posted).
  late final _i1.ColumnDateTime updatedAt;

  /// Manual sort order within pinned/unpinned groups (lower = higher).
  late final _i1.ColumnInt sortOrder;

  /// Whether this channel is archived (soft deleted).
  late final _i1.ColumnBool archived;

  /// When the channel was archived.
  late final _i1.ColumnDateTime archivedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    emoji,
    pinned,
    isSystemChannel,
    createdAt,
    updatedAt,
    sortOrder,
    archived,
    archivedAt,
  ];
}

class ChannelInclude extends _i1.IncludeObject {
  ChannelInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Channel.t;
}

class ChannelIncludeList extends _i1.IncludeList {
  ChannelIncludeList._({
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Channel.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Channel.t;
}

class ChannelRepository {
  const ChannelRepository._();

  /// Returns a list of [Channel]s matching the given query parameters.
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
  Future<List<Channel>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Channel>(
      where: where?.call(Channel.t),
      orderBy: orderBy?.call(Channel.t),
      orderByList: orderByList?.call(Channel.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Channel] matching the given query parameters.
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
  Future<Channel?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Channel>(
      where: where?.call(Channel.t),
      orderBy: orderBy?.call(Channel.t),
      orderByList: orderByList?.call(Channel.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Channel] by its [id] or null if no such row exists.
  Future<Channel?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Channel>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Channel]s in the list and returns the inserted rows.
  ///
  /// The returned [Channel]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Channel>> insert(
    _i1.Session session,
    List<Channel> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Channel>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Channel] and returns the inserted row.
  ///
  /// The returned [Channel] will have its `id` field set.
  Future<Channel> insertRow(
    _i1.Session session,
    Channel row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Channel>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Channel]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Channel>> update(
    _i1.Session session,
    List<Channel> rows, {
    _i1.ColumnSelections<ChannelTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Channel>(
      rows,
      columns: columns?.call(Channel.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Channel]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Channel> updateRow(
    _i1.Session session,
    Channel row, {
    _i1.ColumnSelections<ChannelTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Channel>(
      row,
      columns: columns?.call(Channel.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Channel] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Channel?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ChannelUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Channel>(
      id,
      columnValues: columnValues(Channel.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Channel]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Channel>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ChannelUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ChannelTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ChannelTable>? orderBy,
    _i1.OrderByListBuilder<ChannelTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Channel>(
      columnValues: columnValues(Channel.t.updateTable),
      where: where(Channel.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Channel.t),
      orderByList: orderByList?.call(Channel.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Channel]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Channel>> delete(
    _i1.Session session,
    List<Channel> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Channel>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Channel].
  Future<Channel> deleteRow(
    _i1.Session session,
    Channel row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Channel>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Channel>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ChannelTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Channel>(
      where: where(Channel.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ChannelTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Channel>(
      where: where?.call(Channel.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
