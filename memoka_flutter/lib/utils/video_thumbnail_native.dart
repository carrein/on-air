import 'dart:io';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Extracts a thumbnail frame from a video file at the midpoint.
///
/// Uses VideoPlayerController to get duration, then VideoThumbnail to
/// extract the frame as JPEG bytes.
Future<Uint8List?> extractVideoThumbnail(
  String filePath, {
  String mimeType = 'video/mp4',
  Uint8List? bytes,
}) async {
  try {
    // Get video duration to seek to the middle.
    int timeMs = 0;
    final controller = VideoPlayerController.file(File(filePath));
    try {
      await controller.initialize();
      timeMs = controller.value.duration.inMilliseconds ~/ 2;
    } finally {
      await controller.dispose();
    }

    final thumb = await VideoThumbnail.thumbnailData(
      video: filePath,
      imageFormat: ImageFormat.JPEG,
      quality: 100,
      timeMs: timeMs,
    );
    return (thumb != null && thumb.isNotEmpty) ? thumb : null;
  } catch (_) {
    return null;
  }
}
