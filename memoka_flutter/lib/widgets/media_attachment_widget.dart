import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memoka_client/memoka_client.dart';

import '../utils/file_utils.dart';
import 'document_attachment_widget.dart';
import 'full_screen_image_view.dart';
import 'video_attachment_widget.dart';

/// Widget for displaying a media attachment inline in chat.
/// Routes to either image or document widget based on MIME type.
class MediaAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;
  final List<String> allImageUrls;
  final int initialImageIndex;

  const MediaAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
    this.allImageUrls = const [],
    this.initialImageIndex = 0,
  });

  bool get _isImage {
    final mime = attachment.mimeType.toLowerCase();
    return mime.startsWith('image/');
  }

  bool get _isVideo {
    final mime = attachment.mimeType.toLowerCase();
    return mime.startsWith('video/');
  }

  @override
  Widget build(BuildContext context) {
    // Route to appropriate widget based on type
    if (_isImage) {
      return _ImageAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
        allImageUrls: allImageUrls,
        initialImageIndex: initialImageIndex,
      );
    } else if (_isVideo) {
      return VideoAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
      );
    } else {
      return DocumentAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
      );
    }
  }
}

/// Internal widget for displaying image attachments.
class _ImageAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;
  final List<String> allImageUrls;
  final int initialImageIndex;

  const _ImageAttachmentWidget({
    required this.attachment,
    required this.serverUrl,
    required this.allImageUrls,
    required this.initialImageIndex,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _buildImageUrl(useThumbnail: false);
    final fullImageUrl = _buildImageUrl(useThumbnail: false);

    return GestureDetector(
      onTap: () {
        FullScreenImageView.show(
          context,
          imageUrls: allImageUrls.isNotEmpty ? allImageUrls : [fullImageUrl],
          initialIndex: allImageUrls.isNotEmpty ? initialImageIndex : 0,
        );
      },
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 500,
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[800],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) {
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${error.toString().substring(0, 50)}...',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Compressed indicator
          if (attachment.compressed)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.compress, color: Colors.white70, size: 12),
                    SizedBox(width: 3),
                    Text(
                      'Compressed',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build image URL with cache busting.
  String _buildImageUrl({required bool useThumbnail}) {
    String path = attachment.filePath;

    // Use thumbnail if available and requested
    if (useThumbnail && attachment.thumbnailPath != null) {
      // Thumbnail path is relative to channel directory
      final parts = attachment.filePath.split('/');
      if (parts.length >= 2) {
        final channelPath = parts.take(parts.length - 1).join('/');
        path = '$channelPath/${attachment.thumbnailPath}';
      }
    }

    return FileUtils.buildMediaUrl(serverUrl, path, attachment.contentHash);
  }
}
