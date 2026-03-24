import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'ffmpeg_utils.dart';
import 'process_params.dart';

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

/// Image processor for handling thumbnails and metadata.
class ImageProcessor {
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
  /// Web-safe images (JPEG, PNG, WebP) are passed through untouched — the
  /// original bytes are kept as-is (no re-encoding, no EXIF stripping).
  /// Non-web-safe images (TIFF, BMP, ICO, PSD, etc.) are converted to PNG.
  /// GIFs are always preserved as-is for animation.
  ///
  /// Throws if the image cannot be decoded (caller should fall back to the
  /// document path).
  static Future<ProcessedImageResult> processImage({
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

  /// Processes the file: decodes, hashes, converts if needed, generates thumbnail.
  static Future<ProcessedImageResult> _processFile(
    ProcessFileParams params,
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

      if (image != null) {
        final oriented = img.bakeOrientation(image);
        gifWidth = oriented.width;
        gifHeight = oriented.height;
      }

      // ffmpeg can thumbnail GIFs even when the image package can't decode them
      final thumbPath = await _generateThumbnail(
        params.tempFilePath,
        params.channelDir,
        path.basenameWithoutExtension(params.finalFilePath),
      );

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

    // Web-safe formats (JPEG, PNG, WebP): pass through the original file
    // untouched. Decode only to extract dimensions (after orientation).
    final bool isWebSafe = _webSafeExtensions.contains(ext);
    if (isWebSafe) {
      int wsWidth = 0;
      int wsHeight = 0;

      if (image != null) {
        final oriented = img.bakeOrientation(image);
        wsWidth = oriented.width;
        wsHeight = oriented.height;
      }

      final thumbPath = await _generateThumbnail(
        params.tempFilePath,
        params.channelDir,
        path.basenameWithoutExtension(params.finalFilePath),
      );

      await tempFile.rename(params.finalFilePath);
      return ProcessedImageResult(
        filePath: params.finalFilePath,
        thumbnailPath: thumbPath,
        width: wsWidth,
        height: wsHeight,
        contentHash: contentHash,
        compressed: false,
        animated: false,
      );
    }

    // Non-web-safe (TIFF, BMP, ICO, PSD, TGA, etc.): convert to PNG.
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    image = img.bakeOrientation(image);
    final originalWidth = image.width;
    final originalHeight = image.height;

    final encodedBytes = img.encodePng(image);
    final outputPath = '${path.withoutExtension(params.finalFilePath)}.png';

    await File(outputPath).writeAsBytes(encodedBytes);

    // Delete temp file
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    // Generate thumbnail from the converted PNG
    final thumbnailPath = await _generateThumbnail(
      outputPath,
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

  /// Generate thumbnail via ffmpeg (lossless WebP at 1200px longest side).
  static Future<String?> _generateThumbnail(
    String sourceFilePath,
    String channelDir,
    String baseName,
  ) async {
    if (!await FfmpegUtils.checkAvailable()) return null;

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
      sourceFilePath,
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

    if (result.exitCode != 0) return null;

    return path.relative(thumbnailPath, from: channelDir);
  }
}
