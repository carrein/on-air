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

/// A channel that contains notes.
abstract class Channel implements _i1.SerializableModel {
  Channel._({
    this.id,
    required this.name,
    String? emoji,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : emoji = emoji ?? '💬',
       pinned = pinned ?? false,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Channel({
    int? id,
    required String name,
    String? emoji,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ChannelImpl;

  factory Channel.fromJson(Map<String, dynamic> jsonSerialization) {
    return Channel(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      emoji: jsonSerialization['emoji'] as String?,
      pinned: jsonSerialization['pinned'] as bool?,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      updatedAt: jsonSerialization['updatedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['updatedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The name of the channel.
  String name;

  /// Emoji display picture for the channel.
  String emoji;

  /// Whether the channel is pinned.
  bool pinned;

  /// When the channel was created.
  DateTime createdAt;

  /// When the channel was last updated (e.g., when a note is posted).
  DateTime updatedAt;

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Channel copyWith({
    int? id,
    String? name,
    String? emoji,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'name': name,
      'emoji': emoji,
      'pinned': pinned,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChannelImpl extends Channel {
  _ChannelImpl({
    int? id,
    required String name,
    String? emoji,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super._(
         id: id,
         name: name,
         emoji: emoji,
         pinned: pinned,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Channel copyWith({
    Object? id = _Undefined,
    String? name,
    String? emoji,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Channel(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
