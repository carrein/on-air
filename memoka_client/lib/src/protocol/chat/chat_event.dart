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
import '../chat/note.dart' as _i2;
import '../chat/channel.dart' as _i3;
import 'package:memoka_client/src/protocol/protocol.dart' as _i4;

/// An event broadcasted over WebSocket for real-time updates.
abstract class ChatEvent implements _i1.SerializableModel {
  ChatEvent._({
    required this.type,
    this.note,
    this.noteId,
    this.channelId,
    this.channel,
  });

  factory ChatEvent({
    required String type,
    _i2.Note? note,
    int? noteId,
    int? channelId,
    _i3.Channel? channel,
  }) = _ChatEventImpl;

  factory ChatEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChatEvent(
      type: jsonSerialization['type'] as String,
      note: jsonSerialization['note'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Note>(jsonSerialization['note']),
      noteId: jsonSerialization['noteId'] as int?,
      channelId: jsonSerialization['channelId'] as int?,
      channel: jsonSerialization['channel'] == null
          ? null
          : _i4.Protocol().deserialize<_i3.Channel>(
              jsonSerialization['channel'],
            ),
    );
  }

  /// The type of event: noteCreated, noteUpdated, noteDeleted, noteLinkPreviewReady, channelCreated, channelDeleted.
  String type;

  /// The note data for noteCreated and noteUpdated events.
  _i2.Note? note;

  /// The note ID for noteDeleted events.
  int? noteId;

  /// The channel ID for noteDeleted and channelDeleted events.
  int? channelId;

  /// The channel data for channelCreated events.
  _i3.Channel? channel;

  /// Returns a shallow copy of this [ChatEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChatEvent copyWith({
    String? type,
    _i2.Note? note,
    int? noteId,
    int? channelId,
    _i3.Channel? channel,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChatEvent',
      'type': type,
      if (note != null) 'note': note?.toJson(),
      if (noteId != null) 'noteId': noteId,
      if (channelId != null) 'channelId': channelId,
      if (channel != null) 'channel': channel?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChatEventImpl extends ChatEvent {
  _ChatEventImpl({
    required String type,
    _i2.Note? note,
    int? noteId,
    int? channelId,
    _i3.Channel? channel,
  }) : super._(
         type: type,
         note: note,
         noteId: noteId,
         channelId: channelId,
         channel: channel,
       );

  /// Returns a shallow copy of this [ChatEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChatEvent copyWith({
    String? type,
    Object? note = _Undefined,
    Object? noteId = _Undefined,
    Object? channelId = _Undefined,
    Object? channel = _Undefined,
  }) {
    return ChatEvent(
      type: type ?? this.type,
      note: note is _i2.Note? ? note : this.note?.copyWith(),
      noteId: noteId is int? ? noteId : this.noteId,
      channelId: channelId is int? ? channelId : this.channelId,
      channel: channel is _i3.Channel? ? channel : this.channel?.copyWith(),
    );
  }
}
