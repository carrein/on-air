import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Utilities for file handling and display.
class FileUtils {
  /// Get appropriate icon for file extension.
  static IconData getFileIcon(String fileExtension) {
    final ext = fileExtension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'md':
        return Icons.description;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Get color for file extension.
  static Color getFileColor(String fileExtension) {
    final ext = fileExtension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'txt':
      case 'md':
        return Colors.blue;
      case 'doc':
      case 'docx':
        return Colors.indigo;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'zip':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Extract file extension from filename.
  static String getExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Format file size in human-readable format.
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Build media URL with cache busting.
  /// Media is served from the /media route on the web server (same server
  /// that serves the Flutter app). On web, use the app's own origin so it
  /// works behind reverse proxies without hardcoded port swapping.
  static String buildMediaUrl(String serverUrl, String path, String? contentHash) {
    final String base;
    if (kIsWeb) {
      // Use the origin where the app was loaded from — this is always the
      // web server, which also serves /media.
      final origin = Uri.base;
      base = '${origin.scheme}://${origin.host}:${origin.port}';
    } else {
      // Native: API server is on 8080, web server (media) is on 8082.
      base = serverUrl.replaceAll(':8080', ':8082').replaceAll(RegExp(r'/$'), '');
    }
    final cacheBuster = contentHash ?? '';
    return '$base/media/$path?v=$cacheBuster';
  }
}
