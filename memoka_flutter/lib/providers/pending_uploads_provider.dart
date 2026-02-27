import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../main.dart' show getWebServerUrl;
import '../services/media_service.dart';
import '../services/upload_transport.dart' as transport;
import 'notes_provider.dart';

part 'pending_uploads_provider.g.dart';

/// Upload status for a pending upload.
enum UploadStatus { uploading, error, uploaded }

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
  final int? mediaWidth;
  final int? mediaHeight;
  final double progress;
  final UploadStatus status;
  final String? errorMessage;
  final String? serverImageUrl;
  final DateTime? noteCreatedAt;
  final int? serverNoteId;

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
    this.mediaWidth,
    this.mediaHeight,
    this.progress = 0.0,
    this.status = UploadStatus.uploading,
    this.errorMessage,
    this.serverImageUrl,
    this.noteCreatedAt,
    this.serverNoteId,
  });

  PendingUpload copyWith({
    double? progress,
    UploadStatus? status,
    String? errorMessage,
    String? serverImageUrl,
    DateTime? noteCreatedAt,
    int? serverNoteId,
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
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage,
      serverImageUrl: serverImageUrl ?? this.serverImageUrl,
      noteCreatedAt: noteCreatedAt ?? this.noteCreatedAt,
      serverNoteId: serverNoteId ?? this.serverNoteId,
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

  /// Cancel functions keyed by upload ID — platform-specific (xhr.abort / client.close).
  final Map<String, void Function()> _cancelFunctions = {};

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
    int? mediaWidth,
    int? mediaHeight,
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

    // Read image dimensions from file header if not provided.
    if (mimeType.startsWith('image/') && mediaWidth == null) {
      final dims = await _readImageDimensions(
        filePath: localFilePath,
        bytes: localBytes ?? fileBytes,
      );
      if (dims != null) {
        mediaWidth = dims.$1;
        mediaHeight = dims.$2;
      }
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
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
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
    // Invoke platform-specific cancel (xhr.abort / HttpClient.close).
    _cancelFunctions[id]?.call();
    _cancelFunctions.remove(id);

    // Remove from queue if still waiting.
    _queue.remove(id);

    // Remove ghost note and delete local file.
    remove(id);
  }

  /// Called by PendingNoteWidget when the server image has loaded.
  /// Removes the ghost and lets NoteItem take over seamlessly.
  void completeUpload(String id) {
    state = state.where((p) => p.id != id).toList();
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

    try {
      // Build the multipart body (used by both platforms for encoding).
      final multipart = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      multipart.fields['channelId'] = pending.channelId.toString();
      multipart.fields['noteContent'] = pending.noteContent;
      multipart.fields['compress'] = pending.compress.toString();

      final contentType = MediaType.parse(pending.mimeType);

      if (!kIsWeb && pending.localFilePath != null) {
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
        multipart.files.add(
          http.MultipartFile.fromBytes(
            'file',
            pending.localBytes!,
            filename: pending.fileName,
            contentType: contentType,
          ),
        );
      }

      final totalBytes = multipart.contentLength;
      final bodyStream = multipart.finalize();

      // Platform-specific upload with real network progress.
      final result = await transport.platformUpload(
        url: _uploadUrl,
        bodyStream: bodyStream,
        headers: multipart.headers,
        contentLength: totalBytes,
        uploadId: id,
        onProgress: _updateProgress,
        onRegisterCancel: (cancelFn) => _cancelFunctions[id] = cancelFn,
        timeout: const Duration(minutes: 1),
      );

      final statusCode = result.statusCode;
      final responseBytes = result.bodyBytes;

      if (statusCode >= 200 && statusCode < 300) {
        // Delete the local copy.
        if (!kIsWeb && pending.localFilePath != null) {
          final f = File(pending.localFilePath!);
          if (await f.exists()) await f.delete();
        }

        if (pending.isImage) {
          // Parse response to get the server image URL so the ghost note
          // can load it in-place before handing off to NoteItem.
          String? imageUrl;
          DateTime? createdAt;
          int? noteId;
          try {
            final json =
                jsonDecode(utf8.decode(responseBytes)) as Map<String, dynamic>;
            noteId = json['id'] as int?;
            final createdAtStr = json['createdAt'] as String?;
            if (createdAtStr != null) {
              createdAt = DateTime.tryParse(createdAtStr);
            }
            final attachments = json['attachments'] as List?;
            if (attachments != null && attachments.isNotEmpty) {
              final att = attachments[0] as Map<String, dynamic>;
              final filePath = att['filePath'] as String?;
              final contentHash = att['contentHash'] as String?;
              if (filePath != null) {
                imageUrl =
                    '${getWebServerUrl()}/media/$filePath?v=${contentHash ?? ''}';
              }
            }
          } catch (_) {
            // Parse failed — fall through to immediate removal.
          }

          if (imageUrl != null) {
            // Keep ghost alive — PendingNoteWidget will load the server image
            // and call completeUpload() when ready.
            state = [
              for (final p in state)
                if (p.id == id)
                  p.copyWith(
                    status: UploadStatus.uploaded,
                    serverImageUrl: imageUrl,
                    noteCreatedAt: createdAt,
                    serverNoteId: noteId,
                  )
                else
                  p,
            ];
            // Start fetching notes so NoteItem is ready when ghost is removed.
            ref.invalidate(notesProvider(pending.channelId));
          } else {
            // Couldn't parse — remove ghost immediately.
            state = state.where((p) => p.id != id).toList();
            ref.invalidate(notesProvider(pending.channelId));
          }
        } else {
          // Non-image: remove ghost immediately.
          state = state.where((p) => p.id != id).toList();
          ref.invalidate(notesProvider(pending.channelId));
        }
      } else {
        _setError(id, 'Server error ($statusCode)');
      }
    } catch (e) {
      // Don't set error if the upload was cancelled (client closed).
      if (state.any((p) => p.id == id)) {
        _setError(id, e.toString());
      }
    } finally {
      _cancelFunctions.remove(id);
    }
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

  /// Reads image display dimensions (EXIF-aware).
  ///
  /// Uses [instantiateImageCodec] + first frame decode so the returned
  /// width/height reflect EXIF orientation (portrait photos report correctly).
  Future<(int, int)?> _readImageDimensions({
    String? filePath,
    Uint8List? bytes,
  }) async {
    try {
      Uint8List data;
      if (!kIsWeb && filePath != null) {
        data = await File(filePath).readAsBytes();
      } else if (bytes != null) {
        data = bytes;
      } else {
        return null;
      }
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      return (w, h);
    } catch (_) {
      return null;
    }
  }
}
