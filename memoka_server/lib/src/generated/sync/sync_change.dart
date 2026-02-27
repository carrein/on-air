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

/// A single entity change to push to the server.
abstract class SyncChange
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SyncChange._({
    required this.entityType,
    required this.entityJson,
    required this.baseVersion,
    this.tempId,
    this.clientMutationId,
    bool? deleted,
  }) : deleted = deleted ?? false;

  factory SyncChange({
    required String entityType,
    required String entityJson,
    required int baseVersion,
    int? tempId,
    String? clientMutationId,
    bool? deleted,
  }) = _SyncChangeImpl;

  factory SyncChange.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncChange(
      entityType: jsonSerialization['entityType'] as String,
      entityJson: jsonSerialization['entityJson'] as String,
      baseVersion: jsonSerialization['baseVersion'] as int,
      tempId: jsonSerialization['tempId'] as int?,
      clientMutationId: jsonSerialization['clientMutationId'] as String?,
      deleted: jsonSerialization['deleted'] as bool?,
    );
  }

  /// Entity type: "channel" or "note".
  String entityType;

  /// Full entity state as JSON string.
  String entityJson;

  /// Client's last known version of this entity (0 for creates).
  int baseVersion;

  /// Client temp ID for creates (negative integer). Null for updates/deletes.
  int? tempId;

  /// UUID idempotency key for offline creates. Null for updates/deletes.
  String? clientMutationId;

  /// True if this is a permanent delete (sets deletedAt tombstone on server).
  bool deleted;

  /// Returns a shallow copy of this [SyncChange]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncChange copyWith({
    String? entityType,
    String? entityJson,
    int? baseVersion,
    int? tempId,
    String? clientMutationId,
    bool? deleted,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncChange',
      'entityType': entityType,
      'entityJson': entityJson,
      'baseVersion': baseVersion,
      if (tempId != null) 'tempId': tempId,
      if (clientMutationId != null) 'clientMutationId': clientMutationId,
      'deleted': deleted,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SyncChange',
      'entityType': entityType,
      'entityJson': entityJson,
      'baseVersion': baseVersion,
      if (tempId != null) 'tempId': tempId,
      if (clientMutationId != null) 'clientMutationId': clientMutationId,
      'deleted': deleted,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncChangeImpl extends SyncChange {
  _SyncChangeImpl({
    required String entityType,
    required String entityJson,
    required int baseVersion,
    int? tempId,
    String? clientMutationId,
    bool? deleted,
  }) : super._(
         entityType: entityType,
         entityJson: entityJson,
         baseVersion: baseVersion,
         tempId: tempId,
         clientMutationId: clientMutationId,
         deleted: deleted,
       );

  /// Returns a shallow copy of this [SyncChange]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncChange copyWith({
    String? entityType,
    String? entityJson,
    int? baseVersion,
    Object? tempId = _Undefined,
    Object? clientMutationId = _Undefined,
    bool? deleted,
  }) {
    return SyncChange(
      entityType: entityType ?? this.entityType,
      entityJson: entityJson ?? this.entityJson,
      baseVersion: baseVersion ?? this.baseVersion,
      tempId: tempId is int? ? tempId : this.tempId,
      clientMutationId: clientMutationId is String?
          ? clientMutationId
          : this.clientMutationId,
      deleted: deleted ?? this.deleted,
    );
  }
}
