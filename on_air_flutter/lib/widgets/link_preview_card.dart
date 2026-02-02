import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_air_client/on_air_client.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card widget displaying link preview metadata below a message.
class LinkPreviewCard extends StatelessWidget {
  final LinkPreview preview;

  const LinkPreviewCard({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLink(preview.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available)
            if (preview.imageUrl != null)
              CachedNetworkImage(
                imageUrl: preview.imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 160,
                  color: Colors.grey[100],
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  if (preview.title != null)
                    Text(
                      preview.title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Description
                  if (preview.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // URL with favicon
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (preview.faviconUrl != null)
                        CachedNetworkImage(
                          imageUrl: preview.faviconUrl!,
                          width: 16,
                          height: 16,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.language, size: 16),
                        )
                      else
                        const Icon(Icons.language, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _extractDomain(preview.url),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (_) {
      return url;
    }
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
