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

  _ProcessImageParams({
    required this.tempFilePath,
    required this.finalFilePath,
    required this.channelDir,
  });
}

/// Image processor for handling thumbnails and metadata.
class ImageProcessor {
  static const int thumbnailSize = 300;
  static const int thumbnailQuality = 80;

  /// Extensions that browsers can display natively — no conversion needed.
  static const Set<String> _webSafeExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  /// Calculate SHA-256 hash of file bytes (first 8 characters).
  /// Used for cache busting.
  static Future<String> calculateHash(List<int> bytes) async {
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  /// Process an image file.
  ///
  /// Web-safe images (JPEG, PNG, WebP) are EXIF-stripped and saved in their
  /// original format. Non-web-safe images (TIFF, BMP, ICO, PSD, etc.) are
  /// converted to PNG. GIFs are always preserved as-is for animation.
  ///
  /// Throws if the image cannot be decoded (caller should fall back to the
  /// document path).
  static Future<ProcessedImageResult> processImage({
    required String tempFilePath,
    required String finalFilePath,
    required String channelDir,
  }) async {
    final params = _ProcessImageParams(
      tempFilePath: tempFilePath,
      finalFilePath: finalFilePath,
      channelDir: channelDir,
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

    // Decode image — some GIFs (especially from external APIs) use features
    // that the `image` package cannot decode. Fall back gracefully.
    img.Image? image;
    try {
      image = img.decodeImage(bytes);
    } catch (_) {
      // Decode failed — treat as an opaque binary (likely an exotic GIF).
      image = null;
    }

    // GIF files: always preserve the original to keep animation intact.
    // The `image` package often reports numFrames == 1 for animated GIFs,
    // so we cannot rely on frame count to decide.
    final ext = path.extension(params.finalFilePath).toLowerCase();
    if (ext == '.gif') {
      int gifWidth = 0;
      int gifHeight = 0;
      String? thumbPath;

      if (image != null) {
        final oriented = img.bakeOrientation(image);
        gifWidth = oriented.width;
        gifHeight = oriented.height;
        try {
          thumbPath = await _generateThumbnail(
            oriented.frames.first,
            params.channelDir,
            path.basenameWithoutExtension(params.finalFilePath),
          );
        } catch (_) {}
      }

      await tempFile.rename(params.finalFilePath);
      return ProcessedImageResult(
        filePath: params.finalFilePath,
        thumbnailPath: thumbPath,
        width: gifWidth,
        height: gifHeight,
        contentHash: contentHash,
        compressed: false,
        animated: true,
      );
    }

    // WebP: the `image` package has no WebP encoder. Since EXIF in WebP is
    // rare, just pass the file through untouched.
    if (ext == '.webp') {
      int webpWidth = 0;
      int webpHeight = 0;
      String? thumbPath;

      if (image != null) {
        final oriented = img.bakeOrientation(image);
        webpWidth = oriented.width;
        webpHeight = oriented.height;
        try {
          thumbPath = await _generateThumbnail(
            oriented.frames.first,
            params.channelDir,
            path.basenameWithoutExtension(params.finalFilePath),
          );
        } catch (_) {}
      }

      await tempFile.rename(params.finalFilePath);
      return ProcessedImageResult(
        filePath: params.finalFilePath,
        thumbnailPath: thumbPath,
        width: webpWidth,
        height: webpHeight,
        contentHash: contentHash,
        compressed: false,
        animated: false,
      );
    }

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Apply EXIF orientation BEFORE stripping metadata
    image = img.bakeOrientation(image);

    final originalWidth = image.width;
    final originalHeight = image.height;

    // Strip EXIF metadata after applying orientation
    image.exif.clear();

    // Determine output format based on whether the input extension is web-safe.
    final bool isWebSafe = _webSafeExtensions.contains(ext);

    late final String outputPath;
    late final List<int> encodedBytes;

    if (isWebSafe) {
      // Web-safe: re-encode in the same format (EXIF stripped).
      if (ext == '.jpg' || ext == '.jpeg') {
        encodedBytes = img.encodeJpg(image, quality: 95);
        outputPath = params.finalFilePath;
      } else {
        // .png
        encodedBytes = img.encodePng(image);
        outputPath = params.finalFilePath;
      }
    } else {
      // Non-web-safe (TIFF, BMP, ICO, PSD, TGA, etc.): convert to PNG.
      encodedBytes = img.encodePng(image);
      outputPath = '${path.withoutExtension(params.finalFilePath)}.png';
    }

    await File(outputPath).writeAsBytes(encodedBytes);

    // Delete temp file
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    // Generate thumbnail
    final thumbnailPath = await _generateThumbnail(
      image,
      params.channelDir,
      path.basenameWithoutExtension(params.finalFilePath),
    );

    return ProcessedImageResult(
      filePath: outputPath,
      thumbnailPath: thumbnailPath,
      width: originalWidth,
      height: originalHeight,
      contentHash: contentHash,
      compressed: false,
      animated: false,
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
