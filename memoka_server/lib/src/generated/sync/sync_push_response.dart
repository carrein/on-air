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
import '../sync/sync_result.dart' as _i2;
import 'package:memoka_server/src/generated/protocol.dart' as _i3;

/// Response from syncPush — results for each submitted change.
abstract class SyncPushResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SyncPushResponse._({
    required this.globalVersion,
    required this.results,
  });

  factory SyncPushResponse({
    required int globalVersion,
    required List<_i2.SyncResult> results,
  }) = _SyncPushResponseImpl;

  factory SyncPushResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPushResponse(
      globalVersion: jsonSerialization['globalVersion'] as int,
      results: _i3.Protocol().deserialize<List<_i2.SyncResult>>(
        jsonSerialization['results'],
      ),
    );
  }

  /// The current global version on the server after all applied changes.
  int globalVersion;

  /// Per-change results in the same order as the submitted changes.
  List<_i2.SyncResult> results;

  /// Returns a shallow copy of this [SyncPushResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPushResponse copyWith({
    int? globalVersion,
    List<_i2.SyncResult>? results,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncPushResponse',
      'globalVersion': globalVersion,
      'results': results.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SyncPushResponse',
      'globalVersion': globalVersion,
      'results': results.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncPushResponseImpl extends SyncPushResponse {
  _SyncPushResponseImpl({
    required int globalVersion,
    required List<_i2.SyncResult> results,
  }) : super._(
         globalVersion: globalVersion,
         results: results,
       );

  /// Returns a shallow copy of this [SyncPushResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPushResponse copyWith({
    int? globalVersion,
    List<_i2.SyncResult>? results,
  }) {
    return SyncPushResponse(
      globalVersion: globalVersion ?? this.globalVersion,
      results: results ?? this.results.map((e0) => e0.copyWith()).toList(),
    );
  }
}
