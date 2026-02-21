import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import '../../media/image_processor.dart';
import '../../media/video_processor.dart';
import '../../shared/constants.dart';

/// HTTP route that accepts multipart file uploads.
///
/// Streams the file body directly to disk — never buffers the full file in
/// memory — fixing the OOM crash caused by the previous base64-over-RPC path.
///
/// Reuses the same image/video processing, DB transaction, and WebSocket
/// broadcast logic from [MediaEndpoint].
class MediaUploadRoute extends Route {
  MediaUploadRoute()
    : super(
        methods: {Method.post, Method.options},
        path: '/**',
      );

  /// Maximum file size (1GB).
  static const int maxFileSize = 1024 * 1024 * 1024;

  /// Allowed image MIME types.
  static const List<String> _imageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heic',
  ];

  /// Allowed video MIME types.
  static const List<String> _videoTypes = [
    'video/mp4',
    'video/quicktime',
    'video/webm',
    'video/x-msvideo',
    'video/x-matroska',
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
    String? compressStr;
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

        // Content-type of the file part.
        mimeType = part.headers['content-type'] ?? 'application/octet-stream';

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
          case 'compress':
            compressStr = value;
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

    final compress = compressStr == 'true';
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
    if (noteContent.length > 200000) {
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

    // Move from system temp to channel dir (may be cross-device, so copy+delete).
    await File(tempFilePath).copy(channelTempPath);
    await File(tempFilePath).delete();

    try {
      // Process file based on type.
      final bool isImage = _imageTypes.contains(mimeType.toLowerCase());
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
        final result = await ImageProcessor.processImage(
          tempFilePath: channelTempPath,
          finalFilePath: finalFilePath,
          channelDir: channelDirPath,
          compress: compress,
        );
        resultFilePath = result.filePath;
        width = result.width;
        height = result.height;
        thumbnailPath = result.thumbnailPath;
        compressed = result.compressed;
        animated = result.animated;
        contentHash = result.contentHash;
      } else if (isVideo) {
        final result = await VideoProcessor.processVideo(
          tempFilePath: channelTempPath,
          finalFilePath: finalFilePath,
          channelDir: channelDirPath,
          compress: compress,
        );
        resultFilePath = result.filePath;
        width = result.width;
        height = result.height;
        duration = result.duration;
        thumbnailPath = result.thumbnailPath;
        compressed = result.compressed;
        contentHash = result.contentHash;
      } else {
        // Document — rename to final path.
        await File(channelTempPath).rename(finalFilePath);
        resultFilePath = finalFilePath;

        final fileBytes = await File(finalFilePath).readAsBytes();
        final digest = await ImageProcessor.calculateHash(fileBytes);
        contentHash = digest.substring(0, 8);
      }

      // Create note + attachment in transaction.
      final note = await session.db.transaction((transaction) async {
        final newNote = Note(
          channelId: channelId,
          content: noteContent!,
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

        final attachment = MediaAttachment(
          noteId: savedNote.id!,
          channelId: channelId,
          filePath: relativePath,
          originalFilename: originalFilename!,
          mimeType: mimeType!,
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
    switch (mimeType.toLowerCase()) {
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'image/heic':
        return '.heic';
      case 'video/mp4':
        return '.mp4';
      case 'video/quicktime':
        return '.mov';
      case 'video/webm':
        return '.webm';
      case 'video/x-msvideo':
        return '.avi';
      case 'video/x-matroska':
        return '.mkv';
      case 'application/pdf':
        return '.pdf';
      case 'text/plain':
        return '.txt';
      case 'text/markdown':
        return '.md';
      case 'application/msword':
        return '.doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return '.docx';
      case 'application/vnd.ms-excel':
        return '.xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return '.xlsx';
      case 'application/zip':
      case 'application/x-zip-compressed':
        return '.zip';
      default:
        return '.bin';
    }
  }
}
