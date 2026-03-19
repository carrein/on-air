import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/channel_media.dart';
import 'link_list_item.dart';
import 'media_panel_empty_state.dart';

/// Vertical list display for link previews.
class LinkList extends StatelessWidget {
  final List<LinkItem> links;

  const LinkList({
    super.key,
    required this.links,
  });

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: links.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return LinkListItem(link: links[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return MediaPanelEmptyState(
      icon: PhosphorIcons.linkSimple(PhosphorIconsStyle.bold),
      message: 'No links',
    );
  }
}
