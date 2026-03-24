import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../../media/hash_utils.dart';
import '../../media/image_processor.dart';
import '../../media/video_processor.dart';
import '../../shared/constants.dart';
import '../../sync/version_helper.dart';

/// HTTP route that accepts multipart file uploads.
///
/// Streams the file body directly to disk — never buffers the full file in
/// memory — fixing the OOM crash caused by the previous base64-over-RPC path.
///
/// Reuses the same image/video processing, DB transaction, and WebSocket
/// broadcast logic previously in the (now removed) MediaEndpoint RPC methods.
class MediaUploadRoute extends Route {
  MediaUploadRoute()
    : super(
        methods: {Method.post, Method.options},
        path: '/**',
      );

  /// Maximum file size (1GB).
  static const int maxFileSize = 1024 * 1024 * 1024;

  /// Check if a MIME type is an image (any image/* subtype).
  static bool _isImageMime(String mime) =>
      mime.toLowerCase().startsWith('image/');

  /// Allowed video MIME types.
  static const List<String> _videoTypes = [
    'video/mp4',
    'video/quicktime',
    'video/webm',
    'video/x-msvideo',
    'video/x-matroska',
    'video/x-ms-wmv',
  ];

  static Headers _corsHeaders() => Headers.build((mh) {
    mh.accessControlAllowOrigin =
        const AccessControlAllowOriginHeader.wildcard();
  });

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    // Handle CORS preflight
    if (request.method == Method.options) {
      return Response.noContent(
        headers: Headers.build((mh) {
          mh.accessControlAllowOrigin =
              const AccessControlAllowOriginHeader.wildcard();
          mh['Access-Control-Allow-Methods'] = ['POST', 'OPTIONS'];
          mh['Access-Control-Allow-Headers'] = ['Content-Type'];
        }),
      );
    }

