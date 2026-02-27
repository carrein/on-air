import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'toast_utils.dart';

/// Handle returned from download methods to allow cancellation.
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

class DownloadUtils {
  /// Check if a file is cached in the temp directory.
  static Future<String?> getCachedPath(String filename) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename');
    if (file.existsSync() && file.lengthSync() > 0) {
      return file.path;
    }
    return null;
  }

  /// Download a file to the temp cache without opening it.
  ///
  /// Calls [onSuccess] with the cached file path on completion.
  /// If the file is already cached, [onSuccess] fires immediately.
  static DownloadHandle downloadToCache(
    String url,
    String filename, {
    void Function(int received, int total)? onProgress,
    void Function(String path)? onSuccess,
    void Function(String error)? onError,
    VoidCallback? onComplete,
  }) {
    final client = HttpClient();
    final handle = DownloadHandle._(client);

    _downloadToCache(
      client,
      handle,
      url,
      filename,
      onProgress: onProgress,
      onSuccess: onSuccess,
      onError: onError,
      onComplete: onComplete,
    ).ignore();

    return handle;
  }

  static Future<void> _downloadToCache(
    HttpClient client,
    DownloadHandle handle,
    String url,
    String filename, {
    void Function(int received, int total)? onProgress,
    void Function(String path)? onSuccess,
    void Function(String error)? onError,
    VoidCallback? onComplete,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');

      // Cache hit
      if (file.existsSync() && file.lengthSync() > 0) {
        client.close();
        onSuccess?.call(file.path);
        return;
      }

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      final contentLength = response.contentLength;
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
      onSuccess?.call(file.path);
    } catch (e) {
      if (handle.isCancelled) return;
      onError?.call('$e');
    } finally {
      onComplete?.call();
    }
  }

  /// Open a cached file with the system's default handler.
  static Future<bool> openFile(String path) async {
    final result = await OpenFilex.open(path);
    return result.type == ResultType.done;
  }

  /// Save a cached file using the system file picker (SAF on Android).
  static Future<bool> saveFile(String path, String filename) async {
    final bytes = await File(path).readAsBytes();
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save file',
      fileName: filename,
      bytes: bytes,
    );
    return result != null;
  }

  // ---------------------------------------------------------------
  // Legacy: used by image/video/audio download (gallery dispatch)
  // ---------------------------------------------------------------

  /// Download and dispatch based on MIME type (images/videos → gallery).
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

    _downloadAndDispatch(
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

  static Future<void> _downloadAndDispatch(
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

      if (file.existsSync() && file.lengthSync() > 0) {
        client.close();
        if (context.mounted) await _dispatch(context, file.path, mimeType);
        return;
      }

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      final contentLength = response.contentLength;
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
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && context.mounted) {
        ToastUtils.show(
          context,
          'Could not open file',
          type: ToastType.error,
        );
      }
    }
  }
}
