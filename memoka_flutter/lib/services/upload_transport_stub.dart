import 'dart:async';
import 'dart:io';

/// Result of a platform upload.
class UploadResult {
  final int statusCode;
  final List<int> bodyBytes;
  UploadResult(this.statusCode, this.bodyBytes);
}

/// Native upload using [HttpClient] with chunked flush for TCP back-pressure.
///
/// Writing in 64 KB chunks with [flush] after each ensures that progress
/// reflects actual bytes accepted by the OS TCP send buffer, not just bytes
/// copied into a library-internal buffer.
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
  final client = HttpClient();
  onRegisterCancel(() => client.close(force: true));

  final uri = Uri.parse(url);
  final request = await client.openUrl('POST', uri);

  // Apply headers.
  headers.forEach((key, value) {
    request.headers.set(key, value);
  });
  request.contentLength = contentLength;

  // Write body in 64 KB chunks, flushing after each for back-pressure.
  const chunkSize = 64 * 1024;
  var bytesSent = 0;

  await for (final segment in bodyStream) {
    var offset = 0;
    while (offset < segment.length) {
      final end = (offset + chunkSize < segment.length)
          ? offset + chunkSize
          : segment.length;
      request.add(segment.sublist(offset, end));
      await request.flush();
      bytesSent += end - offset;
      final progress = contentLength > 0 ? bytesSent / contentLength : 0.0;
      onProgress(uploadId, progress);
      offset = end;
    }
  }

  final response = await request.close().timeout(timeout);
  final bodyBytes = await response.fold<List<int>>(
    <int>[],
    (prev, chunk) => prev..addAll(chunk),
  );

  client.close();
  return UploadResult(response.statusCode, bodyBytes);
}
