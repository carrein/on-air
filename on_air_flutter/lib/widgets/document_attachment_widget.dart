import 'package:flutter/material.dart';
import 'package:on_air_client/on_air_client.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget to display document attachments (PDF, TXT, DOC, etc.)
class DocumentAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  const DocumentAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
  });

  IconData get _fileIcon {
    final ext = _getExtension(attachment.originalFilename).toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'md':
        return Icons.description;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get _fileColor {
    final ext = _getExtension(attachment.originalFilename).toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.red;
      case 'txt':
      case 'md':
        return Colors.blue;
      case 'doc':
      case 'docx':
        return Colors.indigo;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'zip':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  String get _fileSizeFormatted {
    final bytes = attachment.fileSize;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _buildDocumentUrl() {
    final mediaServerUrl = serverUrl.replaceAll(':8080', ':8082');
    final cacheBuster = attachment.contentHash ?? '';
    return '$mediaServerUrl/media/${attachment.filePath}?v=$cacheBuster';
  }

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
