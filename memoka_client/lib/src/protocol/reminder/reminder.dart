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

/// A reminder entry for time-based note notifications.
abstract class Reminder implements _i1.SerializableModel {
  Reminder._({
    required this.noteId,
    required this.channelId,
    required this.scheduledAt,
    this.noteContent,
    required this.fired,
    required this.createdAt,
    this.recurrenceRule,
    this.recurrenceEndAt,
  });

  factory Reminder({
    required int noteId,
    required int channelId,
    required DateTime scheduledAt,
    String? noteContent,
    required bool fired,
    required DateTime createdAt,
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) = _ReminderImpl;

  factory Reminder.fromJson(Map<String, dynamic> jsonSerialization) {
    return Reminder(
      noteId: jsonSerialization['noteId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      scheduledAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['scheduledAt'],
      ),
      noteContent: jsonSerialization['noteContent'] as String?,
      fired: jsonSerialization['fired'] as bool,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      recurrenceRule: jsonSerialization['recurrenceRule'] as String?,
      recurrenceEndAt: jsonSerialization['recurrenceEndAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['recurrenceEndAt'],
            ),
    );
  }

  /// The note ID this reminder is attached to.
  int noteId;

  /// The channel ID the note belongs to.
  int channelId;

  /// When the reminder should fire.
  DateTime scheduledAt;

  /// Cached note content for notification body.
  String? noteContent;

  /// Whether the reminder has fired.
  bool fired;

  /// When this reminder was created.
  DateTime createdAt;

  /// RRULE recurrence rule (null = one-shot).
  String? recurrenceRule;

  /// When the recurrence series ends (null = forever).
  DateTime? recurrenceEndAt;

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Reminder copyWith({
    int? noteId,
    int? channelId,
    DateTime? scheduledAt,
    String? noteContent,
    bool? fired,
    DateTime? createdAt,
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Reminder',
      'noteId': noteId,
      'channelId': channelId,
      'scheduledAt': scheduledAt.toJson(),
      if (noteContent != null) 'noteContent': noteContent,
      'fired': fired,
      'createdAt': createdAt.toJson(),
      if (recurrenceRule != null) 'recurrenceRule': recurrenceRule,
      if (recurrenceEndAt != null) 'recurrenceEndAt': recurrenceEndAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReminderImpl extends Reminder {
  _ReminderImpl({
    required int noteId,
    required int channelId,
    required DateTime scheduledAt,
    String? noteContent,
    required bool fired,
    required DateTime createdAt,
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) : super._(
         noteId: noteId,
         channelId: channelId,
         scheduledAt: scheduledAt,
         noteContent: noteContent,
         fired: fired,
         createdAt: createdAt,
         recurrenceRule: recurrenceRule,
         recurrenceEndAt: recurrenceEndAt,
       );

  /// Returns a shallow copy of this [Reminder]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Reminder copyWith({
    int? noteId,
    int? channelId,
    DateTime? scheduledAt,
    Object? noteContent = _Undefined,
    bool? fired,
    DateTime? createdAt,
    Object? recurrenceRule = _Undefined,
    Object? recurrenceEndAt = _Undefined,
  }) {
    return Reminder(
      noteId: noteId ?? this.noteId,
      channelId: channelId ?? this.channelId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      noteContent: noteContent is String? ? noteContent : this.noteContent,
      fired: fired ?? this.fired,
      createdAt: createdAt ?? this.createdAt,
      recurrenceRule: recurrenceRule is String?
          ? recurrenceRule
          : this.recurrenceRule,
      recurrenceEndAt: recurrenceEndAt is DateTime?
          ? recurrenceEndAt
          : this.recurrenceEndAt,
    );
  }
}
