// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CachedChannelsTable extends CachedChannels
    with TableInfo<$CachedChannelsTable, CachedChannel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedChannel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedChannel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedChannel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CachedChannelsTable createAlias(String alias) {
    return $CachedChannelsTable(attachedDatabase, alias);
  }
}

class CachedChannel extends DataClass implements Insertable<CachedChannel> {
  final int id;
  final String json;
  const CachedChannel({required this.id, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    return map;
  }

  CachedChannelsCompanion toCompanion(bool nullToAbsent) {
    return CachedChannelsCompanion(id: Value(id), json: Value(json));
  }

  factory CachedChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedChannel(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
    };
  }

  CachedChannel copyWith({int? id, String? json}) =>
      CachedChannel(id: id ?? this.id, json: json ?? this.json);
  CachedChannel copyWithCompanion(CachedChannelsCompanion data) {
    return CachedChannel(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannel(')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedChannel &&
          other.id == this.id &&
          other.json == this.json);
}

class CachedChannelsCompanion extends UpdateCompanion<CachedChannel> {
  final Value<int> id;
  final Value<String> json;
  const CachedChannelsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
  });
  CachedChannelsCompanion.insert({
    this.id = const Value.absent(),
    required String json,
  }) : json = Value(json);
  static Insertable<CachedChannel> custom({
    Expression<int>? id,
    Expression<String>? json,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
    });
  }

  CachedChannelsCompanion copyWith({Value<int>? id, Value<String>? json}) {
    return CachedChannelsCompanion(id: id ?? this.id, json: json ?? this.json);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannelsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }
}

class $CachedNotesTable extends CachedNotes
    with TableInfo<$CachedNotesTable, CachedNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, channelId, createdAt, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedNote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedNote(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CachedNotesTable createAlias(String alias) {
    return $CachedNotesTable(attachedDatabase, alias);
  }
}

class CachedNote extends DataClass implements Insertable<CachedNote> {
  final int id;
  final int channelId;
  final DateTime createdAt;
  final String json;
  const CachedNote({
    required this.id,
    required this.channelId,
    required this.createdAt,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['json'] = Variable<String>(json);
    return map;
  }

  CachedNotesCompanion toCompanion(bool nullToAbsent) {
    return CachedNotesCompanion(
      id: Value(id),
      channelId: Value(channelId),
      createdAt: Value(createdAt),
      json: Value(json),
    );
  }

  factory CachedNote.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedNote(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'json': serializer.toJson<String>(json),
    };
  }

  CachedNote copyWith({
    int? id,
    int? channelId,
    DateTime? createdAt,
    String? json,
  }) => CachedNote(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    createdAt: createdAt ?? this.createdAt,
    json: json ?? this.json,
  );
  CachedNote copyWithCompanion(CachedNotesCompanion data) {
    return CachedNote(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNote(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('createdAt: $createdAt, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, channelId, createdAt, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNote &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.createdAt == this.createdAt &&
          other.json == this.json);
}

class CachedNotesCompanion extends UpdateCompanion<CachedNote> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<DateTime> createdAt;
  final Value<String> json;
  const CachedNotesCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.json = const Value.absent(),
  });
  CachedNotesCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    required DateTime createdAt,
    required String json,
  }) : channelId = Value(channelId),
       createdAt = Value(createdAt),
       json = Value(json);
  static Insertable<CachedNote> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<DateTime>? createdAt,
    Expression<String>? json,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (createdAt != null) 'created_at': createdAt,
      if (json != null) 'json': json,
    });
  }

  CachedNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? channelId,
    Value<DateTime>? createdAt,
    Value<String>? json,
  }) {
    return CachedNotesCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      createdAt: createdAt ?? this.createdAt,
      json: json ?? this.json,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotesCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('createdAt: $createdAt, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }
}

class $CachedArchiveItemsTable extends CachedArchiveItems
    with TableInfo<$CachedArchiveItemsTable, CachedArchiveItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedArchiveItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, archivedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_archive_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedArchiveItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_archivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedArchiveItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedArchiveItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      )!,
    );
  }

  @override
  $CachedArchiveItemsTable createAlias(String alias) {
    return $CachedArchiveItemsTable(attachedDatabase, alias);
  }
}

