import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'ffmpeg_utils.dart';
import 'hash_utils.dart';
import 'process_params.dart';

/// Result of video processing.
class ProcessedVideoResult {
  /// Path to the final processed video file.
  final String filePath;

  /// Path to the thumbnail image (if generated).
  final String? thumbnailPath;

  /// Video width in pixels.
  final int? width;

  /// Video height in pixels.
  final int? height;

  /// Video duration in seconds.
  final double? duration;

  /// Content hash (first 8 chars of SHA-256).
  final String contentHash;

  ProcessedVideoResult({
    required this.filePath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.duration,
    required this.contentHash,
  });
}

/// Video processor for handling thumbnail generation and metadata extraction.
///
/// Requires ffmpeg to be installed on the system.
class VideoProcessor {
  /// Calculate SHA-256 hash of file bytes (first 8 characters).
  /// Used for cache busting.
  static Future<String> calculateHash(List<int> bytes) async {
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  /// Process a video file.
  ///
  /// Handles thumbnail generation, metadata extraction, and content hashing.
  /// Requires ffmpeg to be installed.
  static Future<ProcessedVideoResult> processVideo({
    required String tempFilePath,
    required String finalFilePath,
    required String channelDir,
  }) async {
    final params = ProcessFileParams(
      tempFilePath: tempFilePath,
      finalFilePath: finalFilePath,
      channelDir: channelDir,
    );

    return await _processFile(params);
  }

  /// Processes the file: hashes, extracts metadata, generates thumbnail.
  static Future<ProcessedVideoResult> _processFile(
    ProcessFileParams params,
  ) async {
    final tempFile = File(params.tempFilePath);

    // Calculate content hash via streaming (avoids loading entire file into memory)
    final contentHash = await computeFileHash(params.tempFilePath);

    // Check if ffmpeg is available
    final ffmpegAvailable = await FfmpegUtils.checkAvailable();
    if (!ffmpegAvailable) {
      // If ffmpeg is not available, skip processing
      await tempFile.rename(params.finalFilePath);
      return ProcessedVideoResult(
        filePath: params.finalFilePath,
        thumbnailPath: null,
        width: null,
        height: null,
        duration: null,
        contentHash: contentHash,
      );
    }

    // Get video metadata (resolution, duration)
    final metadata = await _getVideoMetadata(params.tempFilePath);

    // Move to final path
    await tempFile.rename(params.finalFilePath);

    // Generate thumbnail
    final thumbnailPath = await _generateThumbnail(
      params.finalFilePath,
      params.channelDir,
      path.basenameWithoutExtension(params.finalFilePath),
    );

    return ProcessedVideoResult(
      filePath: params.finalFilePath,
      thumbnailPath: thumbnailPath,
      width: metadata?.width,
      height: metadata?.height,
      duration: metadata?.duration,
      contentHash: contentHash,
    );
  }

  /// Get video metadata using ffprobe.
  static Future<_VideoMetadata?> _getVideoMetadata(String videoPath) async {
    try {
      final result = await Process.run('ffprobe', [
        '-v',
        'error',
        '-select_streams',
        'v:0',
        '-show_entries',
        'stream=width,height,duration',
        '-of',
        'default=noprint_wrappers=1',
        videoPath,
      ]);

      if (result.exitCode != 0) {
        return null;
      }

      final output = result.stdout.toString();
      final lines = output.split('\n');

      int? width;
      int? height;
      double? duration;

      for (final line in lines) {
        if (line.startsWith('width=')) {
          width = int.tryParse(line.substring(6));
        } else if (line.startsWith('height=')) {
          height = int.tryParse(line.substring(7));
        } else if (line.startsWith('duration=')) {
          duration = double.tryParse(line.substring(9));
        }
      }

      if (width == null || height == null) {
        return null;
      }

      return _VideoMetadata(
        width: width,
        height: height,
        duration: duration,
      );
    } catch (_) {
      return null;
    }
  }

  /// Generate thumbnail from video (lossless WebP at 1200px longest side).
  static Future<String?> _generateThumbnail(
    String videoPath,
    String channelDir,
    String baseName,
  ) async {
    try {
      final thumbnailDir = Directory(path.join(channelDir, 'thumbnails'));
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final thumbnailPath = path.join(
        thumbnailDir.path,
        '${baseName}_thumb.webp',
      );

      final size = FfmpegUtils.thumbnailSize;
      final result = await Process.run('ffmpeg', [
        '-i',
        videoPath,
        '-ss',
        '00:00:01',
        '-vframes',
        '1',
        '-vf',
        'scale=$size:$size:force_original_aspect_ratio=decrease',
        '-lossless',
        '1',
        '-compression_level',
        '${FfmpegUtils.thumbnailCompressionLevel}',
        '-y',
        thumbnailPath,
      ]);

      if (result.exitCode != 0) {
        return null;
      }

      return path.relative(thumbnailPath, from: channelDir);
    } catch (_) {
      return null;
    }
  }
}

/// Video metadata.
class _VideoMetadata {
  final int width;
  final int height;
  final double? duration;

  _VideoMetadata({
    required this.width,
    required this.height,
    required this.duration,
  });
}
