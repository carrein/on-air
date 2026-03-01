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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedLocallyMeta = const VerificationMeta(
    'deletedLocally',
  );
  @override
  late final GeneratedColumn<bool> deletedLocally = GeneratedColumn<bool>(
    'deleted_locally',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_locally" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isNewMeta = const VerificationMeta('isNew');
  @override
  late final GeneratedColumn<bool> isNew = GeneratedColumn<bool>(
    'is_new',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_new" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clientMutationIdMeta = const VerificationMeta(
    'clientMutationId',
  );
  @override
  late final GeneratedColumn<String> clientMutationId = GeneratedColumn<String>(
    'client_mutation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    json,
    version,
    dirty,
    deletedLocally,
    isNew,
    clientMutationId,
  ];
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('deleted_locally')) {
      context.handle(
        _deletedLocallyMeta,
        deletedLocally.isAcceptableOrUnknown(
          data['deleted_locally']!,
          _deletedLocallyMeta,
        ),
      );
    }
    if (data.containsKey('is_new')) {
      context.handle(
        _isNewMeta,
        isNew.isAcceptableOrUnknown(data['is_new']!, _isNewMeta),
      );
    }
    if (data.containsKey('client_mutation_id')) {
      context.handle(
        _clientMutationIdMeta,
        clientMutationId.isAcceptableOrUnknown(
          data['client_mutation_id']!,
          _clientMutationIdMeta,
        ),
      );
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deletedLocally: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_locally'],
      )!,
      isNew: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_new'],
      )!,
      clientMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_mutation_id'],
      ),
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
  final int version;
  final bool dirty;
  final bool deletedLocally;
  final bool isNew;
  final String? clientMutationId;
  const CachedChannel({
    required this.id,
    required this.json,
    required this.version,
    required this.dirty,
    required this.deletedLocally,
    required this.isNew,
    this.clientMutationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    map['version'] = Variable<int>(version);
    map['dirty'] = Variable<bool>(dirty);
    map['deleted_locally'] = Variable<bool>(deletedLocally);
    map['is_new'] = Variable<bool>(isNew);
    if (!nullToAbsent || clientMutationId != null) {
      map['client_mutation_id'] = Variable<String>(clientMutationId);
    }
    return map;
  }

  CachedChannelsCompanion toCompanion(bool nullToAbsent) {
    return CachedChannelsCompanion(
      id: Value(id),
      json: Value(json),
      version: Value(version),
      dirty: Value(dirty),
      deletedLocally: Value(deletedLocally),
      isNew: Value(isNew),
      clientMutationId: clientMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMutationId),
    );
  }

  factory CachedChannel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedChannel(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      version: serializer.fromJson<int>(json['version']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deletedLocally: serializer.fromJson<bool>(json['deletedLocally']),
      isNew: serializer.fromJson<bool>(json['isNew']),
      clientMutationId: serializer.fromJson<String?>(json['clientMutationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'version': serializer.toJson<int>(version),
      'dirty': serializer.toJson<bool>(dirty),
      'deletedLocally': serializer.toJson<bool>(deletedLocally),
      'isNew': serializer.toJson<bool>(isNew),
      'clientMutationId': serializer.toJson<String?>(clientMutationId),
    };
  }

  CachedChannel copyWith({
    int? id,
    String? json,
    int? version,
    bool? dirty,
    bool? deletedLocally,
    bool? isNew,
    Value<String?> clientMutationId = const Value.absent(),
  }) => CachedChannel(
    id: id ?? this.id,
    json: json ?? this.json,
    version: version ?? this.version,
    dirty: dirty ?? this.dirty,
    deletedLocally: deletedLocally ?? this.deletedLocally,
    isNew: isNew ?? this.isNew,
    clientMutationId: clientMutationId.present
        ? clientMutationId.value
        : this.clientMutationId,
  );
  CachedChannel copyWithCompanion(CachedChannelsCompanion data) {
    return CachedChannel(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      version: data.version.present ? data.version.value : this.version,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deletedLocally: data.deletedLocally.present
          ? data.deletedLocally.value
          : this.deletedLocally,
      isNew: data.isNew.present ? data.isNew.value : this.isNew,
      clientMutationId: data.clientMutationId.present
          ? data.clientMutationId.value
          : this.clientMutationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannel(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('dirty: $dirty, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('isNew: $isNew, ')
          ..write('clientMutationId: $clientMutationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    json,
    version,
    dirty,
    deletedLocally,
    isNew,
    clientMutationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedChannel &&
          other.id == this.id &&
          other.json == this.json &&
          other.version == this.version &&
          other.dirty == this.dirty &&
          other.deletedLocally == this.deletedLocally &&
          other.isNew == this.isNew &&
          other.clientMutationId == this.clientMutationId);
}

class CachedChannelsCompanion extends UpdateCompanion<CachedChannel> {
  final Value<int> id;
  final Value<String> json;
  final Value<int> version;
  final Value<bool> dirty;
  final Value<bool> deletedLocally;
  final Value<bool> isNew;
  final Value<String?> clientMutationId;
  const CachedChannelsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.version = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.isNew = const Value.absent(),
    this.clientMutationId = const Value.absent(),
  });
  CachedChannelsCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    this.version = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.isNew = const Value.absent(),
    this.clientMutationId = const Value.absent(),
  }) : json = Value(json);
  static Insertable<CachedChannel> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<int>? version,
    Expression<bool>? dirty,
    Expression<bool>? deletedLocally,
    Expression<bool>? isNew,
    Expression<String>? clientMutationId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (version != null) 'version': version,
      if (dirty != null) 'dirty': dirty,
      if (deletedLocally != null) 'deleted_locally': deletedLocally,
      if (isNew != null) 'is_new': isNew,
      if (clientMutationId != null) 'client_mutation_id': clientMutationId,
    });
  }

  CachedChannelsCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<int>? version,
    Value<bool>? dirty,
    Value<bool>? deletedLocally,
    Value<bool>? isNew,
    Value<String?>? clientMutationId,
  }) {
    return CachedChannelsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      version: version ?? this.version,
      dirty: dirty ?? this.dirty,
      deletedLocally: deletedLocally ?? this.deletedLocally,
      isNew: isNew ?? this.isNew,
      clientMutationId: clientMutationId ?? this.clientMutationId,
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deletedLocally.present) {
      map['deleted_locally'] = Variable<bool>(deletedLocally.value);
    }
    if (isNew.present) {
      map['is_new'] = Variable<bool>(isNew.value);
    }
    if (clientMutationId.present) {
      map['client_mutation_id'] = Variable<String>(clientMutationId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedChannelsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('dirty: $dirty, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('isNew: $isNew, ')
          ..write('clientMutationId: $clientMutationId')
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedLocallyMeta = const VerificationMeta(
    'deletedLocally',
  );
  @override
  late final GeneratedColumn<bool> deletedLocally = GeneratedColumn<bool>(
    'deleted_locally',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted_locally" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isNewMeta = const VerificationMeta('isNew');
  @override
  late final GeneratedColumn<bool> isNew = GeneratedColumn<bool>(
    'is_new',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_new" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clientMutationIdMeta = const VerificationMeta(
    'clientMutationId',
  );
  @override
  late final GeneratedColumn<String> clientMutationId = GeneratedColumn<String>(
    'client_mutation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    createdAt,
    json,
    version,
    dirty,
    deletedLocally,
    isNew,
    clientMutationId,
  ];
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('deleted_locally')) {
      context.handle(
        _deletedLocallyMeta,
        deletedLocally.isAcceptableOrUnknown(
          data['deleted_locally']!,
          _deletedLocallyMeta,
        ),
      );
    }
    if (data.containsKey('is_new')) {
      context.handle(
        _isNewMeta,
        isNew.isAcceptableOrUnknown(data['is_new']!, _isNewMeta),
      );
    }
    if (data.containsKey('client_mutation_id')) {
      context.handle(
        _clientMutationIdMeta,
        clientMutationId.isAcceptableOrUnknown(
          data['client_mutation_id']!,
          _clientMutationIdMeta,
        ),
      );
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deletedLocally: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted_locally'],
      )!,
      isNew: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_new'],
      )!,
      clientMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_mutation_id'],
      ),
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
  final int version;
  final bool dirty;
  final bool deletedLocally;
  final bool isNew;
  final String? clientMutationId;
  const CachedNote({
    required this.id,
    required this.channelId,
    required this.createdAt,
    required this.json,
    required this.version,
    required this.dirty,
    required this.deletedLocally,
    required this.isNew,
    this.clientMutationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['json'] = Variable<String>(json);
    map['version'] = Variable<int>(version);
    map['dirty'] = Variable<bool>(dirty);
    map['deleted_locally'] = Variable<bool>(deletedLocally);
    map['is_new'] = Variable<bool>(isNew);
    if (!nullToAbsent || clientMutationId != null) {
      map['client_mutation_id'] = Variable<String>(clientMutationId);
    }
    return map;
  }

  CachedNotesCompanion toCompanion(bool nullToAbsent) {
    return CachedNotesCompanion(
      id: Value(id),
      channelId: Value(channelId),
      createdAt: Value(createdAt),
      json: Value(json),
      version: Value(version),
      dirty: Value(dirty),
      deletedLocally: Value(deletedLocally),
      isNew: Value(isNew),
      clientMutationId: clientMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientMutationId),
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
      version: serializer.fromJson<int>(json['version']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deletedLocally: serializer.fromJson<bool>(json['deletedLocally']),
      isNew: serializer.fromJson<bool>(json['isNew']),
      clientMutationId: serializer.fromJson<String?>(json['clientMutationId']),
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
      'version': serializer.toJson<int>(version),
      'dirty': serializer.toJson<bool>(dirty),
      'deletedLocally': serializer.toJson<bool>(deletedLocally),
      'isNew': serializer.toJson<bool>(isNew),
      'clientMutationId': serializer.toJson<String?>(clientMutationId),
    };
  }

  CachedNote copyWith({
    int? id,
    int? channelId,
    DateTime? createdAt,
    String? json,
    int? version,
    bool? dirty,
    bool? deletedLocally,
    bool? isNew,
    Value<String?> clientMutationId = const Value.absent(),
  }) => CachedNote(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    createdAt: createdAt ?? this.createdAt,
    json: json ?? this.json,
    version: version ?? this.version,
    dirty: dirty ?? this.dirty,
    deletedLocally: deletedLocally ?? this.deletedLocally,
    isNew: isNew ?? this.isNew,
    clientMutationId: clientMutationId.present
        ? clientMutationId.value
        : this.clientMutationId,
  );
  CachedNote copyWithCompanion(CachedNotesCompanion data) {
    return CachedNote(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      json: data.json.present ? data.json.value : this.json,
      version: data.version.present ? data.version.value : this.version,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deletedLocally: data.deletedLocally.present
          ? data.deletedLocally.value
          : this.deletedLocally,
      isNew: data.isNew.present ? data.isNew.value : this.isNew,
      clientMutationId: data.clientMutationId.present
          ? data.clientMutationId.value
          : this.clientMutationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedNote(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('createdAt: $createdAt, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('dirty: $dirty, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('isNew: $isNew, ')
          ..write('clientMutationId: $clientMutationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    createdAt,
    json,
    version,
    dirty,
    deletedLocally,
    isNew,
    clientMutationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedNote &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.createdAt == this.createdAt &&
          other.json == this.json &&
          other.version == this.version &&
          other.dirty == this.dirty &&
          other.deletedLocally == this.deletedLocally &&
          other.isNew == this.isNew &&
          other.clientMutationId == this.clientMutationId);
}

class CachedNotesCompanion extends UpdateCompanion<CachedNote> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<DateTime> createdAt;
  final Value<String> json;
  final Value<int> version;
  final Value<bool> dirty;
  final Value<bool> deletedLocally;
  final Value<bool> isNew;
  final Value<String?> clientMutationId;
  const CachedNotesCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.json = const Value.absent(),
    this.version = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.isNew = const Value.absent(),
    this.clientMutationId = const Value.absent(),
  });
  CachedNotesCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    required DateTime createdAt,
    required String json,
    this.version = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deletedLocally = const Value.absent(),
    this.isNew = const Value.absent(),
    this.clientMutationId = const Value.absent(),
  }) : channelId = Value(channelId),
       createdAt = Value(createdAt),
       json = Value(json);
  static Insertable<CachedNote> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<DateTime>? createdAt,
    Expression<String>? json,
    Expression<int>? version,
    Expression<bool>? dirty,
    Expression<bool>? deletedLocally,
    Expression<bool>? isNew,
    Expression<String>? clientMutationId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (createdAt != null) 'created_at': createdAt,
      if (json != null) 'json': json,
      if (version != null) 'version': version,
      if (dirty != null) 'dirty': dirty,
      if (deletedLocally != null) 'deleted_locally': deletedLocally,
      if (isNew != null) 'is_new': isNew,
      if (clientMutationId != null) 'client_mutation_id': clientMutationId,
    });
  }

  CachedNotesCompanion copyWith({
    Value<int>? id,
    Value<int>? channelId,
    Value<DateTime>? createdAt,
    Value<String>? json,
    Value<int>? version,
    Value<bool>? dirty,
    Value<bool>? deletedLocally,
    Value<bool>? isNew,
    Value<String?>? clientMutationId,
  }) {
    return CachedNotesCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      createdAt: createdAt ?? this.createdAt,
      json: json ?? this.json,
      version: version ?? this.version,
      dirty: dirty ?? this.dirty,
      deletedLocally: deletedLocally ?? this.deletedLocally,
      isNew: isNew ?? this.isNew,
      clientMutationId: clientMutationId ?? this.clientMutationId,
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deletedLocally.present) {
      map['deleted_locally'] = Variable<bool>(deletedLocally.value);
    }
    if (isNew.present) {
      map['is_new'] = Variable<bool>(isNew.value);
    }
    if (clientMutationId.present) {
      map['client_mutation_id'] = Variable<String>(clientMutationId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedNotesCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('createdAt: $createdAt, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('dirty: $dirty, ')
          ..write('deletedLocally: $deletedLocally, ')
          ..write('isNew: $isNew, ')
          ..write('clientMutationId: $clientMutationId')
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

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _globalVersionMeta = const VerificationMeta(
    'globalVersion',
  );
  @override
  late final GeneratedColumn<int> globalVersion = GeneratedColumn<int>(
    'global_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, globalVersion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('global_version')) {
      context.handle(
        _globalVersionMeta,
        globalVersion.isAcceptableOrUnknown(
          data['global_version']!,
          _globalVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      globalVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}global_version'],
      )!,
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaData extends DataClass implements Insertable<SyncMetaData> {
  final int id;
  final int globalVersion;
  const SyncMetaData({required this.id, required this.globalVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['global_version'] = Variable<int>(globalVersion);
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      id: Value(id),
      globalVersion: Value(globalVersion),
    );
  }

  factory SyncMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaData(
      id: serializer.fromJson<int>(json['id']),
      globalVersion: serializer.fromJson<int>(json['globalVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'globalVersion': serializer.toJson<int>(globalVersion),
    };
  }

  SyncMetaData copyWith({int? id, int? globalVersion}) => SyncMetaData(
    id: id ?? this.id,
    globalVersion: globalVersion ?? this.globalVersion,
  );
  SyncMetaData copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaData(
      id: data.id.present ? data.id.value : this.id,
      globalVersion: data.globalVersion.present
          ? data.globalVersion.value
          : this.globalVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaData(')
          ..write('id: $id, ')
          ..write('globalVersion: $globalVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, globalVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaData &&
          other.id == this.id &&
          other.globalVersion == this.globalVersion);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaData> {
  final Value<int> id;
  final Value<int> globalVersion;
  const SyncMetaCompanion({
    this.id = const Value.absent(),
    this.globalVersion = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    this.id = const Value.absent(),
    this.globalVersion = const Value.absent(),
  });
  static Insertable<SyncMetaData> custom({
    Expression<int>? id,
    Expression<int>? globalVersion,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (globalVersion != null) 'global_version': globalVersion,
    });
  }

  SyncMetaCompanion copyWith({Value<int>? id, Value<int>? globalVersion}) {
    return SyncMetaCompanion(
      id: id ?? this.id,
      globalVersion: globalVersion ?? this.globalVersion,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (globalVersion.present) {
      map['global_version'] = Variable<int>(globalVersion.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('id: $id, ')
          ..write('globalVersion: $globalVersion')
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
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedChannels,
    cachedNotes,
    cachedArchiveItems,
    syncMeta,
  ];
}

typedef $$CachedChannelsTableCreateCompanionBuilder =
    CachedChannelsCompanion Function({
      Value<int> id,
      required String json,
      Value<int> version,
      Value<bool> dirty,
      Value<bool> deletedLocally,
      Value<bool> isNew,
      Value<String?> clientMutationId,
    });
typedef $$CachedChannelsTableUpdateCompanionBuilder =
    CachedChannelsCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<int> version,
      Value<bool> dirty,
      Value<bool> deletedLocally,
      Value<bool> isNew,
      Value<String?> clientMutationId,
    });

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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNew => $composableBuilder(
    column: $table.isNew,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNew => $composableBuilder(
    column: $table.isNew,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNew =>
      $composableBuilder(column: $table.isNew, builder: (column) => column);

  GeneratedColumn<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => column,
  );
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
                Value<int> version = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<bool> isNew = const Value.absent(),
                Value<String?> clientMutationId = const Value.absent(),
              }) => CachedChannelsCompanion(
                id: id,
                json: json,
                version: version,
                dirty: dirty,
                deletedLocally: deletedLocally,
                isNew: isNew,
                clientMutationId: clientMutationId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                Value<int> version = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<bool> isNew = const Value.absent(),
                Value<String?> clientMutationId = const Value.absent(),
              }) => CachedChannelsCompanion.insert(
                id: id,
                json: json,
                version: version,
                dirty: dirty,
                deletedLocally: deletedLocally,
                isNew: isNew,
                clientMutationId: clientMutationId,
              ),
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
      Value<int> version,
      Value<bool> dirty,
      Value<bool> deletedLocally,
      Value<bool> isNew,
      Value<String?> clientMutationId,
    });
typedef $$CachedNotesTableUpdateCompanionBuilder =
    CachedNotesCompanion Function({
      Value<int> id,
      Value<int> channelId,
      Value<DateTime> createdAt,
      Value<String> json,
      Value<int> version,
      Value<bool> dirty,
      Value<bool> deletedLocally,
      Value<bool> isNew,
      Value<String?> clientMutationId,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isNew => $composableBuilder(
    column: $table.isNew,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isNew => $composableBuilder(
    column: $table.isNew,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deletedLocally => $composableBuilder(
    column: $table.deletedLocally,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isNew =>
      $composableBuilder(column: $table.isNew, builder: (column) => column);

  GeneratedColumn<String> get clientMutationId => $composableBuilder(
    column: $table.clientMutationId,
    builder: (column) => column,
  );
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
                Value<int> version = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<bool> isNew = const Value.absent(),
                Value<String?> clientMutationId = const Value.absent(),
              }) => CachedNotesCompanion(
                id: id,
                channelId: channelId,
                createdAt: createdAt,
                json: json,
                version: version,
                dirty: dirty,
                deletedLocally: deletedLocally,
                isNew: isNew,
                clientMutationId: clientMutationId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int channelId,
                required DateTime createdAt,
                required String json,
                Value<int> version = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deletedLocally = const Value.absent(),
                Value<bool> isNew = const Value.absent(),
                Value<String?> clientMutationId = const Value.absent(),
              }) => CachedNotesCompanion.insert(
                id: id,
                channelId: channelId,
                createdAt: createdAt,
                json: json,
                version: version,
                dirty: dirty,
                deletedLocally: deletedLocally,
                isNew: isNew,
                clientMutationId: clientMutationId,
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
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({Value<int> id, Value<int> globalVersion});
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({Value<int> id, Value<int> globalVersion});

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
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

  ColumnFilters<int> get globalVersion => $composableBuilder(
    column: $table.globalVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
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

  ColumnOrderings<int> get globalVersion => $composableBuilder(
    column: $table.globalVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get globalVersion => $composableBuilder(
    column: $table.globalVersion,
    builder: (column) => column,
  );
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaData,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaData,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
          ),
          SyncMetaData,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> globalVersion = const Value.absent(),
              }) => SyncMetaCompanion(id: id, globalVersion: globalVersion),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> globalVersion = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                id: id,
                globalVersion: globalVersion,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaData,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (
        SyncMetaData,
        BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaData>,
      ),
      SyncMetaData,
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
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [AppDatabase] instance.
/// On native: SQLite file on disk. On web: WASM SQLite backed by IndexedDB.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Provides the singleton [AppDatabase] instance.
/// On native: SQLite file on disk. On web: WASM SQLite backed by IndexedDB.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Provides the singleton [AppDatabase] instance.
  /// On native: SQLite file on disk. On web: WASM SQLite backed by IndexedDB.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'381febe96593785fa9c66d1647b02b1f2c4c7d05';
