import 'package:path/path.dart' as path;

/// Service for handling media operations.
class MediaService {
  /// Get MIME type from file extension.
  ///
  /// On Android, the file name from FilePicker may lack an extension (e.g.
  /// content URI cache names like "1000028478"). Pass [filePath] as a fallback
  /// so we can try its extension too.
  static String getMimeTypeFromExtension(String fileName, {String? filePath}) {
    var ext = path.extension(fileName).toLowerCase();
    // Fallback: try the file path extension if the filename has none.
    if (ext.isEmpty && filePath != null) {
      ext = path.extension(filePath).toLowerCase();
    }
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
