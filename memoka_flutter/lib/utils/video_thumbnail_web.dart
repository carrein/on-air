import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Extracts a thumbnail frame from video bytes using the HTML Video API.
///
/// Creates a temporary video element, seeks to the midpoint, draws the frame
/// onto a canvas, and returns the image as JPEG bytes.
Future<Uint8List?> extractVideoThumbnail(
  String filePath, {
  String mimeType = 'video/mp4',
  Uint8List? bytes,
}) async {
  if (bytes == null) return null;
  try {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);

    final video = web.HTMLVideoElement()
      ..src = url
      ..muted = true
      ..preload = 'auto';

    try {
      // Wait for metadata to load.
      final metaCompleter = Completer<void>();
      video.addEventListener(
        'loadedmetadata',
        ((web.Event e) => metaCompleter.complete()).toJS,
      );
      video.addEventListener(
        'error',
        ((web.Event e) {
          if (!metaCompleter.isCompleted) {
            metaCompleter.completeError('Video metadata load failed');
          }
        }).toJS,
      );
      video.load();
      await metaCompleter.future.timeout(const Duration(seconds: 10));

      // Seek to the middle of the video.
      video.currentTime = video.duration / 2;

      // Wait for seek to complete.
      final seekCompleter = Completer<void>();
      video.addEventListener(
        'seeked',
        ((web.Event e) => seekCompleter.complete()).toJS,
      );
      await seekCompleter.future.timeout(const Duration(seconds: 10));

      // Draw the frame onto a canvas.
      final width = video.videoWidth;
      final height = video.videoHeight;
      if (width == 0 || height == 0) return null;

      final canvas = web.HTMLCanvasElement()
        ..width = width
        ..height = height;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      ctx.drawImage(video, 0, 0);

      // Convert canvas to JPEG blob.
      final blobCompleter = Completer<web.Blob?>();
      canvas.toBlob(
        ((JSAny? b) => blobCompleter.complete(
          b == null ? null : b as web.Blob,
        )).toJS,
        'image/jpeg',
      );
      final jpegBlob = await blobCompleter.future.timeout(
        const Duration(seconds: 10),
      );
      if (jpegBlob == null) return null;

      // Read blob as ArrayBuffer → Uint8List.
      final arrayBuffer = await jpegBlob.arrayBuffer().toDart;
      return arrayBuffer.toDart.asUint8List();
    } finally {
      // Release the video resource and revoke the object URL.
      video.src = '';
      web.URL.revokeObjectURL(url);
    }
  } catch (_) {
    return null;
  }
}
