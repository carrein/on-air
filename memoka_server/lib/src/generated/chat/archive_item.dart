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
import '../chat/note.dart' as _i2;
import '../chat/channel.dart' as _i3;
import 'package:memoka_server/src/generated/protocol.dart' as _i4;

/// An item in the mixed archive list (note or channel).
abstract class ArchiveItem
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  ArchiveItem._({
    required this.type,
    this.note,
    this.channel,
    required this.archivedAt,
  });

  factory ArchiveItem({
    required String type,
    _i2.Note? note,
    _i3.Channel? channel,
    required DateTime archivedAt,
  }) = _ArchiveItemImpl;

  factory ArchiveItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return ArchiveItem(
      type: jsonSerialization['type'] as String,
      note: jsonSerialization['note'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Note>(jsonSerialization['note']),
      channel: jsonSerialization['channel'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.Channel>(
              jsonSerialization['channel'],
            ),
      archivedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['archivedAt'],
      ),
    );
  }

  /// The type of archive item: "note" or "channel".
  String type;

  /// The archived note (if type is "note").
  _i2.Note? note;

  /// The archived channel (if type is "channel").
  _i3.Channel? channel;

  /// When this item was archived, for chronological sorting.
  DateTime archivedAt;

  /// Returns a shallow copy of this [ArchiveItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ArchiveItem copyWith({
    String? type,
    _i2.Note? note,
    _i3.Channel? channel,
    DateTime? archivedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ArchiveItem',
      'type': type,
      if (note != null) 'note': note?.toJson(),
      if (channel != null) 'channel': channel?.toJson(),
      'archivedAt': archivedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ArchiveItem',
      'type': type,
      if (note != null) 'note': note?.toJsonForProtocol(),
      if (channel != null) 'channel': channel?.toJsonForProtocol(),
      'archivedAt': archivedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ArchiveItemImpl extends ArchiveItem {
  _ArchiveItemImpl({
    required String type,
    _i2.Note? note,
    _i3.Channel? channel,
    required DateTime archivedAt,
  }) : super._(
         type: type,
         note: note,
         channel: channel,
         archivedAt: archivedAt,
       );

  /// Returns a shallow copy of this [ArchiveItem]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ArchiveItem copyWith({
    String? type,
    Object? note = _Undefined,
    Object? channel = _Undefined,
    DateTime? archivedAt,
  }) {
    return ArchiveItem(
      type: type ?? this.type,
      note: note is _i2.Note? ? note : this.note?.copyWith(),
      channel: channel is _i3.Channel? ? channel : this.channel?.copyWith(),
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