class CachedArchiveItem extends DataClass
    implements Insertable<CachedArchiveItem> {
  final int id;
  final String json;
  final DateTime archivedAt;
  const CachedArchiveItem({
    required this.id,
    required this.json,
    required this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    map['archived_at'] = Variable<DateTime>(archivedAt);
    return map;
  }

  CachedArchiveItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedArchiveItemsCompanion(
      id: Value(id),
      json: Value(json),
      archivedAt: Value(archivedAt),
    );
  }

  factory CachedArchiveItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedArchiveItem(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      archivedAt: serializer.fromJson<DateTime>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'archivedAt': serializer.toJson<DateTime>(archivedAt),
    };
  }

  CachedArchiveItem copyWith({int? id, String? json, DateTime? archivedAt}) =>
      CachedArchiveItem(
        id: id ?? this.id,
        json: json ?? this.json,
        archivedAt: archivedAt ?? this.archivedAt,
      );
  CachedArchiveItem copyWithCompanion(CachedArchiveItemsCompanion data) {
    return CachedArchiveItem(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedArchiveItem(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, archivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedArchiveItem &&
          other.id == this.id &&
          other.json == this.json &&
          other.archivedAt == this.archivedAt);
}

class CachedArchiveItemsCompanion extends UpdateCompanion<CachedArchiveItem> {
  final Value<int> id;
  final Value<String> json;
  final Value<DateTime> archivedAt;
  const CachedArchiveItemsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.archivedAt = const Value.absent(),
  });
  CachedArchiveItemsCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    required DateTime archivedAt,
  }) : json = Value(json),
       archivedAt = Value(archivedAt);
  static Insertable<CachedArchiveItem> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<DateTime>? archivedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (archivedAt != null) 'archived_at': archivedAt,
    });
  }

  CachedArchiveItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<DateTime>? archivedAt,
  }) {
    return CachedArchiveItemsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedArchiveItemsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }
}

class $PendingMutationsTable extends PendingMutations
    with TableInfo<$PendingMutationsTable, PendingMutation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingMutationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
    'channel_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    channelId,
    payload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_mutations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingMutation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingMutation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingMutation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}channel_id'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingMutationsTable createAlias(String alias) {
    return $PendingMutationsTable(attachedDatabase, alias);
  }
}

