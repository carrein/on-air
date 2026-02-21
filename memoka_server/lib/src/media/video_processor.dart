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

  /// Whether the video was compressed.
  final bool compressed;

  ProcessedVideoResult({
    required this.filePath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.duration,
    required this.contentHash,
    required this.compressed,
  });
}

/// Parameters for video processing in isolate.
class _ProcessVideoParams {
  final String tempFilePath;
  final String finalFilePath;
  final String channelDir;
  final bool compress;

  _ProcessVideoParams({
    required this.tempFilePath,
    required this.finalFilePath,
    required this.channelDir,
    required this.compress,
  });
}

/// Video processor for handling compression and thumbnail generation.
///
/// Requires ffmpeg to be installed on the system.
class VideoProcessor {
  static const int maxWidth = 1280;
  static const int maxHeight = 720;
  static const int thumbnailSize = 720;

  /// Calculate SHA-256 hash of file bytes (first 8 characters).
  /// Used for cache busting.
  static Future<String> calculateHash(List<int> bytes) async {
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  /// Process a video file with optional compression.
  ///
  /// Handles compression, thumbnail generation, and content hashing.
  /// Requires ffmpeg to be installed.
  static Future<ProcessedVideoResult> processVideo({
    required String tempFilePath,
    required String finalFilePath,
    required String channelDir,
    required bool compress,
  }) async {
    final params = _ProcessVideoParams(
      tempFilePath: tempFilePath,
      finalFilePath: finalFilePath,
      channelDir: channelDir,
      compress: compress,
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
        compressed: false,
      );
    }

    // Get video metadata (resolution, duration)
    final metadata = await _getVideoMetadata(params.tempFilePath);

    bool wasCompressed = false;
    String resultFilePath = params.finalFilePath;

    // Compress if requested and video is larger than target
    if (params.compress &&
        metadata != null &&
        (metadata.width > maxWidth || metadata.height > maxHeight)) {
      resultFilePath = await _compressVideo(
        params.tempFilePath,
        params.finalFilePath,
        metadata,
      );
      wasCompressed = true;

      // Delete temp file after compression
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } else {
      // No compression, just rename
      await tempFile.rename(params.finalFilePath);
    }

    // Generate thumbnail
    final thumbnailPath = await _generateThumbnail(
      resultFilePath,
      params.channelDir,
      path.basenameWithoutExtension(params.finalFilePath),
    );

    return ProcessedVideoResult(
      filePath: resultFilePath,
      thumbnailPath: thumbnailPath,
      width: metadata?.width,
      height: metadata?.height,
      duration: metadata?.duration,
      contentHash: contentHash,
      compressed: wasCompressed,
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

  /// Compress video using ffmpeg.
  static Future<String> _compressVideo(
    String inputPath,
    String outputPath,
    _VideoMetadata metadata,
  ) async {
    // Calculate new dimensions maintaining aspect ratio
    final aspectRatio = metadata.width / metadata.height;
    int newWidth, newHeight;

    if (metadata.width > metadata.height) {
      newWidth = maxWidth;
      newHeight = (maxWidth / aspectRatio).round();
    } else {
      newHeight = maxHeight;
      newWidth = (maxHeight * aspectRatio).round();
    }

    // Ensure dimensions are even (required by H.264)
    if (newWidth % 2 != 0) newWidth--;
    if (newHeight % 2 != 0) newHeight--;

    // Compress using H.264 codec
    final result = await Process.run('ffmpeg', [
      '-i',
      inputPath,
      '-vf',
      'scale=$newWidth:$newHeight',
      '-c:v',
      'libx264',
      '-preset',
      'medium',
      '-crf',
      '23',
      '-c:a',
      'aac',
      '-b:a',
      '128k',
      '-y',
      outputPath,
    ]);

    if (result.exitCode != 0) {
      throw Exception('ffmpeg compression failed: ${result.stderr}');
    }

    return outputPath;
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
