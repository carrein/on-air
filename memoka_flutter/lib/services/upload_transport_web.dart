import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Result of a platform upload.
class UploadResult {
  final int statusCode;
  final List<int> bodyBytes;
  UploadResult(this.statusCode, this.bodyBytes);
}

/// Web upload using [XMLHttpRequest] for real browser-level progress events.
///
/// The browser's `upload.onprogress` fires as bytes leave the network stack,
/// giving accurate progress even on slow connections — unlike wrapping a Dart
/// stream which only measures in-process buffering speed.
Future<UploadResult> platformUpload({
  required String url,
  required Stream<List<int>> bodyStream,
  required Map<String, String> headers,
  required int contentLength,
  required String uploadId,
  required void Function(String id, double progress) onProgress,
  required void Function(void Function() cancelFn) onRegisterCancel,
  required Duration timeout,
}) async {
  // Collect the body stream into a single byte buffer for XHR.
  final builder = BytesBuilder(copy: false);
  await for (final chunk in bodyStream) {
    builder.add(chunk);
  }
  final bodyBytes = builder.toBytes();

  final completer = Completer<UploadResult>();

  final xhr = web.XMLHttpRequest();
  xhr.open('POST', url);
  xhr.timeout = timeout.inMilliseconds;

  onRegisterCancel(() => xhr.abort());

  // Apply headers (skip content-length — browser sets it from body).
  headers.forEach((key, value) {
    if (key.toLowerCase() != 'content-length') {
      xhr.setRequestHeader(key, value);
    }
  });

  // Real network-level progress from the browser.
  xhr.upload.addEventListener(
    'progress',
    ((web.ProgressEvent event) {
      if (event.lengthComputable) {
        final progress = event.total > 0 ? event.loaded / event.total : 0.0;
        onProgress(uploadId, progress);
      }
    }).toJS,
  );

  xhr.addEventListener(
    'load',
    ((web.Event _) {
      if (!completer.isCompleted) {
        final responseBytes = _xhrResponseBytes(xhr);
        completer.complete(UploadResult(xhr.status, responseBytes));
      }
    }).toJS,
  );

  xhr.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Upload network error'));
      }
    }).toJS,
  );

  xhr.addEventListener(
    'timeout',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Upload timed out', timeout),
        );
      }
    }).toJS,
  );

  xhr.addEventListener(
    'abort',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Upload cancelled'));
      }
    }).toJS,
  );

  // Set response type before sending.
  xhr.responseType = 'arraybuffer';

  // Send the body as a Blob (preferred for binary data in XHR).
  final jsArray = bodyBytes.toJS;
  final blob = web.Blob([jsArray].toJS);
  xhr.send(blob);

  return completer.future;
}

/// Extract response bytes from an XHR with responseType = 'arraybuffer'.
List<int> _xhrResponseBytes(web.XMLHttpRequest xhr) {
  try {
    final buffer = xhr.response;
    if (buffer == null) return [];
    final arrayBuffer = buffer as JSArrayBuffer;
    final uint8 = arrayBuffer.toDart.asUint8List();
    return uint8;
  } catch (_) {
    return [];
  }
}
