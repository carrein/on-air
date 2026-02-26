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
import '../chat/channel.dart' as _i2;
import '../chat/note.dart' as _i3;
import 'package:memoka_client/src/protocol/protocol.dart' as _i4;

/// Response from syncPull — all entities changed since sinceVersion.
abstract class SyncPullResponse implements _i1.SerializableModel {
  SyncPullResponse._({
    required this.globalVersion,
    required this.channels,
    required this.notes,
  });

  factory SyncPullResponse({
    required int globalVersion,
    required List<_i2.Channel> channels,
    required List<_i3.Note> notes,
  }) = _SyncPullResponseImpl;

  factory SyncPullResponse.fromJson(Map<String, dynamic> jsonSerialization) {
    return SyncPullResponse(
      globalVersion: jsonSerialization['globalVersion'] as int,
      channels: _i4.Protocol().deserialize<List<_i2.Channel>>(
        jsonSerialization['channels'],
      ),
      notes: _i4.Protocol().deserialize<List<_i3.Note>>(
        jsonSerialization['notes'],
      ),
    );
  }

  /// The current global version on the server at the time of the pull.
  int globalVersion;

  /// All channels with version > sinceVersion (includes archived, tombstoned).
  List<_i2.Channel> channels;

  /// All notes with version > sinceVersion (includes archived, tombstoned).
  List<_i3.Note> notes;

  /// Returns a shallow copy of this [SyncPullResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SyncPullResponse copyWith({
    int? globalVersion,
    List<_i2.Channel>? channels,
    List<_i3.Note>? notes,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SyncPullResponse',
      'globalVersion': globalVersion,
      'channels': channels.toJson(valueToJson: (v) => v.toJson()),
      'notes': notes.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SyncPullResponseImpl extends SyncPullResponse {
  _SyncPullResponseImpl({
    required int globalVersion,
    required List<_i2.Channel> channels,
    required List<_i3.Note> notes,
  }) : super._(
         globalVersion: globalVersion,
         channels: channels,
         notes: notes,
       );

  /// Returns a shallow copy of this [SyncPullResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SyncPullResponse copyWith({
    int? globalVersion,
    List<_i2.Channel>? channels,
    List<_i3.Note>? notes,
  }) {
    return SyncPullResponse(
      globalVersion: globalVersion ?? this.globalVersion,
      channels: channels ?? this.channels.map((e0) => e0.copyWith()).toList(),
      notes: notes ?? this.notes.map((e0) => e0.copyWith()).toList(),
    );
  }
}
