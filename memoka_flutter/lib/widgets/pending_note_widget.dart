import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/pending_uploads_provider.dart';
import '../utils/file_utils.dart';
import '../utils/responsive_utils.dart';
import 'app_spinner.dart';
import 'media_attachment_widget.dart';

/// Standard footer height shared by: timestamp+actions, shimmer, progress bar.
/// Keeps card height stable across ghost → loaded transitions.
const kFooterHeight = 24.0;

/// Ghost note shown while a file is uploading or after a failed upload.
///
/// For image uploads: local preview with dark overlay and spinner, sized to
/// match the final NoteItem media dimensions. Ghost is removed on upload
/// success and NoteItem takes over seamlessly.
///
/// For non-image uploads: card with progress bar + cancel.
class PendingNoteWidget extends ConsumerWidget {
  const PendingNoteWidget({super.key, required this.upload});

  final PendingUpload upload;

  static const _borderColor = Color(0xFF3450A3);
  static const _bgColor = Color(0xFFFFFDF6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isError = upload.status == UploadStatus.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child:
                upload.isImage ||
                    (upload.isVideo && upload.thumbnailBytes != null)
                ? _buildMediaUploadingBox(ref, isError)
                : NoteConstraints(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _bgColor,
                        border: Border.all(color: _borderColor, width: 1.0),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilePreview(),
                          const SizedBox(height: 8),
                          _buildUploadFooter(ref, isError),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaUploadingBox(WidgetRef ref, bool isError) {
    final displaySize = computeDisplaySize(
      width: upload.mediaWidth,
      height: upload.mediaHeight,
      maxWidth: kMediaNoteMaxWidth,
      maxHeight: kMediaNoteMaxHeight,
    );

    return SizedBox(
      width: displaySize.width,
      height: displaySize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildLocalPreview(),
          Container(color: Colors.black.withValues(alpha: 0.3)),
          Center(
            child: isError
                ? _buildMediaErrorContent(ref)
                : const AppSpinner(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview() {
    // Video thumbnail (from upload dialog).
    if (upload.isVideo && upload.thumbnailBytes != null) {
      return Image.memory(
        upload.thumbnailBytes!,
        fit: BoxFit.cover,
        cacheWidth: 1200,
        errorBuilder: (_, _, _) => Container(color: Colors.grey[300]),
      );
    }
    if (!kIsWeb && upload.localFilePath != null) {
      return Image.file(
        File(upload.localFilePath!),
        fit: BoxFit.cover,
        cacheWidth: 1200,
        errorBuilder: (_, _, _) => Container(color: Colors.grey[300]),
      );
    }
    if (upload.localBytes != null) {
      return Image.memory(
        upload.localBytes!,
        fit: BoxFit.cover,
        cacheWidth: 1200,
        errorBuilder: (_, _, _) => Container(color: Colors.grey[300]),
      );
    }
    return Container(color: Colors.grey[300]);
  }

  Widget _buildMediaErrorContent(WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(
          PhosphorIcons.warning(),
          size: 24,
          color: const Color(0xFFDB0000),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload failed',
          style: TextStyle(fontSize: 12, color: Color(0xFFDB0000)),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FooterButton(
              label: 'Retry',
              onTap: () =>
                  ref.read(pendingUploadsProvider.notifier).retry(upload.id),
            ),
            const SizedBox(width: 16),
            _FooterButton(
              label: 'Dismiss',
              onTap: () =>
                  ref.read(pendingUploadsProvider.notifier).remove(upload.id),
            ),
          ],
        ),
      ],
    );
  }

  /// Fixed-height footer with progress bar + byte count + cancel/retry.
  /// Height matches [kFooterHeight] so transitions don't cause layout jumps.
  Widget _buildUploadFooter(WidgetRef ref, bool isError) {
    if (isError) {
      return SizedBox(
        height: kFooterHeight,
        child: Row(
          children: [
            PhosphorIcon(
              PhosphorIcons.warning(),
              size: 14,
              color: const Color(0xFFDB0000),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Upload failed',
                style: const TextStyle(fontSize: 11, color: Color(0xFFDB0000)),
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
        ),
      );
    }

    return SizedBox(
      height: kFooterHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: upload.progress > 0 ? upload.progress : null,
            color: _borderColor,
            backgroundColor: _borderColor.withValues(alpha: 0.15),
            minHeight: 2,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  _progressText(),
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF00171F).withValues(alpha: 0.5),
                  ),
                ),
              ),
              _FooterButton(
                label: 'Cancel',
                onTap: () =>
                    ref.read(pendingUploadsProvider.notifier).cancel(upload.id),
              ),
            ],
          ),
        ],
      ),
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
            PhosphorIcon(
              icon,
              size: 32,
              color: const Color(0xFF00171F).withValues(alpha: 0.6),
            ),
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
      ],
    );
  }

  String _progressText() {
    if (upload.fileSize <= 0) return 'Uploading\u2026';
    final total = FileUtils.formatFileSize(upload.fileSize);
    if (upload.progress > 0) {
      final uploaded = FileUtils.formatFileSize(
        (upload.progress * upload.fileSize).round(),
      );
      return '$uploaded / $total';
    }
    return '0 B / $total';
  }
}

/// On mobile viewports, notes span full width; on desktop, capped at 600px.
/// Shared by [NoteItem] and [PendingNoteWidget].
class NoteConstraints extends StatelessWidget {
  const NoteConstraints({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final constrained = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isMobile ? screenWidth - 28 : 600,
        minWidth: isMobile ? screenWidth - 28 : 350,
      ),
      child: child,
    );
    if (isMobile) return constrained;
    return IntrinsicWidth(child: constrained);
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
            color: Color(0xFF3450A3),
          ),
        ),
      ),
    );
  }
}
