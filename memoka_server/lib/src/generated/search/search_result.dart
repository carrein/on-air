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

/// A search result returned by the search endpoint.
abstract class SearchResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  SearchResult._({
    required this.noteId,
    required this.channelId,
    required this.channelName,
    required this.channelEmoji,
    required this.snippet,
    required this.createdAt,
    required this.score,
  });

  factory SearchResult({
    required int noteId,
    required int channelId,
    required String channelName,
    required String channelEmoji,
    required String snippet,
    required DateTime createdAt,
    required double score,
  }) = _SearchResultImpl;

  factory SearchResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchResult(
      noteId: jsonSerialization['noteId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      channelName: jsonSerialization['channelName'] as String,
      channelEmoji: jsonSerialization['channelEmoji'] as String,
      snippet: jsonSerialization['snippet'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      score: (jsonSerialization['score'] as num).toDouble(),
    );
  }

  /// The ID of the matching note.
  int noteId;

  /// The channel ID the note belongs to.
  int channelId;

  /// The name of the channel.
  String channelName;

  /// The emoji identifier of the channel.
  String channelEmoji;

  /// A snippet of the note content with <b> tags highlighting matches.
  String snippet;

  /// When the note was created.
  DateTime createdAt;

  /// The relevance score (higher is better).
  double score;

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchResult copyWith({
    int? noteId,
    int? channelId,
    String? channelName,
    String? channelEmoji,
    String? snippet,
    DateTime? createdAt,
    double? score,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchResult',
      'noteId': noteId,
      'channelId': channelId,
      'channelName': channelName,
      'channelEmoji': channelEmoji,
      'snippet': snippet,
      'createdAt': createdAt.toJson(),
      'score': score,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'SearchResult',
      'noteId': noteId,
      'channelId': channelId,
      'channelName': channelName,
      'channelEmoji': channelEmoji,
      'snippet': snippet,
      'createdAt': createdAt.toJson(),
      'score': score,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SearchResultImpl extends SearchResult {
  _SearchResultImpl({
    required int noteId,
    required int channelId,
    required String channelName,
    required String channelEmoji,
    required String snippet,
    required DateTime createdAt,
    required double score,
  }) : super._(
         noteId: noteId,
         channelId: channelId,
         channelName: channelName,
         channelEmoji: channelEmoji,
         snippet: snippet,
         createdAt: createdAt,
         score: score,
       );

  /// Returns a shallow copy of this [SearchResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchResult copyWith({
    int? noteId,
    int? channelId,
    String? channelName,
    String? channelEmoji,
    String? snippet,
    DateTime? createdAt,
    double? score,
  }) {
    return SearchResult(
      noteId: noteId ?? this.noteId,
      channelId: channelId ?? this.channelId,
      channelName: channelName ?? this.channelName,
      channelEmoji: channelEmoji ?? this.channelEmoji,
      snippet: snippet ?? this.snippet,
      createdAt: createdAt ?? this.createdAt,
      score: score ?? this.score,
    );
  }
}
