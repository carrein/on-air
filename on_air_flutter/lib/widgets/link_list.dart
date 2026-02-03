import 'package:flutter/material.dart';
import '../models/channel_media.dart';
import 'link_list_item.dart';

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No links in this channel yet',
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
