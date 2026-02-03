import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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

  /// Validate file size (max 100MB).
  static bool validateFileSize(int bytes) {
    const maxSize = 100 * 1024 * 1024; // 100MB
    return bytes <= maxSize;
  }
}
