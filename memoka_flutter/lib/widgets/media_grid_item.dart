import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/channel_media.dart';
import '../main.dart' show serverUrl;
import '../providers/scroll_to_note_provider.dart';
import '../utils/file_utils.dart';
import 'media_grid.dart';
import 'app_spinner.dart';

/// Individual grid item displaying a media thumbnail or document card.
class MediaGridItem extends ConsumerWidget {
  final MediaItem item;
  final MediaType type;

  const MediaGridItem({
    super.key,
    required this.item,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => _handleTap(context, ref),
      child: Container(
        color: Colors.white,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (type) {
      case MediaType.image:
        return _buildImageContent();
      case MediaType.video:
        return _buildVideoContent();
      case MediaType.document:
        return _buildDocumentContent();
    }
  }

  Widget _buildImageContent() {
    final imageUrl = item.getMediaUrl(serverUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          cacheWidth: 400,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorPlaceholder(
              PhosphorIcons.imageBroken(),
              'Failed to load',
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingPlaceholder();
          },
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    final thumbnailUrl = item.getThumbnailUrl(serverUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null)
          Image.network(
            thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPlaceholder(
                PhosphorIcons.video(),
                'No preview',
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _buildLoadingPlaceholder();
            },
          )
        else
          _buildErrorPlaceholder(PhosphorIcons.video(), 'No preview'),

        // Play icon overlay
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: PhosphorIcon(
              PhosphorIcons.play(),
              color: Colors.white,
              size: 32,
            ),
          ),
        ),

        // Duration overlay (if available)
        if (item.attachment.duration != null)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                FileUtils.formatDuration(item.attachment.duration!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentContent() {
    final extension = item.attachment.filePath.split('.').last;
    final icon = FileUtils.getFileIcon(extension);
    final sizeFormatted = FileUtils.formatFileSize(item.attachment.fileSize);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 36,
            color: const Color(0xFF00171F).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              item.attachment.originalFilename,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sizeFormatted,
            style: TextStyle(
              fontSize: 9,
              color: const Color(0xFF00171F).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: AppSpinner(size: 16),
      ),
    );
  }

  Widget _buildErrorPlaceholder(IconData icon, String message) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: const Color(0xFF00171F).withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFF00171F).withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    // Scroll to the note containing this media item
    ref.read(scrollToNoteProvider.notifier).state = item.noteId;
  }
}
