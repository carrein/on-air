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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// Result for a single entity change from syncPush.
abstract class SyncResult implements _i1.SerializableModel {
  SyncResult._({
    required this.status,
    this.reason,
    this.tempId,
    this.serverId,
    required this.entityType,
    this.entityJson,
  });

  factory SyncResult({
    required String status,
    String? reason,
    String? tempId,
    int? serverId,
    required String entityType,
    String? entityJson,
  }) = _SyncResultImpl;

  factory SyncResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncResult(
      status: jsonSerialization['status'] as String,
      reason: jsonSerialization['reason'] as String?,
      tempId: jsonSerialization['tempId'] as String?,
      serverId: jsonSerialization['serverId'] as int?,
      entityType: jsonSerialization['entityType'] as String,
      entityJson: jsonSerialization['entityJson'] as String?,
    );
  }

  /// "applied", "rejected", or "already_applied".
  String status;

  /// Human-readable reason for rejection. Null if applied.
  String? reason;

  /// Client temp ID (echoed back for create mapping). Null for updates/deletes.
  String? tempId;

  /// Server-assigned ID (for creates). Null for updates/deletes.
  int? serverId;

  /// Entity type: "channel" or "note".
  String entityType;

  /// Current server entity JSON. Set on rejection so client can accept server state.
  String? entityJson;

  /// Returns a shallow copy of this [SyncResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncResult copyWith({
    String? status,
    String? reason,
    String? tempId,
    int? serverId,
    String? entityType,
    String? entityJson,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncResult',
      'status': status,
      if (reason != null) 'reason': reason,
      if (tempId != null) 'tempId': tempId,
      if (serverId != null) 'serverId': serverId,
      'entityType': entityType,
      if (entityJson != null) 'entityJson': entityJson,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SyncResultImpl extends SyncResult {
  _SyncResultImpl({
    required String status,
    String? reason,
    String? tempId,
    int? serverId,
    required String entityType,
    String? entityJson,
  }) : super._(
         status: status,
         reason: reason,
         tempId: tempId,
         serverId: serverId,
         entityType: entityType,
         entityJson: entityJson,
       );

  /// Returns a shallow copy of this [SyncResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncResult copyWith({
    String? status,
    Object? reason = _Undefined,
    Object? tempId = _Undefined,
    Object? serverId = _Undefined,
    String? entityType,
    Object? entityJson = _Undefined,
  }) {
    return SyncResult(
      status: status ?? this.status,
      reason: reason is String? ? reason : this.reason,
      tempId: tempId is String? ? tempId : this.tempId,
      serverId: serverId is int? ? serverId : this.serverId,
      entityType: entityType ?? this.entityType,
      entityJson: entityJson is String? ? entityJson : this.entityJson,
    );
  }
}
