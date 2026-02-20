import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';
import 'image_processor.dart';
import 'video_processor.dart';

/// Endpoint for media upload and management.
class MediaEndpoint extends Endpoint {
  /// Maximum file size (1GB).
  static const int maxFileSize = 1024 * 1024 * 1024;

  /// Allowed MIME types for images.
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/heic',
  ];

  /// Allowed MIME types for videos.
  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/quicktime', // .mov
    'video/webm',
    'video/x-msvideo', // .avi
    'video/x-matroska', // .mkv
  ];

  /// Allowed MIME types for documents.
  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'text/plain',
    'text/markdown',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document', // .docx
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', // .xlsx
    'application/zip',
    'application/x-zip-compressed',
  ];

  /// All allowed MIME types.
  static List<String> get allowedMimeTypes => [
    ...allowedImageTypes,
    ...allowedVideoTypes,
    ...allowedDocumentTypes,
  ];

  /// Upload a media file as bytes and create a note with it.
  ///
  /// Uses two-phase commit:
  /// 1. Write bytes to temporary file
  /// 2. Process image
  /// 3. Insert database records (note + attachment) in transaction
  /// 4. Rename to final filename
  /// 5. On error: cleanup temp file
  Future<Note> uploadMediaAndCreateNote(
    Session session,
    int channelId,
    String noteContent,
    List<int> fileBytes,
    String originalFilename,
    String mimeType,
    bool compress,
  ) async {
    // Validate file size
    if (fileBytes.length > maxFileSize) {
      throw Exception(
        'File size exceeds maximum allowed size of ${maxFileSize ~/ (1024 * 1024)}MB',
      );
    }

    // Validate filename length
    if (originalFilename.length > 255) {
      throw Exception('Filename too long (max 255 characters)');
    }

    // Validate note content length
    if (noteContent.length > 50000) {
      throw Exception('Note content too long (max 50,000 characters)');
    }

    // Verify channel exists
    final channel = await Channel.db.findById(session, channelId);
    if (channel == null) {
      throw Exception('Channel not found: $channelId');
    }

    // Generate UUID-based filename, preferring the original file's extension
    final uuid = Uuid().v4();
    final originalExt = path.extension(originalFilename).toLowerCase();
    final extension = originalExt.isNotEmpty
        ? originalExt
        : _getExtensionFromMimeType(mimeType);
    final filename = '$uuid$extension';
    final tempFilename = '$uuid.tmp';

    // Create channel-specific directory
    // Use local data directory in development, /app/media in production
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

    final tempFilePath = path.join(channelDir.path, tempFilename);
    final finalFilePath = path.join(channelDir.path, filename);

    // Phase 1: Write to temporary file
    final tempFile = File(tempFilePath);

    try {
      await tempFile.writeAsBytes(fileBytes);

      // Phase 2: Process file based on type
      final bool isImage = _isImage(mimeType);
      final bool isVideo = _isVideo(mimeType);
      late final String resultFilePath;
      int? width;
      int? height;
      double? duration;
      String? thumbnailPath;
      bool compressed = false;
      bool animated = false;
      String? contentHash;

      if (isImage) {
        // Process image (compression, thumbnails, EXIF handling)
        final result = await ImageProcessor.processImage(
          tempFilePath: tempFilePath,
          finalFilePath: finalFilePath,
          channelDir: channelDir.path,
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
        // Process video (compression, thumbnails, metadata extraction)
        final result = await VideoProcessor.processVideo(
          tempFilePath: tempFilePath,
          finalFilePath: finalFilePath,
          channelDir: channelDir.path,
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
        // For documents, just rename temp file to final path
        await tempFile.rename(finalFilePath);
        resultFilePath = finalFilePath;

        // Calculate content hash for cache busting
        final file = File(finalFilePath);
        final fileBytes = await file.readAsBytes();
        final digest = await ImageProcessor.calculateHash(fileBytes);
        contentHash = digest.substring(0, 8);
      }

      // Phase 3: Create note and attachment in transaction
      final note = await session.db.transaction((transaction) async {
        // Create note
        final newNote = Note(
          channelId: channelId,
          content: noteContent,
        );
        final savedNote = await Note.db.insertRow(
          session,
          newNote,
          transaction: transaction,
        );

        // Create attachment linked to note
        final relativePath = path.relative(
          resultFilePath,
          from: mediaBaseDir.path,
        );

        final attachment = MediaAttachment(
          noteId: savedNote.id!,
          channelId: channelId,
          filePath: relativePath,
          originalFilename: originalFilename,
          mimeType: mimeType,
          fileSize: fileBytes.length,
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

        // Attach to note
        savedNote.attachments = [attachment];

        // Update channel timestamp
        channel.updatedAt = DateTime.now();
        await Channel.db.updateRow(session, channel, transaction: transaction);

        return savedNote;
      });

      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(
          type: 'noteCreated',
          note: note,
        ),
      );

      return note;
    } catch (e) {
      // Cleanup on error
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final finalFile = File(finalFilePath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      session.log('Media upload failed: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Upload a media file with streaming (for future use).
  ///
  /// Uses two-phase commit:
  /// 1. Stream to temporary file
  /// 2. Process image
  /// 3. Insert database record
  /// 4. Rename to final filename
  /// 5. On error: cleanup temp file
  Future<MediaAttachment> uploadMedia(
    Session session,
    int channelId,
    String originalFilename,
    String mimeType,
    bool compress,
    Stream<List<int>> fileStream,
  ) async {
    // Verify channel exists
    final channel = await Channel.db.findById(session, channelId);
    if (channel == null) {
      throw Exception('Channel not found: $channelId');
    }

    // Generate UUID-based filename, preferring the original file's extension
    final uuid = Uuid().v4();
    final originalExt = path.extension(originalFilename).toLowerCase();
    final extension = originalExt.isNotEmpty
        ? originalExt
        : _getExtensionFromMimeType(mimeType);
    final filename = '$uuid$extension';
    final tempFilename = '$uuid.tmp';

    // Create channel-specific directory
    // Use local data directory in development, /app/media in production
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

    final tempFilePath = path.join(channelDir.path, tempFilename);
    final finalFilePath = path.join(channelDir.path, filename);

    // Phase 1: Stream to temporary file
    final tempFile = File(tempFilePath);
    var totalBytes = 0;

    try {
      final sink = tempFile.openWrite();

      await for (final chunk in fileStream) {
        totalBytes += chunk.length;

        // Enforce size limit
        if (totalBytes > maxFileSize) {
          await sink.close();
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
          throw Exception(
            'File size exceeds maximum allowed size of ${maxFileSize ~/ (1024 * 1024)}MB',
          );
        }

        sink.add(chunk);
      }

      await sink.flush();
      await sink.close();

      // Phase 2: Process image in isolate
      final result = await ImageProcessor.processImage(
        tempFilePath: tempFilePath,
        finalFilePath: finalFilePath,
        channelDir: channelDir.path,
        compress: compress,
      );

      // Phase 3: Insert database record
      final relativePath = path.relative(
        result.filePath,
        from: mediaBaseDir.path,
      );

      final attachment = MediaAttachment(
        noteId: 0, // Will be set when creating note
        channelId: channelId,
        filePath: relativePath,
        originalFilename: originalFilename,
        mimeType: mimeType,
        fileSize: totalBytes,
        width: result.width,
        height: result.height,
        duration: null, // Only set for videos
        thumbnailPath: result.thumbnailPath,
        compressed: result.compressed,
        animated: result.animated,
        contentHash: result.contentHash,
      );

      // Insert to database
      await MediaAttachment.db.insertRow(session, attachment);

      return attachment;
    } catch (e) {
      // Cleanup on error
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      final finalFile = File(finalFilePath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      session.log('Media upload failed: $e', level: LogLevel.error);
      rethrow;
    }
  }

  /// Get file extension from MIME type.
  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType.toLowerCase()) {
      // Images
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

      // Videos
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

      // Documents
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
        // Try to extract from original filename or fallback
        return '.bin';
    }
  }

  /// Check if MIME type is an image.
  bool _isImage(String mimeType) {
    return allowedImageTypes.contains(mimeType.toLowerCase());
  }

  /// Check if MIME type is a video.
  bool _isVideo(String mimeType) {
    return allowedVideoTypes.contains(mimeType.toLowerCase());
  }

  /// Delete a media attachment and its files.
  Future<void> deleteAttachment(Session session, int attachmentId) async {
    final attachment = await MediaAttachment.db.findById(session, attachmentId);
    if (attachment == null) {
      throw Exception('Attachment not found: $attachmentId');
    }

    // Delete files
    // Use local data directory in development, /app/media in production
    final mediaBaseDir = Directory(ServerConstants.mediaBaseDir);
    final filePath = path.join(mediaBaseDir.path, attachment.filePath);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Delete thumbnail
    if (attachment.thumbnailPath != null) {
      final thumbnailPath = path.join(
        mediaBaseDir.path,
        'channels',
        attachment.channelId.toString(),
        attachment.thumbnailPath!,
      );
      final thumbnailFile = File(thumbnailPath);
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
      }
    }

    // Delete database record
    await MediaAttachment.db.deleteRow(session, attachment);
  }
}
