import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Utilities for file handling and display.
class FileUtils {
  static const _iconColor = Color(0xFF00171F);

  /// Get appropriate icon for file extension.
  static IconData getFileIcon(String fileExtension) {
    final ext = fileExtension.toLowerCase();
    switch (ext) {
      // Documents
      case 'pdf':
        return PhosphorIcons.filePdf();
      case 'doc':
        return PhosphorIcons.fileDoc();
      case 'docx':
        return PhosphorIcons.fileDoc();
      case 'ppt':
        return PhosphorIcons.filePpt();
      case 'pptx':
        return PhosphorIcons.filePpt();
      case 'xls':
        return PhosphorIcons.fileXls();
      case 'xlsx':
        return PhosphorIcons.fileXls();
      case 'csv':
        return PhosphorIcons.fileCsv();
      case 'txt':
        return PhosphorIcons.fileTxt();
      case 'md':
        return PhosphorIcons.fileMd();
      case 'sql':
        return PhosphorIcons.fileSql();
      // Archives
      case 'zip':
      case 'tar':
      case 'gz':
      case 'bz2':
      case '7z':
        return PhosphorIcons.fileZip();
      // Images
      case 'jpg':
      case 'jpeg':
        return PhosphorIcons.fileJpg();
      case 'png':
        return PhosphorIcons.filePng();
      case 'svg':
        return PhosphorIcons.fileSvg();
      // Web / markup
      case 'html':
      case 'htm':
        return PhosphorIcons.fileHtml();
      case 'css':
        return PhosphorIcons.fileCss();
      case 'js':
        return PhosphorIcons.fileJs();
      case 'jsx':
        return PhosphorIcons.fileJsx();
      case 'ts':
        return PhosphorIcons.fileTs();
      case 'tsx':
        return PhosphorIcons.fileTsx();
      case 'vue':
        return PhosphorIcons.fileVue();
      // Systems / compiled
      case 'c':
        return PhosphorIcons.fileC();
      case 'cpp':
      case 'cc':
        return PhosphorIcons.fileCpp();
      case 'cs':
        return PhosphorIcons.fileCSharp();
      case 'py':
        return PhosphorIcons.filePy();
      case 'rs':
        return PhosphorIcons.fileRs();
      // Audio / video
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'ogg':
        return PhosphorIcons.fileAudio();
      case 'mp4':
      case 'mov':
      case 'webm':
        return PhosphorIcons.fileVideo();
      // Config
      case 'ini':
        return PhosphorIcons.fileIni();
      default:
        return PhosphorIcons.file();
    }
  }

  /// Icon color for file attachments — always uses the app's core text colour.
  static Color getFileColor(String fileExtension) => _iconColor;

  /// Returns true if the extension is a supported audio format.
  static bool isAudio(String fileExtension) {
    const audioExts = {'mp3', 'wav', 'flac', 'ogg', 'aac', 'm4a', 'opus'};
    return audioExts.contains(fileExtension.toLowerCase());
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
  /// Serverpod runs the API on port 8080 and the web server (which serves
  /// /media) on port 8082. If the server URL uses port 8080, swap to 8082.
  /// Production servers behind a reverse proxy (no explicit port or 80/443)
  /// serve media from the same base URL.
  static String buildMediaUrl(
    String serverUrl,
    String path,
    String? contentHash,
  ) {
    final uri = Uri.parse(serverUrl);
    final String base;
    if (uri.port == 8080) {
      base = '${uri.scheme}://${uri.host}:8082';
    } else {
      base =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    }
    final cacheBuster = contentHash ?? '';
    return '$base/media/$path?v=$cacheBuster';
  }
}
