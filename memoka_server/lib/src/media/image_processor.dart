import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

/// Result of image processing.
class ProcessedImageResult {
  /// Path to the final processed image file.
  final String filePath;

  /// Path to the thumbnail image (if generated).
  final String? thumbnailPath;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Content hash (first 8 chars of SHA-256).
  final String contentHash;

  /// Whether the image was compressed.
  final bool compressed;

  /// Whether the image is animated.
  final bool animated;

  ProcessedImageResult({
    required this.filePath,
    required this.thumbnailPath,
    required this.width,
    required this.height,
    required this.contentHash,
    required this.compressed,
    required this.animated,
  });
}

/// Parameters for image processing in isolate.
class _ProcessImageParams {
  final String tempFilePath;
  final String finalFilePath;
  final String channelDir;
  final bool compress;

  _ProcessImageParams({
    required this.tempFilePath,
    required this.finalFilePath,
    required this.channelDir,
    required this.compress,
  });
}

/// Image processor for handling compression, thumbnails, and metadata.
class ImageProcessor {
  static const int maxDimension = 1920;
  static const int thumbnailSize = 300;
  static const int compressionQuality = 85;
  static const int thumbnailQuality = 80;

  /// Calculate SHA-256 hash of file bytes (first 8 characters).
  /// Used for cache busting.
  static Future<String> calculateHash(List<int> bytes) async {
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  /// Process an image file with optional compression.
  ///
  /// Runs in an isolate to avoid blocking the main thread.
  /// Handles EXIF orientation, compression, thumbnail generation, and content hashing.
  static Future<ProcessedImageResult> processImage({
    required String tempFilePath,
    required String finalFilePath,
    required String channelDir,
    required bool compress,
  }) async {
    // Run processing in a separate isolate
    final params = _ProcessImageParams(
      tempFilePath: tempFilePath,
      finalFilePath: finalFilePath,
      channelDir: channelDir,
      compress: compress,
    );

    return await _processInIsolate(params);
  }

  /// Actual processing logic (runs in isolate).
  static Future<ProcessedImageResult> _processInIsolate(
    _ProcessImageParams params,
  ) async {
    final tempFile = File(params.tempFilePath);
    final bytes = await tempFile.readAsBytes();

    // Calculate content hash
    final hash = sha256.convert(bytes);
    final contentHash = hash.toString().substring(0, 8);

    // Decode image
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Check if animated (GIF with multiple frames)
    final isAnimated = image.numFrames > 1;

    // Apply EXIF orientation BEFORE stripping metadata
    image = img.bakeOrientation(image);

    final originalWidth = image.width;
    final originalHeight = image.height;

    bool wasCompressed = false;
    String? thumbnailPath;

    if (isAnimated) {
      // For animated GIFs, preserve the original file
      await tempFile.rename(params.finalFilePath);

      // Generate static thumbnail from first frame
      final firstFrame = image.frames.first;
      thumbnailPath = await _generateThumbnail(
        firstFrame,
        params.channelDir,
        path.basenameWithoutExtension(params.finalFilePath),
      );
    } else {
      // Strip EXIF metadata after applying orientation
      image.exif.clear();

      // Compress if requested
      if (params.compress) {
        image = _compressImage(image);
        wasCompressed = true;
      }

      // Save processed image as JPEG (WebP encoding not available in this version)
      final jpegBytes = img.encodeJpg(
        image,
        quality: compressionQuality,
      );
      await File(params.finalFilePath).writeAsBytes(jpegBytes);

      // Delete temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Generate thumbnail
      thumbnailPath = await _generateThumbnail(
        image,
        params.channelDir,
        path.basenameWithoutExtension(params.finalFilePath),
      );
    }

    return ProcessedImageResult(
      filePath: params.finalFilePath,
      thumbnailPath: thumbnailPath,
      width: originalWidth,
      height: originalHeight,
      contentHash: contentHash,
      compressed: wasCompressed,
      animated: isAnimated,
    );
  }

  /// Compress image to max dimension while maintaining aspect ratio.
  static img.Image _compressImage(img.Image image) {
    if (image.width <= maxDimension && image.height <= maxDimension) {
      return image;
    }

    // Calculate new dimensions maintaining aspect ratio
    final aspectRatio = image.width / image.height;
    int newWidth, newHeight;

    if (image.width > image.height) {
      newWidth = maxDimension;
      newHeight = (maxDimension / aspectRatio).round();
    } else {
      newHeight = maxDimension;
      newWidth = (maxDimension * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Generate thumbnail image.
  static Future<String> _generateThumbnail(
    img.Image image,
    String channelDir,
    String baseName,
  ) async {
    // Create thumbnails directory
    final thumbnailDir = Directory(path.join(channelDir, 'thumbnails'));
    if (!await thumbnailDir.exists()) {
      await thumbnailDir.create(recursive: true);
    }

    // Resize to thumbnail size
    final thumbnail = img.copyResize(
      image,
      width: image.width > image.height ? thumbnailSize : null,
      height: image.width <= image.height ? thumbnailSize : null,
      interpolation: img.Interpolation.linear,
    );

    // Save as JPEG (WebP encoding not available)
    final thumbnailPath = path.join(
      thumbnailDir.path,
      '${baseName}_thumb.jpg',
    );
    final jpegBytes = img.encodeJpg(thumbnail, quality: thumbnailQuality);
    await File(thumbnailPath).writeAsBytes(jpegBytes);

    // Return relative path from channel directory (e.g., "thumbnails/uuid_thumb.jpg")
    return path.relative(thumbnailPath, from: channelDir);
  }
}
