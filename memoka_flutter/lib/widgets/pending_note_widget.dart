import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/pending_uploads_provider.dart';
import '../utils/file_utils.dart';

/// Ghost note shown while a file is uploading or after a failed upload.
///
/// Matches the [NoteItem] card styling: border, background, padding, maxWidth.
class PendingNoteWidget extends ConsumerWidget {
  const PendingNoteWidget({super.key, required this.upload});

  final PendingUpload upload;

  static const _borderColor = Color(0xFFCE2161);
  static const _bgColor = Color(0xFFF6F0ED);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isError = upload.status == UploadStatus.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: IntrinsicWidth(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600, minWidth: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _bgColor,
                      border: Border.all(color: _borderColor, width: 1.0),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPreview(),
                        const SizedBox(height: 8),
                        _buildFooter(ref, isError),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (upload.isImage) {
      return _buildImagePreview();
    }
    return _buildFilePreview();
  }

  Widget _buildImagePreview() {
    Widget image;
    if (!kIsWeb && upload.localFilePath != null) {
      image = Image.file(
        File(upload.localFilePath!),
        fit: BoxFit.contain,
        cacheWidth: 600,
      );
    } else if (upload.localBytes != null) {
      image = Image.memory(
        upload.localBytes!,
        fit: BoxFit.contain,
        cacheWidth: 600,
      );
    } else {
      image = const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300, maxHeight: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Opacity(
              opacity: upload.status == UploadStatus.error ? 0.5 : 0.8,
              child: image,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (upload.status == UploadStatus.uploading)
          LinearProgressIndicator(
            value: upload.progress > 0 ? upload.progress : null,
            color: _borderColor,
            backgroundColor: _borderColor.withValues(alpha: 0.15),
          ),
        if (upload.status == UploadStatus.error)
          LinearProgressIndicator(
            value: 1.0,
            color: Colors.red,
            backgroundColor: Colors.red.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _buildFilePreview() {
    final icon = upload.isVideo
        ? PhosphorIcons.filmStrip()
        : FileUtils.getFileIcon(upload.fileExtension);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PhosphorIcon(icon, size: 32, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                upload.fileName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF00171F),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (upload.status == UploadStatus.uploading)
          LinearProgressIndicator(
            value: upload.progress > 0 ? upload.progress : null,
            color: _borderColor,
            backgroundColor: _borderColor.withValues(alpha: 0.15),
          ),
        if (upload.status == UploadStatus.error)
          LinearProgressIndicator(
            value: 1.0,
            color: Colors.red,
            backgroundColor: Colors.red.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _buildFooter(WidgetRef ref, bool isError) {
    if (isError) {
      return Row(
        children: [
          PhosphorIcon(PhosphorIcons.warning(), size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Upload failed',
              style: TextStyle(fontSize: 11, color: Colors.red[700]),
            ),
          ),
          _FooterButton(
            label: 'Retry',
            onTap: () =>
                ref.read(pendingUploadsProvider.notifier).retry(upload.id),
          ),
          const SizedBox(width: 8),
          _FooterButton(
            label: 'Dismiss',
            onTap: () =>
                ref.read(pendingUploadsProvider.notifier).remove(upload.id),
          ),
        ],
      );
    }

    return Text(
      'Uploading\u2026',
      style: TextStyle(
        fontSize: 11,
        color: const Color(0xFF00171F).withValues(alpha: 0.5),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFFCE2161),
          ),
        ),
      ),
    );
  }
}
