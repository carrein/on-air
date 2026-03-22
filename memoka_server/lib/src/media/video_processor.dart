import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

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

/// Parameters for video processing in isolate.
class _ProcessVideoParams {
  final String tempFilePath;
  final String finalFilePath;
  final String channelDir;

  _ProcessVideoParams({
    required this.tempFilePath,
    required this.finalFilePath,
    required this.channelDir,
  });
}

/// Video processor for handling thumbnail generation and metadata extraction.
///
/// Requires ffmpeg to be installed on the system.
class VideoProcessor {
  static const int thumbnailSize = 720;

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
    final params = _ProcessVideoParams(
      tempFilePath: tempFilePath,
      finalFilePath: finalFilePath,
      channelDir: channelDir,
    );

    return await _processInIsolate(params);
  }

  /// Actual processing logic (runs in isolate).
  static Future<ProcessedVideoResult> _processInIsolate(
    _ProcessVideoParams params,
  ) async {
    final tempFile = File(params.tempFilePath);
    final bytes = await tempFile.readAsBytes();

    // Calculate content hash
    final hash = sha256.convert(bytes);
    final contentHash = hash.toString().substring(0, 8);

    // Check if ffmpeg is available
    final ffmpegAvailable = await _checkFfmpegAvailable();
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

  /// Check if ffmpeg is available on the system.
  static Future<bool> _checkFfmpegAvailable() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
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

  /// Generate thumbnail from video (first frame).
  static Future<String?> _generateThumbnail(
    String videoPath,
    String channelDir,
    String baseName,
  ) async {
    try {
      // Create thumbnails directory
      final thumbnailDir = Directory(path.join(channelDir, 'thumbnails'));
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      // Extract frame at 1 second (or first frame if video is shorter)
      final thumbnailPath = path.join(
        thumbnailDir.path,
        '${baseName}_thumb.jpg',
      );

      final result = await Process.run('ffmpeg', [
        '-i',
        videoPath,
        '-ss',
        '00:00:01',
        '-vframes',
        '1',
        '-vf',
        'scale=$thumbnailSize:$thumbnailSize:force_original_aspect_ratio=decrease',
        '-y',
        thumbnailPath,
      ]);

      if (result.exitCode != 0) {
        return null;
      }

      // Return relative path from channel directory
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
