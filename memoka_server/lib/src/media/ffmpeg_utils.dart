import 'dart:io';

/// Shared ffmpeg utilities and thumbnail constants for image/video processors.
class FfmpegUtils {
  static const int thumbnailSize = 1200;
  static const int thumbnailCompressionLevel = 3;

  static bool? _available;

  /// Check if ffmpeg is available on the system (cached after first check).
  static Future<bool> checkAvailable() async {
    if (_available != null) return _available!;
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      _available = result.exitCode == 0;
    } catch (_) {
      _available = false;
    }
    return _available!;
  }
}
