import 'package:flutter/foundation.dart';

import 'download_utils.dart';

enum DownloadStatus { downloading, completed }

class DownloadEntry {
  const DownloadEntry({
    required this.handle,
    required this.status,
    this.receivedBytes = 0,
    this.totalBytes = -1,
    this.cachedPath,
  });

  final DownloadHandle handle;
  final DownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final String? cachedPath;
}

/// Singleton that tracks in-flight and completed cache downloads so state
/// survives widget disposal (e.g. channel switches).
class DownloadTracker extends ChangeNotifier {
  DownloadTracker._();
  static final instance = DownloadTracker._();

  final _entries = <String, DownloadEntry>{};

  DownloadEntry? operator [](String key) => _entries[key];

  /// Start a cache download tracked by [key]. No-op if [key] already tracked.
  void startCacheDownload(
    String key,
    String url,
    String filename, {
    void Function(String error)? onError,
  }) {
    if (_entries.containsKey(key)) return;

    late final DownloadHandle handle;
    handle = DownloadUtils.downloadToCache(
      url,
      filename,
      onProgress: (received, total) {
        _entries[key] = DownloadEntry(
          handle: handle,
          status: DownloadStatus.downloading,
          receivedBytes: received,
          totalBytes: total,
        );
        notifyListeners();
      },
      onSuccess: (path) {
        _entries[key] = DownloadEntry(
          handle: handle,
          status: DownloadStatus.completed,
          cachedPath: path,
        );
        notifyListeners();
      },
      onError: (error) {
        _entries.remove(key);
        notifyListeners();
        onError?.call(error);
      },
    );

    _entries[key] = DownloadEntry(
      handle: handle,
      status: DownloadStatus.downloading,
    );
    notifyListeners();
  }

  void cancel(String key) {
    final entry = _entries[key];
    if (entry != null) {
      entry.handle.cancel();
      _entries.remove(key);
      notifyListeners();
    }
  }

  /// Remove a completed entry. Caller already handled state update.
  void acknowledge(String key) {
    _entries.remove(key);
  }
}
