import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/file_utils.dart';

/// Helper class for upload file data.
///
/// On native platforms, [filePath] points to the picked file on disk and
/// [bytes] is null (avoids loading multi-MB files into the Dart heap).
/// On web, [bytes] holds the file contents because web has no file system.
class UploadFileData {
  final Uint8List? bytes;
  final String? filePath;
  final String fileName;
  final String extension;

  UploadFileData({
    this.bytes,
    this.filePath,
    required this.fileName,
    required this.extension,
  }) : assert(
         bytes != null || filePath != null,
         'Either bytes or filePath must be provided',
       );

  bool get isImage {
    final ext = extension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
  }

  bool get isMedia => isImage || isVideo;

  bool get isVideo {
    final ext = extension.toLowerCase();
    return ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);
  }

  /// Infer MIME type from extension for video files.
  String get mimeType {
    const map = {
      'mp4': 'video/mp4',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'avi': 'video/x-msvideo',
      'mkv': 'video/x-matroska',
    };
    return map[extension.toLowerCase()] ?? 'video/mp4';
  }

  IconData get fileIcon => FileUtils.getFileIcon(extension);

  String get fileSizeFormatted {
    if (bytes != null) {
      return FileUtils.formatFileSize(bytes!.length);
    }
    if (!kIsWeb && filePath != null) {
      return FileUtils.formatFileSize(File(filePath!).lengthSync());
    }
    return '';
  }
}
