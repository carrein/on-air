import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Copies the image at [imageUrl] to the system clipboard as PNG.
///
/// Returns true on success, false if the browser does not support the
/// Clipboard API / ClipboardItem, or if an error occurs.
///
/// Requires that the server sends CORS headers (Access-Control-Allow-Origin)
/// for the media URLs so the fetch blob request succeeds.
Future<bool> copyImageToClipboard(String imageUrl) async {
  try {
    // Guard: ClipboardItem.supports() throws if ClipboardItem is unavailable.
    try {
      if (!web.ClipboardItem.supports('image/png')) return false;
    } catch (_) {
      return false;
    }

    // Fetch image blob via the browser Fetch API.
    final response = await web.window.fetch(imageUrl.toJS).toDart;
    final blob = await response.blob().toDart;

    // Convert the blob to PNG using a canvas element so the Clipboard API
    // always receives a supported format regardless of the source MIME type.
    final objectUrl = web.URL.createObjectURL(blob);
    try {
      final img = web.HTMLImageElement();
      img.src = objectUrl;
      await img.onLoad.first;

      final canvas = web.HTMLCanvasElement()
        ..width = img.naturalWidth
        ..height = img.naturalHeight;
      (canvas.getContext('2d') as web.CanvasRenderingContext2D)
          .drawImage(img, 0, 0);

      // toBlob is callback-based; bridge to a Future with a Completer.
      final blobCompleter = Completer<web.Blob?>();
      canvas.toBlob(
        ((JSAny? b) =>
                blobCompleter.complete(b == null ? null : b as web.Blob))
            .toJS,
        'image/png',
      );
      final pngBlob = await blobCompleter.future;
      if (pngBlob == null) return false;

      // Build ClipboardItem({'image/png': blob}).
      final dataObj = JSObject();
      dataObj['image/png'] = pngBlob;
      final item = web.ClipboardItem(dataObj);

      // Write to the clipboard.
      await web.window.navigator.clipboard.write([item].toJS).toDart;
      return true;
    } finally {
      web.URL.revokeObjectURL(objectUrl);
    }
  } catch (_) {
    return false;
  }
}