    try {
      return await _handleUpload(session, request);
    } catch (e, st) {
      session.log('Media upload route error: $e\n$st', level: LogLevel.error);
      return Response.internalServerError(
        body: Body.fromString(jsonEncode({'error': e.toString()})),
        headers: _corsHeaders(),
      );
    }
  }

  Future<Response> _handleUpload(Session session, Request request) async {
    // Parse the content-type header for the multipart boundary.
    final contentTypeValues = request.headers['content-type'];
    if (contentTypeValues == null || contentTypeValues.isEmpty) {
      return Response.badRequest(
        body: Body.fromString(jsonEncode({'error': 'Missing Content-Type'})),
        headers: _corsHeaders(),
      );
    }

    final contentType = contentTypeValues.first;
    if (!contentType.contains('multipart/form-data')) {
      return Response.badRequest(
        body: Body.fromString(
          jsonEncode({'error': 'Expected multipart/form-data'}),
        ),
        headers: _corsHeaders(),
      );
    }

    // Extract boundary from Content-Type.
    final boundaryMatch = RegExp(
      r'boundary=(.+?)(?:;|$)',
      caseSensitive: false,
    ).firstMatch(contentType);
    if (boundaryMatch == null) {
      return Response.badRequest(
        body: Body.fromString(jsonEncode({'error': 'Missing boundary'})),
        headers: _corsHeaders(),
      );
    }
    final boundary = boundaryMatch.group(1)!.trim();

    // Read body stream.
    final bodyStream = request.read();

    // Parse multipart parts.
    final transformer = MimeMultipartTransformer(boundary);

    // Collect text fields and stream the file to a temp path.
    String? channelIdStr;
    String? noteContent;
    String? clientWidthStr;
    String? clientHeightStr;
    String? originalFilename;
    String? mimeType;
    String? tempFilePath;
    int totalFileBytes = 0;

    final uuid = Uuid().v4();

    await for (final part in transformer.bind(bodyStream)) {
      final disposition = part.headers['content-disposition'] ?? '';
      final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(disposition);
      if (nameMatch == null) continue;
      final fieldName = nameMatch.group(1)!;

      if (fieldName == 'file') {
        // Extract filename from content-disposition.
        final filenameMatch = RegExp(
          r'filename="([^"]*)"',
        ).firstMatch(disposition);
        originalFilename = filenameMatch?.group(1) ?? 'upload';

        // Content-type of the file part. Fall back to filename extension if
        // the client sent application/octet-stream (common on Android).
        mimeType = part.headers['content-type'] ?? 'application/octet-stream';
        if (mimeType == 'application/octet-stream') {
          mimeType = lookupMimeType(originalFilename) ?? mimeType;
        }

        // Stream to a temp file in the system temp directory.
        final tempDir = Directory.systemTemp;
        tempFilePath = path.join(tempDir.path, '$uuid.tmp');
        final sink = File(tempFilePath).openWrite();

        try {
          await for (final chunk in part) {
            totalFileBytes += chunk.length;
            if (totalFileBytes > maxFileSize) {
              await sink.close();
              await File(tempFilePath).delete();
              return Response.contentTooLarge(
                body: Body.fromString(
                  jsonEncode({'error': 'File exceeds 1GB limit'}),
                ),
                headers: _corsHeaders(),
              );
            }
            sink.add(chunk);
          }
          await sink.flush();
          await sink.close();
        } catch (e) {
          await sink.close();
          final f = File(tempFilePath);
          if (await f.exists()) await f.delete();
          rethrow;
        }
      } else {
        // Collect small text fields into memory.
        final value = await utf8.decodeStream(part);
        switch (fieldName) {
          case 'channelId':
            channelIdStr = value;
            break;
          case 'noteContent':
            noteContent = value;
            break;
          case 'width':
            clientWidthStr = value;
            break;
          case 'height':
            clientHeightStr = value;
            break;
        }
      }
    }

    // Validate required fields.
    if (channelIdStr == null || tempFilePath == null) {
      if (tempFilePath != null) {
        final f = File(tempFilePath);
        if (await f.exists()) await f.delete();
      }
      return Response.badRequest(
        body: Body.fromString(
          jsonEncode({'error': 'Missing channelId or file'}),
        ),
        headers: _corsHeaders(),
      );
    }

    final channelId = int.tryParse(channelIdStr);
    if (channelId == null) {
      await File(tempFilePath).delete();
      return Response.badRequest(
        body: Body.fromString(jsonEncode({'error': 'Invalid channelId'})),
        headers: _corsHeaders(),
      );
    }

    noteContent ??= '';
    originalFilename ??= 'upload';
    mimeType ??= 'application/octet-stream';

    // Validate filename length
    if (originalFilename.length > 255) {
      await File(tempFilePath).delete();
      return Response.badRequest(
        body: Body.fromString(
          jsonEncode({'error': 'Filename too long (max 255 characters)'}),
        ),
        headers: _corsHeaders(),
      );
    }

    // Validate note content length
    if (noteContent.length > maxNoteContentLength) {
      await File(tempFilePath).delete();
      return Response.badRequest(
        body: Body.fromString(
          jsonEncode({
            'error': 'Note content too long (max 200,000 characters)',
          }),
        ),
        headers: _corsHeaders(),
      );
    }

    // Verify channel exists.
    final channel = await Channel.db.findById(session, channelId);
    if (channel == null) {
      await File(tempFilePath).delete();
      return Response.notFound(
        body: Body.fromString(jsonEncode({'error': 'Channel not found'})),
        headers: _corsHeaders(),
      );
    }

    // Move temp file into channel directory.
    final mediaBaseDir = Directory(ServerConstants.mediaBaseDir);
    if (!await mediaBaseDir.exists()) {
      await mediaBaseDir.create(recursive: true);
    }

    final channelDir = Directory(
      path.join(mediaBaseDir.path, 'channels', channelId.toString()),
    );
    if (!await channelDir.exists()) {
      await channelDir.create(recursive: true);
    }
    final channelDirPath = channelDir.path;

    final originalExt = path.extension(originalFilename).toLowerCase();
    final ext = originalExt.isNotEmpty
        ? originalExt
        : _getExtensionFromMimeType(mimeType);
    final filename = '$uuid$ext';
    final channelTempPath = path.join(channelDirPath, '$uuid.tmp');
    final finalFilePath = path.join(channelDirPath, filename);

    // Move from system temp to channel dir. Try rename first (same device),
    // fall back to copy+delete if cross-device.
    try {
      await File(tempFilePath).rename(channelTempPath);
    } on FileSystemException {
      await File(tempFilePath).copy(channelTempPath);
      await File(tempFilePath).delete();
    }

    try {
      // Process file based on type.
      final bool isImage = _isImageMime(mimeType);
      final bool isVideo = _videoTypes.contains(mimeType.toLowerCase());
      late final String resultFilePath;
      int? width;
      int? height;
      double? duration;
      String? thumbnailPath;
      bool compressed = false;
      bool animated = false;
      String? contentHash;

      if (isImage) {
        try {
          final result = await ImageProcessor.processImage(
            tempFilePath: channelTempPath,
            finalFilePath: finalFilePath,
            channelDir: channelDirPath,
          );
          resultFilePath = result.filePath;
          width = result.width;
          height = result.height;
          thumbnailPath = result.thumbnailPath;
          compressed = result.compressed;
          animated = result.animated;
          contentHash = result.contentHash;
        } catch (e) {
          // Image decode failed — fall back to document path.
          session.log(
            'Image processing failed, treating as document: $e',
            level: LogLevel.warning,
          );
          await File(channelTempPath).rename(finalFilePath);
          resultFilePath = finalFilePath;

          contentHash = await computeFileHash(finalFilePath);
        }
      } else if (isVideo) {
        final result = await VideoProcessor.processVideo(
          tempFilePath: channelTempPath,
          finalFilePath: finalFilePath,
          channelDir: channelDirPath,
        );
        resultFilePath = result.filePath;
        width = result.width;
        height = result.height;
        duration = result.duration;
        thumbnailPath = result.thumbnailPath;
        contentHash = result.contentHash;
      } else {
        // Document — rename to final path.
        await File(channelTempPath).rename(finalFilePath);
        resultFilePath = finalFilePath;

        contentHash = await computeFileHash(finalFilePath);
      }

      // Prefer client-measured dimensions for images — Flutter's native codec
      // handles EXIF orientation correctly, while the server's `image` package
      // sometimes fails for certain JPEGs.
      if (isImage) {
        final clientWidth = clientWidthStr != null
            ? int.tryParse(clientWidthStr)
            : null;
        final clientHeight = clientHeightStr != null
            ? int.tryParse(clientHeightStr)
            : null;
        if (clientWidth != null &&
            clientWidth > 0 &&
            clientHeight != null &&
            clientHeight > 0) {
          width = clientWidth;
          height = clientHeight;
        }
      }

      // Create note + attachment in transaction (with version increment).
      final note = await session.db.transaction((transaction) async {
        final newVersion = await incrementGlobalVersion(
          session,
          transaction: transaction,
        );
        final newNote = Note(
          channelId: channelId,
          content: noteContent!,
          version: newVersion,
        );
        final savedNote = await Note.db.insertRow(
          session,
          newNote,
          transaction: transaction,
        );

        final relativePath = path.relative(
          resultFilePath,
          from: mediaBaseDir.path,
        );

        // Use MIME type from the actual result file — the processor may have
        // converted browser-incompatible formats (e.g. TIFF) to PNG.
        final resultMimeType = lookupMimeType(resultFilePath) ?? mimeType!;

        final attachment = MediaAttachment(
          noteId: savedNote.id!,
          channelId: channelId,
          filePath: relativePath,
          originalFilename: originalFilename!,
          mimeType: resultMimeType,
          fileSize: totalFileBytes,
          width: width,
          height: height,
          duration: duration,
          thumbnailPath: thumbnailPath,
          compressed: compressed,
          animated: animated,
          contentHash: contentHash,
        );

        await MediaAttachment.db.insertRow(
          session,
          attachment,
          transaction: transaction,
        );

        savedNote.attachments = [attachment];

        channel.updatedAt = DateTime.now();
        channel.version = newVersion;
        await Channel.db.updateRow(session, channel, transaction: transaction);

        return savedNote;
      });

      // Broadcast via WebSocket.
      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(type: 'noteCreated', note: note),
      );

      return Response.ok(
        body: Body.fromString(jsonEncode(note.toJson())),
        headers: Headers.build((mh) {
          mh.accessControlAllowOrigin =
              const AccessControlAllowOriginHeader.wildcard();
          mh['Content-Type'] = ['application/json'];
        }),
      );
    } catch (e) {
      // Cleanup on error.
      final tmpFile = File(channelTempPath);
      if (await tmpFile.exists()) await tmpFile.delete();
      final finalFile = File(finalFilePath);
      if (await finalFile.exists()) await finalFile.delete();

      session.log('Media upload failed: $e', level: LogLevel.error);
      rethrow;
    }
  }

  String _getExtensionFromMimeType(String mimeType) {
    final ext = extensionFromMime(mimeType);
    // extensionFromMime returns the input unchanged for unknown types
    if (ext == mimeType) return '.bin';
    return '.$ext';
  }
}