class PendingMutation extends DataClass implements Insertable<PendingMutation> {
  final int id;
  final String type;
  final int? channelId;
  final String payload;
  final DateTime createdAt;
  const PendingMutation({
    required this.id,
    required this.type,
    this.channelId,
    required this.payload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || channelId != null) {
      map['channel_id'] = Variable<int>(channelId);
    }
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingMutationsCompanion toCompanion(bool nullToAbsent) {
    return PendingMutationsCompanion(
      id: Value(id),
      type: Value(type),
      channelId: channelId == null && nullToAbsent
          ? const Value.absent()
          : Value(channelId),
      payload: Value(payload),
      createdAt: Value(createdAt),
    );
  }

  factory PendingMutation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingMutation(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      channelId: serializer.fromJson<int?>(json['channelId']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'channelId': serializer.toJson<int?>(channelId),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingMutation copyWith({
    int? id,
    String? type,
    Value<int?> channelId = const Value.absent(),
    String? payload,
    DateTime? createdAt,
  }) => PendingMutation(
    id: id ?? this.id,
    type: type ?? this.type,
    channelId: channelId.present ? channelId.value : this.channelId,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingMutation copyWithCompanion(PendingMutationsCompanion data) {
    return PendingMutation(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutation(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('channelId: $channelId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, channelId, payload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingMutation &&
          other.id == this.id &&
          other.type == this.type &&
          other.channelId == this.channelId &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt);
}

class PendingMutationsCompanion extends UpdateCompanion<PendingMutation> {
  final Value<int> id;
  final Value<String> type;
  final Value<int?> channelId;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  const PendingMutationsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.channelId = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingMutationsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.channelId = const Value.absent(),
    required String payload,
    required DateTime createdAt,
  }) : type = Value(type),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<PendingMutation> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? channelId,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (channelId != null) 'channel_id': channelId,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingMutationsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int?>? channelId,
    Value<String>? payload,
    Value<DateTime>? createdAt,
  }) {
    return PendingMutationsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      channelId: channelId ?? this.channelId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingMutationsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('channelId: $channelId, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedChannelsTable cachedChannels = $CachedChannelsTable(this);
  late final $CachedNotesTable cachedNotes = $CachedNotesTable(this);
  late final $CachedArchiveItemsTable cachedArchiveItems =
      $CachedArchiveItemsTable(this);
  late final $PendingMutationsTable pendingMutations = $PendingMutationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedChannels,
    cachedNotes,
    cachedArchiveItems,
    pendingMutations,
  ];
}

typedef $$CachedChannelsTableCreateCompanionBuilder =
    CachedChannelsCompanion Function({Value<int> id, required String json});
typedef $$CachedChannelsTableUpdateCompanionBuilder =
    CachedChannelsCompanion Function({Value<int> id, Value<String> json});

class $$CachedChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedChannelsTable> {
  $$CachedChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedChannelsTable> {
  $$CachedChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedChannelsTable> {
  $$CachedChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CachedChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedChannelsTable,
          CachedChannel,
          $$CachedChannelsTableFilterComposer,
          $$CachedChannelsTableOrderingComposer,
          $$CachedChannelsTableAnnotationComposer,
          $$CachedChannelsTableCreateCompanionBuilder,
          $$CachedChannelsTableUpdateCompanionBuilder,
          (
            CachedChannel,
            BaseReferences<_$AppDatabase, $CachedChannelsTable, CachedChannel>,
          ),
          CachedChannel,
          PrefetchHooks Function()
        > {
  $$CachedChannelsTableTableManager(
    _$AppDatabase db,
    $CachedChannelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
              }) => CachedChannelsCompanion(id: id, json: json),
          createCompanionCallback:
              ({Value<int> id = const Value.absent(), required String json}) =>
                  CachedChannelsCompanion.insert(id: id, json: json),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedChannelsTable,
      CachedChannel,
      $$CachedChannelsTableFilterComposer,
      $$CachedChannelsTableOrderingComposer,
      $$CachedChannelsTableAnnotationComposer,
      $$CachedChannelsTableCreateCompanionBuilder,
      $$CachedChannelsTableUpdateCompanionBuilder,
      (
        CachedChannel,
        BaseReferences<_$AppDatabase, $CachedChannelsTable, CachedChannel>,
      ),
      CachedChannel,
      PrefetchHooks Function()
    >;
typedef $$CachedNotesTableCreateCompanionBuilder =
    CachedNotesCompanion Function({
      Value<int> id,
      required int channelId,
      required DateTime createdAt,
      required String json,
    });
typedef $$CachedNotesTableUpdateCompanionBuilder =
    CachedNotesCompanion Function({
      Value<int> id,
      Value<int> channelId,
      Value<DateTime> createdAt,
      Value<String> json,
    });

class $$CachedNotesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedNotesTable> {
  $$CachedNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CachedNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedNotesTable,
          CachedNote,
          $$CachedNotesTableFilterComposer,
          $$CachedNotesTableOrderingComposer,
          $$CachedNotesTableAnnotationComposer,
          $$CachedNotesTableCreateCompanionBuilder,
          $$CachedNotesTableUpdateCompanionBuilder,
          (
            CachedNote,
            BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>,
          ),
          CachedNote,
          PrefetchHooks Function()
        > {
  $$CachedNotesTableTableManager(_$AppDatabase db, $CachedNotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> channelId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> json = const Value.absent(),
              }) => CachedNotesCompanion(
                id: id,
                channelId: channelId,
                createdAt: createdAt,
                json: json,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int channelId,
                required DateTime createdAt,
                required String json,
              }) => CachedNotesCompanion.insert(
                id: id,
                channelId: channelId,
                createdAt: createdAt,
                json: json,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedNotesTable,
      CachedNote,
      $$CachedNotesTableFilterComposer,
      $$CachedNotesTableOrderingComposer,
      $$CachedNotesTableAnnotationComposer,
      $$CachedNotesTableCreateCompanionBuilder,
      $$CachedNotesTableUpdateCompanionBuilder,
      (
        CachedNote,
        BaseReferences<_$AppDatabase, $CachedNotesTable, CachedNote>,
      ),
      CachedNote,
      PrefetchHooks Function()
    >;
typedef $$CachedArchiveItemsTableCreateCompanionBuilder =
    CachedArchiveItemsCompanion Function({
      Value<int> id,
      required String json,
      required DateTime archivedAt,
    });
typedef $$CachedArchiveItemsTableUpdateCompanionBuilder =
    CachedArchiveItemsCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<DateTime> archivedAt,
    });

class $$CachedArchiveItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedArchiveItemsTable> {
  $$CachedArchiveItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedArchiveItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedArchiveItemsTable> {
  $$CachedArchiveItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedArchiveItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedArchiveItemsTable> {
  $$CachedArchiveItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$CachedArchiveItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedArchiveItemsTable,
          CachedArchiveItem,
          $$CachedArchiveItemsTableFilterComposer,
          $$CachedArchiveItemsTableOrderingComposer,
          $$CachedArchiveItemsTableAnnotationComposer,
          $$CachedArchiveItemsTableCreateCompanionBuilder,
          $$CachedArchiveItemsTableUpdateCompanionBuilder,
          (
            CachedArchiveItem,
            BaseReferences<
              _$AppDatabase,
              $CachedArchiveItemsTable,
              CachedArchiveItem
            >,
          ),
          CachedArchiveItem,
          PrefetchHooks Function()
        > {
  $$CachedArchiveItemsTableTableManager(
    _$AppDatabase db,
    $CachedArchiveItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedArchiveItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedArchiveItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedArchiveItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> archivedAt = const Value.absent(),
              }) => CachedArchiveItemsCompanion(
                id: id,
                json: json,
                archivedAt: archivedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                required DateTime archivedAt,
              }) => CachedArchiveItemsCompanion.insert(
                id: id,
                json: json,
                archivedAt: archivedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedArchiveItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedArchiveItemsTable,
      CachedArchiveItem,
      $$CachedArchiveItemsTableFilterComposer,
      $$CachedArchiveItemsTableOrderingComposer,
      $$CachedArchiveItemsTableAnnotationComposer,
      $$CachedArchiveItemsTableCreateCompanionBuilder,
      $$CachedArchiveItemsTableUpdateCompanionBuilder,
      (
        CachedArchiveItem,
        BaseReferences<
          _$AppDatabase,
          $CachedArchiveItemsTable,
          CachedArchiveItem
        >,
      ),
      CachedArchiveItem,
      PrefetchHooks Function()
    >;
typedef $$PendingMutationsTableCreateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<int> id,
      required String type,
      Value<int?> channelId,
      required String payload,
      required DateTime createdAt,
    });
typedef $$PendingMutationsTableUpdateCompanionBuilder =
    PendingMutationsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<int?> channelId,
      Value<String> payload,
      Value<DateTime> createdAt,
    });

class $$PendingMutationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingMutationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingMutationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingMutationsTable> {
  $$PendingMutationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingMutationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingMutationsTable,
          PendingMutation,
          $$PendingMutationsTableFilterComposer,
          $$PendingMutationsTableOrderingComposer,
          $$PendingMutationsTableAnnotationComposer,
          $$PendingMutationsTableCreateCompanionBuilder,
          $$PendingMutationsTableUpdateCompanionBuilder,
          (
            PendingMutation,
            BaseReferences<
              _$AppDatabase,
              $PendingMutationsTable,
              PendingMutation
            >,
          ),
          PendingMutation,
          PrefetchHooks Function()
        > {
  $$PendingMutationsTableTableManager(
    _$AppDatabase db,
    $PendingMutationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingMutationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingMutationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingMutationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int?> channelId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PendingMutationsCompanion(
                id: id,
                type: type,
                channelId: channelId,
                payload: payload,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                Value<int?> channelId = const Value.absent(),
                required String payload,
                required DateTime createdAt,
              }) => PendingMutationsCompanion.insert(
                id: id,
                type: type,
                channelId: channelId,
                payload: payload,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingMutationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingMutationsTable,
      PendingMutation,
      $$PendingMutationsTableFilterComposer,
      $$PendingMutationsTableOrderingComposer,
      $$PendingMutationsTableAnnotationComposer,
      $$PendingMutationsTableCreateCompanionBuilder,
      $$PendingMutationsTableUpdateCompanionBuilder,
      (
        PendingMutation,
        BaseReferences<_$AppDatabase, $PendingMutationsTable, PendingMutation>,
      ),
      PendingMutation,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedChannelsTableTableManager get cachedChannels =>
      $$CachedChannelsTableTableManager(_db, _db.cachedChannels);
  $$CachedNotesTableTableManager get cachedNotes =>
      $$CachedNotesTableTableManager(_db, _db.cachedNotes);
  $$CachedArchiveItemsTableTableManager get cachedArchiveItems =>
      $$CachedArchiveItemsTableTableManager(_db, _db.cachedArchiveItems);
  $$PendingMutationsTableTableManager get pendingMutations =>
      $$PendingMutationsTableTableManager(_db, _db.pendingMutations);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'381febe96593785fa9c66d1647b02b1f2c4c7d05';

/// Provides the singleton [AppDatabase] instance.
/// On native: SQLite file on disk. On web: WASM SQLite backed by IndexedDB.
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = Provider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = ProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
