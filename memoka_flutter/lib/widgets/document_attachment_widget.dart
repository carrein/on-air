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

  DownloadHandle? _downloadHandle;
  int _receivedBytes = 0;
  int _totalBytes = -1;

  bool get _isDownloading => _downloadHandle != null;

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
  void dispose() {
    _downloadHandle?.cancel();
    super.dispose();
  }

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
              icon: _isDownloading
                  ? PhosphorIcons.x()
                  : PhosphorIcons.downloadSimple(),
              onPressed: _isDownloading
                  ? _cancelDownload
                  : () => _handleDownload(context),
              size: 20,
            ),
          ],
        ),
        if (_isDownloading) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _totalBytes > 0 ? _receivedBytes / _totalBytes : null,
            color: _accent,
            backgroundColor: _accent.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 2),
          Text(
            _totalBytes > 0
                ? '${FileUtils.formatFileSize(_receivedBytes)} / ${FileUtils.formatFileSize(_totalBytes)}'
                : FileUtils.formatFileSize(_receivedBytes),
            style: TextStyle(
              fontSize: 10,
              color: _textPrimary.withValues(alpha: 0.5),
            ),
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

  void _cancelDownload() {
    _downloadHandle?.cancel();
    if (mounted) {
      setState(() {
        _downloadHandle = null;
        _receivedBytes = 0;
        _totalBytes = -1;
      });
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
      setState(() {
        _receivedBytes = 0;
        _totalBytes = -1;
      });
      _downloadHandle = DownloadUtils.downloadToDevice(
        context,
        url,
        widget.attachment.originalFilename,
        mimeType: widget.attachment.mimeType,
        onProgress: (received, total) {
          if (mounted) {
            setState(() {
              _receivedBytes = received;
              _totalBytes = total;
            });
          }
        },
        onComplete: () {
          if (mounted) {
            setState(() {
              _downloadHandle = null;
              _receivedBytes = 0;
              _totalBytes = -1;
            });
          }
        },
      );
    }
  }
}
