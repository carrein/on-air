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

/// Progress snapshot for an in-flight thumbnail regeneration job.
/// Returned by settings.getRegenProgress().
abstract class ThumbnailRegenProgress implements _i1.SerializableModel {
  ThumbnailRegenProgress._({
    required this.total,
    required this.processed,
    required this.failed,
    required this.isRunning,
  });

  factory ThumbnailRegenProgress({
    required int total,
    required int processed,
    required int failed,
    required bool isRunning,
  }) = _ThumbnailRegenProgressImpl;

  factory ThumbnailRegenProgress.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ThumbnailRegenProgress(
      total: jsonSerialization['total'] as int,
      processed: jsonSerialization['processed'] as int,
      failed: jsonSerialization['failed'] as int,
      isRunning: jsonSerialization['isRunning'] as bool,
    );
  }

  /// Total number of attachments to process.
  int total;

  /// Number successfully regenerated so far.
  int processed;

  /// Number that failed (ffmpeg error or missing source file).
  int failed;

  /// True while the background job is still running.
  bool isRunning;

  /// Returns a shallow copy of this [ThumbnailRegenProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ThumbnailRegenProgress copyWith({
    int? total,
    int? processed,
    int? failed,
    bool? isRunning,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ThumbnailRegenProgress',
      'total': total,
      'processed': processed,
      'failed': failed,
      'isRunning': isRunning,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ThumbnailRegenProgressImpl extends ThumbnailRegenProgress {
  _ThumbnailRegenProgressImpl({
    required int total,
    required int processed,
    required int failed,
    required bool isRunning,
  }) : super._(
         total: total,
         processed: processed,
         failed: failed,
         isRunning: isRunning,
       );

  /// Returns a shallow copy of this [ThumbnailRegenProgress]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ThumbnailRegenProgress copyWith({
    int? total,
    int? processed,
    int? failed,
    bool? isRunning,
  }) {
    return ThumbnailRegenProgress(
      total: total ?? this.total,
      processed: processed ?? this.processed,
      failed: failed ?? this.failed,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}
