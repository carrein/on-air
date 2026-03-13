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

/// A page watch entry for monitoring URL content changes.
abstract class PageWatch implements _i1.SerializableModel {
  PageWatch._({
    required this.noteId,
    required this.channelId,
    required this.url,
    this.contentHash,
    this.lastCheckedAt,
    bool? enabled,
    int? consecutiveFailures,
    this.lastError,
    bool? hasUnacknowledgedChange,
    required this.createdAt,
    required this.updatedAt,
  }) : enabled = enabled ?? true,
       consecutiveFailures = consecutiveFailures ?? 0,
       hasUnacknowledgedChange = hasUnacknowledgedChange ?? false;

  factory PageWatch({
    required int noteId,
    required int channelId,
    required String url,
    String? contentHash,
    DateTime? lastCheckedAt,
    bool? enabled,
    int? consecutiveFailures,
    String? lastError,
    bool? hasUnacknowledgedChange,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PageWatchImpl;

  factory PageWatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return PageWatch(
      noteId: jsonSerialization['noteId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      url: jsonSerialization['url'] as String,
      contentHash: jsonSerialization['contentHash'] as String?,
      lastCheckedAt: jsonSerialization['lastCheckedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastCheckedAt'],
            ),
      enabled: jsonSerialization['enabled'] as bool?,
      consecutiveFailures: jsonSerialization['consecutiveFailures'] as int?,
      lastError: jsonSerialization['lastError'] as String?,
      hasUnacknowledgedChange:
          jsonSerialization['hasUnacknowledgedChange'] as bool?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The note ID this watch is attached to.
  int noteId;

  /// The channel ID the note belongs to.
  int channelId;

  /// The URL being watched.
  String url;

  /// SHA-256 hash of extracted visible text (null on first check).
  String? contentHash;

  /// When the URL was last checked.
  DateTime? lastCheckedAt;

  /// Whether this watch is active.
  bool enabled;

  /// Number of consecutive fetch failures.
  int consecutiveFailures;

  /// Last error message (null if no error).
  String? lastError;

  /// Whether there is an unacknowledged content change.
  bool hasUnacknowledgedChange;

  /// When this watch was created.
  DateTime createdAt;

  /// When this watch was last updated.
  DateTime updatedAt;

  /// Returns a shallow copy of this [PageWatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PageWatch copyWith({
    int? noteId,
    int? channelId,
    String? url,
    String? contentHash,
    DateTime? lastCheckedAt,
    bool? enabled,
    int? consecutiveFailures,
    String? lastError,
    bool? hasUnacknowledgedChange,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PageWatch',
      'noteId': noteId,
      'channelId': channelId,
      'url': url,
      if (contentHash != null) 'contentHash': contentHash,
      if (lastCheckedAt != null) 'lastCheckedAt': lastCheckedAt?.toJson(),
      'enabled': enabled,
      'consecutiveFailures': consecutiveFailures,
      if (lastError != null) 'lastError': lastError,
      'hasUnacknowledgedChange': hasUnacknowledgedChange,
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

class _PageWatchImpl extends PageWatch {
  _PageWatchImpl({
    required int noteId,
    required int channelId,
    required String url,
    String? contentHash,
    DateTime? lastCheckedAt,
    bool? enabled,
    int? consecutiveFailures,
    String? lastError,
    bool? hasUnacknowledgedChange,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         noteId: noteId,
         channelId: channelId,
         url: url,
         contentHash: contentHash,
         lastCheckedAt: lastCheckedAt,
         enabled: enabled,
         consecutiveFailures: consecutiveFailures,
         lastError: lastError,
         hasUnacknowledgedChange: hasUnacknowledgedChange,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [PageWatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PageWatch copyWith({
    int? noteId,
    int? channelId,
    String? url,
    Object? contentHash = _Undefined,
    Object? lastCheckedAt = _Undefined,
    bool? enabled,
    int? consecutiveFailures,
    Object? lastError = _Undefined,
    bool? hasUnacknowledgedChange,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PageWatch(
      noteId: noteId ?? this.noteId,
      channelId: channelId ?? this.channelId,
      url: url ?? this.url,
      contentHash: contentHash is String? ? contentHash : this.contentHash,
      lastCheckedAt: lastCheckedAt is DateTime?
          ? lastCheckedAt
          : this.lastCheckedAt,
      enabled: enabled ?? this.enabled,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastError: lastError is String? ? lastError : this.lastError,
      hasUnacknowledgedChange:
          hasUnacknowledgedChange ?? this.hasUnacknowledgedChange,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
