import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:on_air_client/on_air_client.dart';
import '../main.dart';
import '../services/media_service.dart';

part 'media_provider.g.dart';

/// Provider for media upload operations.
@riverpod
class MediaUpload extends _$MediaUpload {
  @override
  FutureOr<void> build() {}

  /// Upload an image and create a note with it.
  Future<Note> uploadImageAndCreateNote({
    required int channelId,
    required String noteContent,
    required Uint8List imageBytes,
    required String fileName,
    required bool compress,
  }) async {
    // Validate file size
    if (!MediaService.validateFileSize(imageBytes.length)) {
      throw Exception('File size exceeds 100MB limit');
    }

    // Get MIME type
    final mimeType = MediaService.getMimeTypeFromExtension(fileName);

    // Optionally compress
    Uint8List finalBytes = imageBytes;
    if (compress) {
      final compressed = await MediaService.compressImageBytes(
        imageBytes,
        format: fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpg',
      );
      if (compressed != null) {
        finalBytes = compressed;
      }
    }

    // Upload to server
    final note = await client.media.uploadMediaAndCreateNote(
      channelId,
      noteContent,
      finalBytes,
      fileName,
      mimeType,
      compress,
    );

    return note;
  }
}
