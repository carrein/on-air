import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';

/// Extracts a thumbnail from the first frame of a video file.
Future<Uint8List?> extractVideoThumbnail(
  String filePath, {
  String mimeType = 'video/mp4',
  Uint8List? bytes,
}) async {
  try {
    // Get video duration to seek to the middle.
    final thumb = await VideoThumbnail.thumbnailData(
      video: filePath,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
      timeMs: 0,
    );
    return (thumb != null && thumb.isNotEmpty) ? thumb : null;
  } catch (_) {
    return null;
  }
}
