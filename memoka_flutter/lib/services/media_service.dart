import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;

/// Service for handling media operations.
class MediaService {
  /// Compress an image file.
  static Future<Uint8List?> compressImage(File file) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 85,
      minWidth: 1920,
      minHeight: 1920,
    );
    return result;
  }

  /// Compress image bytes.
  static Future<Uint8List?> compressImageBytes(Uint8List bytes,
      {String format = 'jpg'}) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 85,
      minWidth: 1920,
      minHeight: 1920,
      format: format == 'png' ? CompressFormat.png : CompressFormat.jpeg,
    );
    return result;
  }

  /// Compress a video file.
  /// Returns compressed video bytes or null on failure.
  static Future<Uint8List?> compressVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );

      if (info == null || info.file == null) {
        return null;
      }

      final compressedBytes = await info.file!.readAsBytes();

      // Clean up compressed file
      await info.file!.delete();

      return compressedBytes;
    } catch (e) {
      return null;
    }
  }

  /// Compress video bytes by writing to temp file first.
  static Future<Uint8List?> compressVideoBytes(Uint8List bytes, String fileName) async {
    try {
      // Write bytes to a temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // Compress the temp file
      final compressedBytes = await compressVideo(tempFile);

      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return compressedBytes;
    } catch (e) {
      return null;
    }
  }

  /// Get MIME type from bytes using file extension.
  static String getMimeTypeFromExtension(String fileName) {
    final ext = path.extension(fileName).toLowerCase();
    switch (ext) {
      // Images
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      // Videos
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      // Documents
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.md':
        return 'text/markdown';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  /// Validate file size (max 1GB).
  static bool validateFileSize(int bytes) {
    const maxSize = 1024 * 1024 * 1024; // 1GB
    return bytes <= maxSize;
  }
}
