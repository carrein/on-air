import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../main.dart' show getWebServerUrl;
import '../services/media_service.dart';
import 'notes_provider.dart';

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
  final int fileSize;
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
    this.fileSize = 0,
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
      fileSize: fileSize,
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

  /// Active HTTP clients keyed by upload ID — used to cancel in-flight uploads.
  final Map<String, http.Client> _activeClients = {};

  @override
  List<PendingUpload> build() {
    // Clean up old pending_uploads files on app start.
    if (!kIsWeb) {
      unawaited(_cleanupOldFiles());
    }
    return [];
  }

  /// The upload endpoint URL derived from shared web server URL.
  String get _uploadUrl => '${getWebServerUrl()}/media/upload';

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
    final mimeType = MediaService.getMimeTypeFromExtension(
      fileName,
      filePath: filePath,
    );

    String? localFilePath;
    Uint8List? localBytes;
    int fileSize = 0;

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
      fileSize = await File(stablePath).length();
    } else if (fileBytes != null) {
      localBytes = fileBytes;
      fileSize = fileBytes.length;
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
      fileSize: fileSize,
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

  /// Cancel an in-progress upload.
  void cancel(String id) {
    // Close the HTTP client to abort the request.
    _activeClients[id]?.close();
    _activeClients.remove(id);

    // Remove from queue if still waiting.
    _queue.remove(id);

    // Remove ghost note and delete local file.
    remove(id);
  }

  /// Dismiss a failed upload (remove ghost note).
  void remove(String id) {
    // Also delete the local copy if it exists.
    final pending = state.firstWhere(
      (p) => p.id == id,
      orElse: () => PendingUpload(
        id: '',
        channelId: 0,
        fileName: '',
        mimeType: '',
        noteContent: '',
        compress: false,
      ),
    );
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
    final pending = state.firstWhere(
      (p) => p.id == id,
      orElse: () => PendingUpload(
        id: '',
        channelId: 0,
        fileName: '',
        mimeType: '',
        noteContent: '',
        compress: false,
      ),
    );
    if (pending.id.isEmpty) return;

    final client = http.Client();
    _activeClients[id] = client;

    try {
      final multipart = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      multipart.fields['channelId'] = pending.channelId.toString();
      multipart.fields['noteContent'] = pending.noteContent;
      multipart.fields['compress'] = pending.compress.toString();

      final contentType = MediaType.parse(pending.mimeType);

      if (!kIsWeb && pending.localFilePath != null) {
        // Stream from disk — never holds full file in memory.
        final file = File(pending.localFilePath!);
        final fileLength = await file.length();
        multipart.files.add(
          http.MultipartFile(
            'file',
            file.openRead(),
            fileLength,
            filename: pending.fileName,
            contentType: contentType,
          ),
        );
      } else if (pending.localBytes != null) {
        // Web: bytes already in memory.
        multipart.files.add(
          http.MultipartFile.fromBytes(
            'file',
            pending.localBytes!,
            filename: pending.fileName,
            contentType: contentType,
          ),
        );
      }

      // Finalize into a StreamedRequest so we can track bytes *sent over
      // the network* (not just read from disk — disk reads are near-instant).
      final totalBytes = multipart.contentLength;
      final bodyStream = multipart.finalize();

      final streamed = http.StreamedRequest('POST', Uri.parse(_uploadUrl))
        ..contentLength = totalBytes
        ..headers.addAll(multipart.headers);

      unawaited(
        _trackProgress(
          bodyStream,
          totalBytes,
          id,
        ).pipe(streamed.sink).catchError((_) {}),
      );

      final streamedResponse = await client
          .send(streamed)
          .timeout(
            const Duration(minutes: 1),
            onTimeout: () => throw TimeoutException(
              'Upload timed out after 1 minute',
            ),
          );
      final statusCode = streamedResponse.statusCode;
      await streamedResponse.stream.drain<void>();

      if (statusCode >= 200 && statusCode < 300) {
        // Success — remove ghost note.
        // Delete the local copy.
        if (!kIsWeb && pending.localFilePath != null) {
          final f = File(pending.localFilePath!);
          if (await f.exists()) await f.delete();
        }
        state = state.where((p) => p.id != id).toList();

        // Invalidate notes so the real note appears even if the WebSocket
        // event was missed (e.g. app was backgrounded).
        ref.invalidate(notesProvider(pending.channelId));
      } else {
        _setError(id, 'Server error ($statusCode)');
      }
    } catch (e) {
      // Don't set error if the upload was cancelled (client closed).
      if (state.any((p) => p.id == id)) {
        _setError(id, e.toString());
      }
    } finally {
      _activeClients.remove(id);
      client.close();
    }
  }

  /// Wraps a byte stream to track upload progress.
  Stream<List<int>> _trackProgress(
    Stream<List<int>> source,
    int totalBytes,
    String uploadId,
  ) {
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
