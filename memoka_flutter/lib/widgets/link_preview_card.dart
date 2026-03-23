import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show serverUrl;
import '../utils/file_utils.dart';
import 'app_spinner.dart';

/// Card widget displaying link preview metadata below a message.
class LinkPreviewCard extends StatelessWidget {
  final LinkPreview preview;

  const LinkPreviewCard({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF00171F);
    const fg = Colors.white;

    return Card(
      margin: const EdgeInsets.only(top: 2),
      elevation: 0,
      color: bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openLink(preview.url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (if available and resolvable)
            if (FileUtils.resolvePreviewUrl(serverUrl, preview.imageUrl)
                case final resolvedImageUrl?)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: resolvedImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: bg,
                    child: Center(child: AppSpinner()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: bg,
                    child: Center(
                      child: PhosphorIcon(
                        PhosphorIcons.imageBroken(),
                        size: 48,
                        color: fg,
                      ),
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
                        color: fg,
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
                        color: fg,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // URL with favicon
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (FileUtils.resolvePreviewUrl(
                            serverUrl,
                            preview.faviconUrl,
                          )
                          case final resolvedFaviconUrl?)
                        CachedNetworkImage(
                          imageUrl: resolvedFaviconUrl,
                          width: 16,
                          height: 16,
                          errorWidget: (context, url, error) => PhosphorIcon(
                            PhosphorIcons.globe(),
                            size: 16,
                            color: fg,
                          ),
                        )
                      else
                        PhosphorIcon(
                          PhosphorIcons.globe(),
                          size: 16,
                          color: fg,
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _extractDomain(preview.url),
                          style: TextStyle(
                            fontSize: 11,
                            color: fg,
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
