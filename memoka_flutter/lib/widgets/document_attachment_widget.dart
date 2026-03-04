import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../utils/download_utils.dart';
import '../utils/file_utils.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';

/// Widget to display document attachments (PDF, APK, ZIP, etc.)
///
/// Native (Android): three states:
///   1. Not downloaded → download icon
///   2. Downloading → X (cancel) icon + progress bar
///   3. Downloaded → eye (open) icon + floppy disk (save) icon
///
/// Web: always shows eye (open in browser) + download (browser save).
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
  String? _cachedPath;
  int _receivedBytes = 0;
  int _totalBytes = -1;

  bool get _isDownloading => _downloadHandle != null;
  bool get _isDownloaded => _cachedPath != null;

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
  void initState() {
    super.initState();
    if (!kIsWeb) _checkCache();
  }

  @override
  void dispose() {
    // Do NOT cancel downloads — let them finish in the background so the file
    // is cached when the user switches back. Callbacks guard with `mounted`.
    super.dispose();
  }

  Future<void> _checkCache() async {
    final path = await DownloadUtils.getCachedPath(
      widget.attachment.originalFilename,
    );
    if (path != null && mounted) {
      setState(() => _cachedPath = path);
    }
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
            if (kIsWeb) ..._buildWebActions() else ..._buildNativeActions(),
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

  // -- Web: eye (open in browser) + download (browser save) --

  List<Widget> _buildWebActions() {
    return [
      IconButtonStyled(
        icon: PhosphorIcons.eye(),
        onPressed: _handleWebPreview,
        size: IconButtonStyled.sm,
      ),
      const SizedBox(width: 4),
      IconButtonStyled(
        icon: PhosphorIcons.downloadSimple(),
        onPressed: _handleWebDownload,
        size: IconButtonStyled.sm,
      ),
    ];
  }

  Future<void> _handleWebPreview() async {
    final url = _buildDocumentUrl();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _handleWebDownload() {
    final url = _buildDocumentUrl();
    html.AnchorElement()
      ..href = url
      ..setAttribute('download', widget.attachment.originalFilename)
      ..click();
  }

  // -- Native: download → cancel → eye + floppy disk --

  List<Widget> _buildNativeActions() {
    if (_isDownloaded) {
      // Downloaded: eye (open) + floppy disk (save to device)
      return [
        IconButtonStyled(
          icon: PhosphorIcons.eye(),
          onPressed: _handleOpen,
          size: IconButtonStyled.sm,
        ),
        const SizedBox(width: 4),
        IconButtonStyled(
          icon: PhosphorIcons.floppyDisk(),
          onPressed: _handleSave,
          size: IconButtonStyled.sm,
        ),
      ];
    }
    if (_isDownloading) {
      // Downloading: X (cancel)
      return [
        IconButtonStyled(
          icon: PhosphorIcons.x(),
          onPressed: _cancelDownload,
          size: IconButtonStyled.sm,
        ),
      ];
    }
    // Not downloaded: download icon
    return [
      IconButtonStyled(
        icon: PhosphorIcons.downloadSimple(),
        onPressed: _startDownload,
        size: IconButtonStyled.sm,
      ),
    ];
  }

  void _startDownload() {
    final url = _buildDocumentUrl();
    setState(() {
      _receivedBytes = 0;
      _totalBytes = -1;
    });
    _downloadHandle = DownloadUtils.downloadToCache(
      url,
      widget.attachment.originalFilename,
      onProgress: (received, total) {
        if (mounted) {
          setState(() {
            _receivedBytes = received;
            _totalBytes = total;
          });
        }
      },
      onSuccess: (path) {
        if (mounted) {
          setState(() {
            _cachedPath = path;
            _downloadHandle = null;
            _receivedBytes = 0;
            _totalBytes = -1;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _downloadHandle = null;
            _receivedBytes = 0;
            _totalBytes = -1;
          });
          ToastUtils.show(
            context,
            'Download failed: $error',
            type: ToastType.error,
          );
        }
      },
    );
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

  Future<void> _handleOpen() async {
    if (_cachedPath == null) return;
    final ok = await DownloadUtils.openFile(_cachedPath!);
    if (!ok && mounted) {
      ToastUtils.show(context, 'Could not open file', type: ToastType.error);
    }
  }

  Future<void> _handleSave() async {
    if (_cachedPath == null) return;
    final saved = await DownloadUtils.saveFile(
      _cachedPath!,
      widget.attachment.originalFilename,
    );
    if (mounted) {
      if (saved) {
        ToastUtils.show(context, 'File saved', type: ToastType.success);
      } else {
        ToastUtils.show(context, 'Save cancelled', type: ToastType.info);
      }
    }
  }
}
