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
import '../chat/link_preview.dart' as _i2;
import '../media/media_attachment.dart' as _i3;
import 'package:memoka_client/src/protocol/protocol.dart' as _i4;

/// A note within a channel.
abstract class Note implements _i1.SerializableModel {
  Note._({
    this.id,
    required this.channelId,
    required this.content,
    this.linkPreview,
    this.attachments,
    bool? archived,
    this.archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.clientMutationId,
  }) : archived = archived ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Note({
    int? id,
    required int channelId,
    required String content,
    _i2.LinkPreview? linkPreview,
    List<_i3.MediaAttachment>? attachments,
    bool? archived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientMutationId,
  }) = _NoteImpl;

  factory Note.fromJson(Map<String, dynamic> jsonSerialization) {
    return Note(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      content: jsonSerialization['content'] as String,
      linkPreview: jsonSerialization['linkPreview'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.LinkPreview>(
              jsonSerialization['linkPreview'],
            ),
      attachments: jsonSerialization['attachments'] == null
          ? null
          : _i4.Protocol().deserialize<List<_i3.MediaAttachment>>(
              jsonSerialization['attachments'],
            ),
      archived: jsonSerialization['archived'] as bool?,
      archivedAt: jsonSerialization['archivedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['archivedAt']),
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
      clientMutationId: jsonSerialization['clientMutationId'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The ID of the channel this note belongs to.
  int channelId;

  /// The content of the note.
  String content;

  /// Link preview metadata (if URL detected in content).
  _i2.LinkPreview? linkPreview;

  /// Media attachments associated with this note.
  List<_i3.MediaAttachment>? attachments;

  /// Whether this note has been archived (soft-deleted).
  bool archived;

  /// When the note was archived.
  DateTime? archivedAt;

  /// When the note was created.
  DateTime createdAt;

  /// When the note was last updated.
  DateTime updatedAt;

  /// Idempotency key for offline-created notes. NULL for online-created notes.
  String? clientMutationId;

  /// Returns a shallow copy of this [Note]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Note copyWith({
    int? id,
    int? channelId,
    String? content,
    _i2.LinkPreview? linkPreview,
    List<_i3.MediaAttachment>? attachments,
    bool? archived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientMutationId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Note',
      if (id != null) 'id': id,
      'channelId': channelId,
      'content': content,
      if (linkPreview != null) 'linkPreview': linkPreview?.toJson(),
      if (attachments != null)
        'attachments': attachments?.toJson(valueToJson: (v) => v.toJson()),
      'archived': archived,
      if (archivedAt != null) 'archivedAt': archivedAt?.toJson(),
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (clientMutationId != null) 'clientMutationId': clientMutationId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NoteImpl extends Note {
  _NoteImpl({
    int? id,
    required int channelId,
    required String content,
    _i2.LinkPreview? linkPreview,
    List<_i3.MediaAttachment>? attachments,
    bool? archived,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientMutationId,
  }) : super._(
         id: id,
         channelId: channelId,
         content: content,
         linkPreview: linkPreview,
         attachments: attachments,
         archived: archived,
         archivedAt: archivedAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
         clientMutationId: clientMutationId,
       );

  /// Returns a shallow copy of this [Note]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Note copyWith({
    Object? id = _Undefined,
    int? channelId,
    String? content,
    Object? linkPreview = _Undefined,
    Object? attachments = _Undefined,
    bool? archived,
    Object? archivedAt = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? clientMutationId = _Undefined,
  }) {
    return Note(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      content: content ?? this.content,
      linkPreview: linkPreview is _i2.LinkPreview?
          ? linkPreview
          : this.linkPreview?.copyWith(),
      attachments: attachments is List<_i3.MediaAttachment>?
          ? attachments
          : this.attachments?.map((e0) => e0.copyWith()).toList(),
      archived: archived ?? this.archived,
      archivedAt: archivedAt is DateTime? ? archivedAt : this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientMutationId: clientMutationId is String?
          ? clientMutationId
          : this.clientMutationId,
    );
  }
}
