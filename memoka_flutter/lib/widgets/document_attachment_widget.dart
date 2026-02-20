import 'package:flutter/material.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/file_utils.dart';
import 'icon_button_styled.dart';

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

  String get _fileSizeFormatted => FileUtils.formatFileSize(attachment.fileSize);

  String _buildDocumentUrl() =>
      FileUtils.buildMediaUrl(serverUrl, attachment.filePath, attachment.contentHash);

  static const _textPrimary = Color(0xFF00171F);

  @override
  Widget build(BuildContext context) {
    return Row(
          children: [
            PhosphorIcon(_fileIcon, color: _textPrimary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.originalFilename,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _fileSizeFormatted,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            IconButtonStyled(
              icon: PhosphorIcons.downloadSimple(),
              onPressed: _handleDownload,
              size: 20,
            ),
          ],
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
