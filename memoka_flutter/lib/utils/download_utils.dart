import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'toast_utils.dart';

/// Handle returned from [DownloadUtils.downloadToDevice] to allow cancellation.
class DownloadHandle {
  DownloadHandle._(this._client);
  final HttpClient _client;
  bool _cancelled = false;

  /// Cancel the in-flight download.
  void cancel() {
    _cancelled = true;
    _client.close(force: true);
  }

  bool get isCancelled => _cancelled;
}

/// Downloads a file from [url] to a temporary directory, then dispatches
/// based on MIME type: images/videos → gallery, everything else → open with
/// default handler.  Caches files so repeated taps skip the download.
class DownloadUtils {
  /// Returns a [DownloadHandle] that can be used to cancel the download.
  ///
  /// [onProgress] receives `(receivedBytes, totalBytes)`.
  /// [totalBytes] is -1 when the server doesn't report Content-Length.
  static DownloadHandle downloadToDevice(
    BuildContext context,
    String url,
    String filename, {
    String? mimeType,
    void Function(int received, int total)? onProgress,
    VoidCallback? onComplete,
  }) {
    final client = HttpClient();
    final handle = DownloadHandle._(client);

    _download(
      context,
      client,
      handle,
      url,
      filename,
      mimeType: mimeType,
      onProgress: onProgress,
      onComplete: onComplete,
    ).ignore();

    return handle;
  }

  static Future<void> _download(
    BuildContext context,
    HttpClient client,
    DownloadHandle handle,
    String url,
    String filename, {
    String? mimeType,
    void Function(int received, int total)? onProgress,
    VoidCallback? onComplete,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');

      // Use cached file if it exists and has content.
      if (file.existsSync() && file.lengthSync() > 0) {
        client.close();
        if (context.mounted) await _dispatch(context, file.path, mimeType);
        return;
      }

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      final contentLength = response.contentLength; // -1 if unknown
      final bytes = <int>[];
      var received = 0;

      await for (final chunk in response) {
        if (handle.isCancelled) return;
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, contentLength);
      }

      if (handle.isCancelled) return;
      client.close();

      await file.writeAsBytes(bytes);
      if (context.mounted) await _dispatch(context, file.path, mimeType);
    } catch (e) {
      if (handle.isCancelled) return;
      if (context.mounted) {
        ToastUtils.show(context, 'Download failed: $e', type: ToastType.error);
      }
    } finally {
      onComplete?.call();
    }
  }

  /// Dispatch the downloaded file based on MIME type.
  static Future<void> _dispatch(
    BuildContext context,
    String path,
    String? mimeType,
  ) async {
    final mime = (mimeType ?? '').toLowerCase();
    if (mime.startsWith('image/')) {
      await Gal.putImage(path);
      if (context.mounted) {
        ToastUtils.show(context, 'Saved to gallery', type: ToastType.success);
      }
    } else if (mime.startsWith('video/')) {
      await Gal.putVideo(path);
      if (context.mounted) {
        ToastUtils.show(context, 'Saved to gallery', type: ToastType.success);
      }
    } else {
      await OpenFilex.open(path);
    }
  }
}
