import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/channel_media.dart';

/// Individual list item displaying a link preview card.
class LinkListItem extends StatelessWidget {
  final LinkItem link;

  const LinkListItem({
    super.key,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _handleTap(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and favicon row
              Row(
                children: [
                  if (link.faviconUrl != null) ...[
                    Image.network(
                      link.faviconUrl!,
                      width: 16,
                      height: 16,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.language, size: 16, color: Colors.grey[600]);
                      },
                    ),
                    const SizedBox(width: 8),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.language, size: 16, color: Colors.grey[600]),
                    ),
                  Expanded(
                    child: Text(
                      link.displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.open_in_new, size: 14, color: Colors.grey[500]),
                ],
              ),

              // Description (if available)
              if (link.description != null && link.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  link.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ] else if (!link.hasFullPreview) ...[
                // Show URL as description if no preview
                const SizedBox(height: 6),
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],

              // URL (only show if we have a full preview, otherwise it's already shown above)
              if (link.hasFullPreview) ...[
                const SizedBox(height: 6),
                Text(
                  _formatUrl(link.url),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                  ),
                ),
              ],

              // Date
              const SizedBox(height: 6),
              Text(
                _formatDate(link.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  Future<void> _handleTap(BuildContext context) async {
    try {
      final uri = Uri.parse(link.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open link: ${link.url}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
}
