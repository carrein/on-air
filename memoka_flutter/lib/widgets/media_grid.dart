import 'package:flutter/material.dart';
import '../models/channel_media.dart';
import '../utils/responsive_utils.dart';
import 'media_grid_item.dart';

enum MediaType {
  image,
  video,
  document,
}

/// Grid display for media items (images, videos, or documents).
class MediaGrid extends StatelessWidget {
  final List<MediaItem> items;
  final MediaType type;

  const MediaGrid({
    super.key,
    required this.items,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    final columnCount = ResponsiveUtils.getGridColumnCount(
      context,
      isDocument: type == MediaType.document,
    );
    final spacing = ResponsiveUtils.getGridSpacing(context);

    return GridView.builder(
      padding: EdgeInsets.all(spacing),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
        childAspectRatio: type == MediaType.document ? 1.2 : 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return MediaGridItem(
          item: items[index],
          type: type,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    String message;
    IconData icon;

    switch (type) {
      case MediaType.image:
        message = 'No images in this channel yet';
        icon = Icons.image_outlined;
        break;
      case MediaType.video:
        message = 'No videos in this channel yet';
        icon = Icons.videocam_outlined;
        break;
      case MediaType.document:
        message = 'No documents in this channel yet';
        icon = Icons.description_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
