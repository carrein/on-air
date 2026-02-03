import 'package:flutter/material.dart';
import 'package:on_air_client/on_air_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/file_utils.dart';

/// Widget to display document attachments (PDF, TXT, DOC, etc.)
class DocumentAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  const DocumentAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
  });

  String get _extension => FileUtils.getExtension(attachment.originalFilename);

  IconData get _fileIcon => FileUtils.getFileIcon(_extension);

  Color get _fileColor => FileUtils.getFileColor(_extension);

  String get _fileSizeFormatted => FileUtils.formatFileSize(attachment.fileSize);

  String _buildDocumentUrl() =>
      FileUtils.buildMediaUrl(serverUrl, attachment.filePath, attachment.contentHash);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleDownload,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // File icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _fileColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    _fileIcon,
                    color: _fileColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.originalFilename,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fileSizeFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Download button
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _handleDownload,
                  tooltip: 'Download',
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDownload() async {
    final url = _buildDocumentUrl();
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
