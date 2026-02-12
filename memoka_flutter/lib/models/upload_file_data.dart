import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/file_utils.dart';

/// Helper class for upload file data
class UploadFileData {
  final Uint8List bytes;
  final String fileName;
  final String extension;
  bool compress;

  UploadFileData({
    required this.bytes,
    required this.fileName,
    required this.extension,
    this.compress = false,
  });

  bool get isImage {
    final ext = extension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
  }

  bool get isVideo {
    final ext = extension.toLowerCase();
    return ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);
  }

  IconData get fileIcon => FileUtils.getFileIcon(extension);

  String get fileSizeFormatted => FileUtils.formatFileSize(bytes.length);
}
