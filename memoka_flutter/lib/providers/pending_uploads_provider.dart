import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../main.dart' show serverUrl;
import '../services/media_service.dart';

part 'pending_uploads_provider.g.dart';

/// Upload status for a pending upload.
enum UploadStatus { uploading, error }

/// Represents a file being uploaded optimistically.
class PendingUpload {
  final String id;
  final int channelId;
  final String fileName;
  final String mimeType;
  final String? localFilePath; // native only
  final Uint8List? localBytes; // web only
  final String noteContent;
  final bool compress;
  final double progress;
  final UploadStatus status;
  final String? errorMessage;

  const PendingUpload({
    required this.id,
    required this.channelId,
    required this.fileName,
    required this.mimeType,
    this.localFilePath,
    this.localBytes,
    required this.noteContent,
    required this.compress,
    this.progress = 0.0,
    this.status = UploadStatus.uploading,
    this.errorMessage,
  });

  PendingUpload copyWith({
    double? progress,
    UploadStatus? status,
    String? errorMessage,
  }) {
    return PendingUpload(
      id: id,
      channelId: channelId,
      fileName: fileName,
      mimeType: mimeType,
      localFilePath: localFilePath,
      localBytes: localBytes,
      noteContent: noteContent,
      compress: compress,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');

  String get fileExtension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }
}

/// Manages optimistic uploads with progress tracking and retry.
@Riverpod(keepAlive: true)
class PendingUploads extends _$PendingUploads {
  /// Queue of upload IDs waiting to start.
  final List<String> _queue = [];
  bool _isProcessing = false;

  @override
  List<PendingUpload> build() {
    // Clean up old pending_uploads files on app start.
    if (!kIsWeb) {
      unawaited(_cleanupOldFiles());
    }
    return [];
  }

  /// The upload endpoint URL derived from [serverUrl].
  String get _uploadUrl {
    final uri = Uri.parse(serverUrl);
    // Serverpod web server runs on port 8082 in dev (API is 8080).
    final port = uri.port == 8080 ? 8082 : uri.port;
    return '${uri.scheme}://${uri.host}:$port/media/upload';
  }

  /// Enqueue a file for upload. The ghost note appears immediately.
  ///
  /// On native, copies the file to a stable local path so retries work even
  /// if the original path becomes unavailable.
  Future<void> enqueue({
    required int channelId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String noteContent,
    required bool compress,
  }) async {
    final id = const Uuid().v4();
    final mimeType = MediaService.getMimeTypeFromExtension(fileName);

    String? localFilePath;
    Uint8List? localBytes;

    if (!kIsWeb && filePath != null) {
      // Copy file to app documents dir for retry resilience.
      final docsDir = await getApplicationDocumentsDirectory();
      final pendingDir = Directory(p.join(docsDir.path, 'pending_uploads'));
      if (!await pendingDir.exists()) {
        await pendingDir.create(recursive: true);
      }
      final ext = p.extension(fileName);
      final stablePath = p.join(pendingDir.path, '$id$ext');
      await File(filePath).copy(stablePath);
      localFilePath = stablePath;
    } else if (fileBytes != null) {
      localBytes = fileBytes;
    }

    final pending = PendingUpload(
      id: id,
      channelId: channelId,
      fileName: fileName,
      mimeType: mimeType,
      localFilePath: localFilePath,
      localBytes: localBytes,
      noteContent: noteContent,
      compress: compress,
    );

    // Prepend so newest ghost notes are first (they render at bottom of
    // inverted list).
    state = [pending, ...state];

    _queue.add(id);
    unawaited(_processQueue());
  }

  /// Retry a failed upload.
  void retry(String id) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: UploadStatus.uploading, progress: 0.0)
        else
          p,
    ];
    _queue.add(id);
    unawaited(_processQueue());
  }

  /// Dismiss a failed upload (remove ghost note).
  void remove(String id) {
    // Also delete the local copy if it exists.
    final pending = state.firstWhere((p) => p.id == id,
        orElse: () => PendingUpload(
            id: '', channelId: 0, fileName: '', mimeType: '', noteContent: '', compress: false));
    if (pending.localFilePath != null) {
      final f = File(pending.localFilePath!);
      if (f.existsSync()) f.deleteSync();
    }
    state = state.where((p) => p.id != id).toList();
  }

  /// Sequential queue processor — runs one upload at a time.
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final id = _queue.removeAt(0);
      // Skip if removed or already completed.
      if (!state.any((p) => p.id == id)) continue;
      await _upload(id);
    }

    _isProcessing = false;
  }

  /// Perform the actual HTTP multipart upload.
  Future<void> _upload(String id) async {
    final pending = state.firstWhere((p) => p.id == id,
        orElse: () => PendingUpload(
            id: '', channelId: 0, fileName: '', mimeType: '', noteContent: '', compress: false));
    if (pending.id.isEmpty) return;

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['channelId'] = pending.channelId.toString();
      request.fields['noteContent'] = pending.noteContent;
      request.fields['compress'] = pending.compress.toString();

      if (!kIsWeb && pending.localFilePath != null) {
        // Stream from disk — never holds full file in memory.
        final file = File(pending.localFilePath!);
        final fileLength = await file.length();
        final byteStream = _trackProgress(file.openRead(), fileLength, id);
        request.files.add(http.MultipartFile(
          'file',
          byteStream,
          fileLength,
          filename: pending.fileName,
        ));
      } else if (pending.localBytes != null) {
        // Web: bytes already in memory.
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          pending.localBytes!,
          filename: pending.fileName,
        ));
      }

      final streamedResponse = await request.send();
      final statusCode = streamedResponse.statusCode;
      await streamedResponse.stream.drain<void>();

      if (statusCode >= 200 && statusCode < 300) {
        // Success — remove ghost note (real note arrives via WebSocket).
        // Delete the local copy.
        if (!kIsWeb && pending.localFilePath != null) {
          final f = File(pending.localFilePath!);
          if (await f.exists()) await f.delete();
        }
        state = state.where((p) => p.id != id).toList();
      } else {
        _setError(id, 'Server error ($statusCode)');
      }
    } catch (e) {
      _setError(id, e.toString());
    }
  }

  /// Wraps a byte stream to track upload progress.
  Stream<List<int>> _trackProgress(
      Stream<List<int>> source, int totalBytes, String uploadId) {
    var sent = 0;
    return source.map((chunk) {
      sent += chunk.length;
      final progress = totalBytes > 0 ? sent / totalBytes : 0.0;
      _updateProgress(uploadId, progress);
      return chunk;
    });
  }

  void _updateProgress(String id, double progress) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(progress: progress) else p,
    ];
  }

  void _setError(String id, String message) {
    state = [
      for (final p in state)
        if (p.id == id)
          p.copyWith(status: UploadStatus.error, errorMessage: message)
        else
          p,
    ];
  }

  /// Delete files in pending_uploads/ older than 24 hours.
  Future<void> _cleanupOldFiles() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final pendingDir = Directory(p.join(docsDir.path, 'pending_uploads'));
      if (!await pendingDir.exists()) return;

      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      await for (final entity in pendingDir.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
    } catch (_) {
      // Ignore cleanup errors.
    }
  }
}
