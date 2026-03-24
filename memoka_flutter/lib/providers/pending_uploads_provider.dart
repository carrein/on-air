import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:memoka_client/memoka_client.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../main.dart' show getWebServerUrl;
import '../services/local_image_cache.dart';
import '../services/media_service.dart';
import '../widgets/chat_view.dart' show ChatView;
import '../services/upload_transport.dart' as transport;
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
  final int fileSize;
  final int? mediaWidth;
  final int? mediaHeight;
  final Uint8List? thumbnailBytes; // video thumbnail
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
    this.fileSize = 0,
    this.mediaWidth,
    this.mediaHeight,
    this.thumbnailBytes,
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
      fileSize: fileSize,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      thumbnailBytes: thumbnailBytes,
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
    int? mediaWidth,
    int? mediaHeight,
    Uint8List? thumbnailBytes,
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

    // Read dimensions from file header if not provided.
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
    // For videos, read dimensions from thumbnail if available.
    if (mimeType.startsWith('video/') &&
        mediaWidth == null &&
        thumbnailBytes != null) {
      final dims = await _readImageDimensions(bytes: thumbnailBytes);
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
      fileSize: fileSize,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      thumbnailBytes: thumbnailBytes,
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
      ),
    );
    if (pending.id.isEmpty) return;

    try {
      // Build the multipart body (used by both platforms for encoding).
      final multipart = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      multipart.fields['channelId'] = pending.channelId.toString();
      multipart.fields['noteContent'] = pending.noteContent;
      if (pending.mediaWidth != null) {
        multipart.fields['width'] = pending.mediaWidth.toString();
      }
      if (pending.mediaHeight != null) {
        multipart.fields['height'] = pending.mediaHeight.toString();
      }

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
        // Parse the Note from the response so we can insert it directly.
        Note? uploadedNote;
        try {
          final json =
              jsonDecode(utf8.decode(responseBytes)) as Map<String, dynamic>;
          uploadedNote = Note.fromJson(json);

          // Store local bytes in LocalImageCache so NoteItem renders instantly.
          if (pending.isImage) {
            final attachments = json['attachments'] as List?;
            if (attachments != null && attachments.isNotEmpty) {
              final att = attachments[0] as Map<String, dynamic>;
              final filePath = att['filePath'] as String?;
              final contentHash = att['contentHash'] as String?;
              if (filePath != null) {
                final imageUrl =
                    '${getWebServerUrl()}/media/$filePath?v=${contentHash ?? ''}';
                final bytes =
                    pending.localBytes ??
                    (pending.localFilePath != null
                        ? await File(pending.localFilePath!).readAsBytes()
                        : null);
                if (bytes != null) {
                  LocalImageCache.put(imageUrl, bytes);
                }
              }
            }
          }
        } catch (_) {
          // Parse failed — note will appear via WebSocket instead.
        }

        // Delete the local copy.
        if (!kIsWeb && pending.localFilePath != null) {
          final f = File(pending.localFilePath!);
          if (await f.exists()) await f.delete();
        }

        // Insert the note directly so NoteItem appears in the same frame
        // as the ghost removal — no gap, no flicker.
        if (uploadedNote != null) {
          ref
              .read(notesProvider(pending.channelId).notifier)
              .insertUploadedNote(uploadedNote);
        }

        // Remove ghost and scroll to the new note at the bottom.
        state = state.where((p) => p.id != id).toList();
        _scrollToBottom(pending.channelId);
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

  void _scrollToBottom(int channelId) {
    final controller = ChatView.channelScrollControllers[channelId];
    if (controller != null && controller.isAttached) {
      controller.jumpTo(index: 0);
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
  /// Uses [instantiateImageCodec] + first frame decode. On web, the codec may
  /// not apply EXIF orientation, so we read the JPEG EXIF orientation tag from
  /// the raw bytes and swap width/height for 90/270 degree rotations.
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

      // On web, instantiateImageCodec may not apply EXIF orientation.
      // Check JPEG EXIF and swap dims for 90/270 degree rotations.
      if (kIsWeb) {
        final orientation = _readJpegExifOrientation(data);
        if (orientation != null && orientation >= 5) {
          return (h, w);
        }
      }

      return (w, h);
    } catch (_) {
      return null;
    }
  }

  /// Reads JPEG EXIF orientation tag (1-8) from raw bytes.
  /// Returns null for non-JPEG, missing EXIF, or parse failure.
  static int? _readJpegExifOrientation(Uint8List bytes) {
    try {
      if (bytes.length < 14 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
        return null; // Not JPEG
      }

      var offset = 2;
      while (offset < bytes.length - 1) {
        if (bytes[offset] != 0xFF) return null;
        final marker = bytes[offset + 1];

        if (marker == 0xE1) break; // APP1 (EXIF)
        if (marker == 0xDA || marker == 0xD9) return null; // SOS or EOI

        // Skip segment: 2-byte length follows the marker.
        if (offset + 3 >= bytes.length) return null;
        final segLen = (bytes[offset + 2] << 8) | bytes[offset + 3];
        offset += 2 + segLen;
        continue;
      }

      // Parse APP1 EXIF segment.
      if (offset + 3 >= bytes.length) return null;
      final exifStart = offset + 4;
      // Verify "Exif\0\0" header.
      if (exifStart + 6 > bytes.length) return null;
      if (bytes[exifStart] != 0x45 ||
          bytes[exifStart + 1] != 0x78 ||
          bytes[exifStart + 2] != 0x69 ||
          bytes[exifStart + 3] != 0x66 ||
          bytes[exifStart + 4] != 0x00 ||
          bytes[exifStart + 5] != 0x00) {
        return null;
      }

      final tiffStart = exifStart + 6;
      if (tiffStart + 8 > bytes.length) return null;

      // Byte order: "II" (little-endian) or "MM" (big-endian).
      final bool littleEndian;
      if (bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49) {
        littleEndian = true;
      } else if (bytes[tiffStart] == 0x4D && bytes[tiffStart + 1] == 0x4D) {
        littleEndian = false;
      } else {
        return null;
      }

      int readUint16(int pos) {
        if (pos + 1 >= bytes.length) return 0;
        return littleEndian
            ? bytes[pos] | (bytes[pos + 1] << 8)
            : (bytes[pos] << 8) | bytes[pos + 1];
      }

      int readUint32(int pos) {
        if (pos + 3 >= bytes.length) return 0;
        return littleEndian
            ? bytes[pos] |
                  (bytes[pos + 1] << 8) |
                  (bytes[pos + 2] << 16) |
                  (bytes[pos + 3] << 24)
            : (bytes[pos] << 24) |
                  (bytes[pos + 1] << 16) |
                  (bytes[pos + 2] << 8) |
                  bytes[pos + 3];
      }

      // Verify TIFF magic number (42).
      if (readUint16(tiffStart + 2) != 42) return null;

      // Read IFD0 offset and scan entries.
      final ifd0Offset = readUint32(tiffStart + 4);
      final ifdAbsolute = tiffStart + ifd0Offset;
      if (ifdAbsolute + 2 > bytes.length) return null;

      final entryCount = readUint16(ifdAbsolute);
      for (var i = 0; i < entryCount; i++) {
        final entryOffset = ifdAbsolute + 2 + (i * 12);
        if (entryOffset + 12 > bytes.length) return null;
        final tag = readUint16(entryOffset);
        if (tag == 0x0112) {
          // Orientation tag — value is at offset+8 (SHORT type).
          return readUint16(entryOffset + 8);
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
