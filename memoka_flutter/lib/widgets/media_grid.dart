import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/channel_media.dart';
import 'media_grid_item.dart';
import 'media_panel_empty_state.dart';

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

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 1.0,
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
        message = 'No images';
        icon = PhosphorIcons.image(PhosphorIconsStyle.bold);
        break;
      case MediaType.video:
        message = 'No videos';
        icon = PhosphorIcons.video(PhosphorIconsStyle.bold);
        break;
      case MediaType.document:
        message = 'No documents';
        icon = PhosphorIcons.file(PhosphorIconsStyle.bold);
        break;
    }

    return MediaPanelEmptyState(icon: icon, message: message);
  }
}
