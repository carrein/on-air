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
import 'package:serverpod/protocol.dart' as _i2;
import 'chat/archive_item.dart' as _i3;
import 'chat/channel.dart' as _i4;
import 'chat/chat_event.dart' as _i5;
import 'chat/link_preview.dart' as _i6;
import 'chat/note.dart' as _i7;
import 'media/media_attachment.dart' as _i8;
import 'pagewatch/page_watch.dart' as _i9;
import 'search/search_result.dart' as _i10;
import 'settings/app_settings.dart' as _i11;
import 'sync/sync_change.dart' as _i12;
import 'sync/sync_pull_response.dart' as _i13;
import 'sync/sync_push_response.dart' as _i14;
import 'sync/sync_result.dart' as _i15;
import 'package:memoka_server/src/generated/chat/channel.dart' as _i16;
import 'package:memoka_server/src/generated/chat/note.dart' as _i17;
import 'package:memoka_server/src/generated/chat/archive_item.dart' as _i18;
import 'package:memoka_server/src/generated/search/search_result.dart' as _i19;
import 'package:memoka_server/src/generated/sync/sync_change.dart' as _i20;
export 'chat/archive_item.dart';
export 'chat/channel.dart';
export 'chat/chat_event.dart';
export 'chat/link_preview.dart';
export 'chat/note.dart';
export 'media/media_attachment.dart';
export 'pagewatch/page_watch.dart';
export 'search/search_result.dart';
export 'settings/app_settings.dart';
export 'sync/sync_change.dart';
export 'sync/sync_pull_response.dart';
export 'sync/sync_push_response.dart';
export 'sync/sync_result.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'channels',
      dartName: 'Channel',
      schema: 'public',
      module: 'memoka',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'channels_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'emoji',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'chatCircle\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'pinned',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'isSystemChannel',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'sortOrder',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'archived',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'archivedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'version',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'position',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
          columnDefault: '0.0',
        ),
        _i2.ColumnDefinition(
          name: 'clientMutationId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'channels_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'channels_version_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'version',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'client_mutation_ch_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientMutationId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'media_attachments',
      dartName: 'MediaAttachment',
      schema: 'public',
      module: 'memoka',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'media_attachments_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'noteId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'filePath',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'originalFilename',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'mimeType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'fileSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'width',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'height',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'duration',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'thumbnailPath',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'compressed',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'animated',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'contentHash',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'uploadedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'media_attachments_fk_0',
          columns: ['noteId'],
          referenceTable: 'notes',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'media_attachments_fk_1',
          columns: ['channelId'],
          referenceTable: 'channels',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'media_attachments_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'note_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'noteId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'channel_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'uploadedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'notes',
      dartName: 'Note',
      schema: 'public',
      module: 'memoka',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'notes_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'content',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'linkPreview',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'protocol:LinkPreview?',
        ),
        _i2.ColumnDefinition(
          name: 'attachments',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<protocol:MediaAttachment>?',
        ),
        _i2.ColumnDefinition(
          name: 'archived',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'archivedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
        _i2.ColumnDefinition(
          name: 'clientMutationId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'version',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'deletedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'notes_fk_0',
          columns: ['channelId'],
          referenceTable: 'channels',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'notes_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'channel_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'archived_updated_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'archived',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'client_mutation_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'clientMutationId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'notes_version_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'version',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i3.ArchiveItem) {
      return _i3.ArchiveItem.fromJson(data) as T;
    }
    if (t == _i4.Channel) {
      return _i4.Channel.fromJson(data) as T;
    }
    if (t == _i5.ChatEvent) {
      return _i5.ChatEvent.fromJson(data) as T;
    }
    if (t == _i6.LinkPreview) {
      return _i6.LinkPreview.fromJson(data) as T;
    }
    if (t == _i7.Note) {
      return _i7.Note.fromJson(data) as T;
    }
    if (t == _i8.MediaAttachment) {
      return _i8.MediaAttachment.fromJson(data) as T;
    }
    if (t == _i9.PageWatch) {
      return _i9.PageWatch.fromJson(data) as T;
    }
    if (t == _i10.SearchResult) {
      return _i10.SearchResult.fromJson(data) as T;
    }
    if (t == _i11.AppSettings) {
      return _i11.AppSettings.fromJson(data) as T;
    }
    if (t == _i12.SyncChange) {
      return _i12.SyncChange.fromJson(data) as T;
    }
    if (t == _i13.SyncPullResponse) {
      return _i13.SyncPullResponse.fromJson(data) as T;
    }
    if (t == _i14.SyncPushResponse) {
      return _i14.SyncPushResponse.fromJson(data) as T;
    }
    if (t == _i15.SyncResult) {
      return _i15.SyncResult.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.ArchiveItem?>()) {
      return (data != null ? _i3.ArchiveItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Channel?>()) {
      return (data != null ? _i4.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ChatEvent?>()) {
      return (data != null ? _i5.ChatEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.LinkPreview?>()) {
      return (data != null ? _i6.LinkPreview.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Note?>()) {
      return (data != null ? _i7.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.MediaAttachment?>()) {
      return (data != null ? _i8.MediaAttachment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.PageWatch?>()) {
      return (data != null ? _i9.PageWatch.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SearchResult?>()) {
      return (data != null ? _i10.SearchResult.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.AppSettings?>()) {
      return (data != null ? _i11.AppSettings.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.SyncChange?>()) {
      return (data != null ? _i12.SyncChange.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.SyncPullResponse?>()) {
      return (data != null ? _i13.SyncPullResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.SyncPushResponse?>()) {
      return (data != null ? _i14.SyncPushResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.SyncResult?>()) {
      return (data != null ? _i15.SyncResult.fromJson(data) : null) as T;
    }
    if (t == List<_i8.MediaAttachment>) {
      return (data as List)
              .map((e) => deserialize<_i8.MediaAttachment>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i8.MediaAttachment>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i8.MediaAttachment>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i4.Channel>) {
      return (data as List).map((e) => deserialize<_i4.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i7.Note>) {
      return (data as List).map((e) => deserialize<_i7.Note>(e)).toList() as T;
    }
    if (t == List<_i15.SyncResult>) {
      return (data as List).map((e) => deserialize<_i15.SyncResult>(e)).toList()
          as T;
    }
    if (t == List<_i16.Channel>) {
      return (data as List).map((e) => deserialize<_i16.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i17.Note>) {
      return (data as List).map((e) => deserialize<_i17.Note>(e)).toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i18.ArchiveItem>) {
      return (data as List)
              .map((e) => deserialize<_i18.ArchiveItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i19.SearchResult>) {
      return (data as List)
              .map((e) => deserialize<_i19.SearchResult>(e))
              .toList()
          as T;
    }
    if (t == List<_i20.SyncChange>) {
      return (data as List).map((e) => deserialize<_i20.SyncChange>(e)).toList()
          as T;
    }
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.ArchiveItem => 'ArchiveItem',
      _i4.Channel => 'Channel',
      _i5.ChatEvent => 'ChatEvent',
      _i6.LinkPreview => 'LinkPreview',
      _i7.Note => 'Note',
      _i8.MediaAttachment => 'MediaAttachment',
      _i9.PageWatch => 'PageWatch',
      _i10.SearchResult => 'SearchResult',
      _i11.AppSettings => 'AppSettings',
      _i12.SyncChange => 'SyncChange',
      _i13.SyncPullResponse => 'SyncPullResponse',
      _i14.SyncPushResponse => 'SyncPushResponse',
      _i15.SyncResult => 'SyncResult',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('memoka.', '');
    }

    switch (data) {
      case _i3.ArchiveItem():
        return 'ArchiveItem';
      case _i4.Channel():
        return 'Channel';
      case _i5.ChatEvent():
        return 'ChatEvent';
      case _i6.LinkPreview():
        return 'LinkPreview';
      case _i7.Note():
        return 'Note';
      case _i8.MediaAttachment():
        return 'MediaAttachment';
      case _i9.PageWatch():
        return 'PageWatch';
      case _i10.SearchResult():
        return 'SearchResult';
      case _i11.AppSettings():
        return 'AppSettings';
      case _i12.SyncChange():
        return 'SyncChange';
      case _i13.SyncPullResponse():
        return 'SyncPullResponse';
      case _i14.SyncPushResponse():
        return 'SyncPushResponse';
      case _i15.SyncResult():
        return 'SyncResult';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ArchiveItem') {
      return deserialize<_i3.ArchiveItem>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i4.Channel>(data['data']);
    }
    if (dataClassName == 'ChatEvent') {
      return deserialize<_i5.ChatEvent>(data['data']);
    }
    if (dataClassName == 'LinkPreview') {
      return deserialize<_i6.LinkPreview>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i7.Note>(data['data']);
    }
    if (dataClassName == 'MediaAttachment') {
      return deserialize<_i8.MediaAttachment>(data['data']);
    }
    if (dataClassName == 'PageWatch') {
      return deserialize<_i9.PageWatch>(data['data']);
    }
    if (dataClassName == 'SearchResult') {
      return deserialize<_i10.SearchResult>(data['data']);
    }
    if (dataClassName == 'AppSettings') {
      return deserialize<_i11.AppSettings>(data['data']);
    }
    if (dataClassName == 'SyncChange') {
      return deserialize<_i12.SyncChange>(data['data']);
    }
    if (dataClassName == 'SyncPullResponse') {
      return deserialize<_i13.SyncPullResponse>(data['data']);
    }
    if (dataClassName == 'SyncPushResponse') {
      return deserialize<_i14.SyncPushResponse>(data['data']);
    }
    if (dataClassName == 'SyncResult') {
      return deserialize<_i15.SyncResult>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i4.Channel:
        return _i4.Channel.t;
      case _i7.Note:
        return _i7.Note.t;
      case _i8.MediaAttachment:
        return _i8.MediaAttachment.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'memoka';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i2.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
