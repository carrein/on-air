import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
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
            PhosphorIcon(
              PhosphorIcons.linkBreak(),
              size: 32,
              color: Color(0xFF00171F).withValues(alpha: 0.6),
            ),
            const SizedBox(height: 14),
            Text(
              'No links',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF00171F).withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
