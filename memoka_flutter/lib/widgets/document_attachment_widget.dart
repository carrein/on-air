import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../utils/download_utils.dart';
import '../utils/file_utils.dart';
import 'icon_button_styled.dart';

/// Widget to display document attachments (PDF, TXT, DOC, etc.)
class DocumentAttachmentWidget extends StatefulWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  const DocumentAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
  });

  @override
  State<DocumentAttachmentWidget> createState() =>
      _DocumentAttachmentWidgetState();
}

class _DocumentAttachmentWidgetState extends State<DocumentAttachmentWidget> {
  static const _textPrimary = Color(0xFF00171F);
  static const _accent = Color(0xFFCE2161);

  /// null = not downloading; 0.0–1.0 = download progress.
  double? _downloadProgress;

  String get _extension =>
      FileUtils.getExtension(widget.attachment.originalFilename);

  IconData get _fileIcon => FileUtils.getFileIcon(_extension);

  String get _fileSizeFormatted =>
      FileUtils.formatFileSize(widget.attachment.fileSize);

  String _buildDocumentUrl() => FileUtils.buildMediaUrl(
    widget.serverUrl,
    widget.attachment.filePath,
    widget.attachment.contentHash,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PhosphorIcon(_fileIcon, color: _textPrimary, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.attachment.originalFilename,
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
            const SizedBox(width: 16),
            IconButtonStyled(
              icon: PhosphorIcons.handEye(),
              onPressed: _handlePreview,
              size: 20,
            ),
            const SizedBox(width: 4),
            IconButtonStyled(
              icon: PhosphorIcons.downloadSimple(),
              onPressed: _downloadProgress == null
                  ? () => _handleDownload(context)
                  : null,
              size: 20,
            ),
          ],
        ),
        if (_downloadProgress != null) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _downloadProgress! > 0 ? _downloadProgress : null,
            color: _accent,
            backgroundColor: _accent.withValues(alpha: 0.15),
          ),
        ],
      ],
    );
  }

  Future<void> _handlePreview() async {
    final url = _buildDocumentUrl();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleDownload(BuildContext context) {
    final url = _buildDocumentUrl();
    if (kIsWeb) {
      html.AnchorElement()
        ..href = url
        ..setAttribute('download', widget.attachment.originalFilename)
        ..click();
    } else {
      setState(() => _downloadProgress = 0.0);
      DownloadUtils.downloadToDevice(
        context,
        url,
        widget.attachment.originalFilename,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      ).whenComplete(() {
        if (mounted) setState(() => _downloadProgress = null);
      });
    }
  }
}
