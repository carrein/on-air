import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:on_air_client/on_air_client.dart';
import 'full_screen_image_view.dart';
import 'document_attachment_widget.dart';

/// Widget for displaying a media attachment inline in chat.
/// Routes to either image or document widget based on MIME type.
class MediaAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  const MediaAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
  });

  bool get _isImage {
    final mime = attachment.mimeType.toLowerCase();
    return mime.startsWith('image/');
  }

  @override
  Widget build(BuildContext context) {
    // Route to appropriate widget based on type
    if (_isImage) {
      return _ImageAttachmentWidget(
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

  const _ImageAttachmentWidget({
    required this.attachment,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Build URL with cache busting using content hash
    final imageUrl = _buildImageUrl(useThumbnail: true);
    final fullImageUrl = _buildImageUrl(useThumbnail: false);

    return GestureDetector(
      onTap: () {
        // Open full screen viewer
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenImageView(
              imageUrl: fullImageUrl,
              heroTag: 'media_${attachment.id}',
            ),
          ),
        );
      },
      child: Hero(
        tag: 'media_${attachment.id}',
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 300,
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
              print('=== Image Load Error ===');
              print('URL: $url');
              print('Error: $error');
              print('Error type: ${error.runtimeType}');
              print('=======================');
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
                        style: const TextStyle(color: Colors.red, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build image URL with cache busting.
  String _buildImageUrl({required bool useThumbnail}) {
    String path = attachment.filePath;

    print('=== MediaAttachment Debug ===');
    print('Attachment ID: ${attachment.id}');
    print('Original filePath: ${attachment.filePath}');
    print('thumbnailPath: ${attachment.thumbnailPath}');
    print('useThumbnail: $useThumbnail');

    // Use thumbnail if available and requested
    if (useThumbnail && attachment.thumbnailPath != null) {
      // Thumbnail path is relative to channel directory
      final parts = attachment.filePath.split('/');
      print('filePath parts: $parts');
      if (parts.length >= 2) {
        final channelPath = parts.take(parts.length - 1).join('/');
        path = '$channelPath/${attachment.thumbnailPath}';
        print('Constructed thumbnail path: $path');
      }
    }

    // Media is served from web server (port 8082 in dev)
    // Replace the API server port with web server port
    final mediaServerUrl = serverUrl.replaceAll(':8080', ':8082');
    print('Server URL: $serverUrl');
    print('Media Server URL: $mediaServerUrl');

    // Add cache busting parameter
    final cacheBuster = attachment.contentHash ?? '';
    final finalUrl = '$mediaServerUrl/media/$path?v=$cacheBuster';
    print('Final URL: $finalUrl');
    print('============================');

    return finalUrl;
  }
}
