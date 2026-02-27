import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/pending_uploads_provider.dart';
import '../utils/file_utils.dart';
import 'media_attachment_widget.dart';

/// Standard footer height shared by: timestamp+actions, shimmer, progress bar.
/// Keeps card height stable across ghost → loaded transitions.
const kFooterHeight = 24.0;

/// Ghost note shown while a file is uploading or after a failed upload.
///
/// Matches the [NoteItem] card styling: border, background, padding, maxWidth.
///
/// For image uploads, the lifecycle is two visual steps:
///   1. Skeleton + progress bar (during upload)
///   2. Real server image + timestamp+actions (once image loads from server)
/// Then NoteItem takes over seamlessly.
class PendingNoteWidget extends ConsumerWidget {
  const PendingNoteWidget({super.key, required this.upload});

  final PendingUpload upload;

  static const _borderColor = Color(0xFFCE2161);
  static const _bgColor = Color(0xFFF6F0ED);

  bool get _isGif => upload.mimeType.toLowerCase() == 'image/gif';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isError = upload.status == UploadStatus.error;
    final isUploaded = upload.status == UploadStatus.uploaded;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: NoteConstraints(
                child: Container(
                  decoration: BoxDecoration(
                    color: _bgColor,
                    border: Border.all(color: _borderColor, width: 1.0),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: upload.isImage
                      ? (isUploaded && upload.serverImageUrl != null
                            ? _UploadedImageContent(upload: upload)
                            : _buildImageSkeleton(ref, isError))
                      : Column(
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
          ),
        ],
      ),
    );
  }

  /// Skeleton for image uploads during the uploading phase.
  /// Image area is a shimmer matching NoteItem's display dimensions.
  /// Footer: shimmer for GIFs, progress bar + byte count + cancel for others.
  Widget _buildImageSkeleton(WidgetRef ref, bool isError) {
    final displaySize = computeDisplaySize(
      width: upload.mediaWidth,
      height: upload.mediaHeight,
      maxWidth: kImageMaxWidth,
      maxHeight: kImageMaxHeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerPlaceholder(
          width: displaySize.width,
          height: displaySize.height,
        ),
        const SizedBox(height: 12),
        if (_isGif)
          const _ShimmerFooter()
        else
          _buildUploadFooter(ref, isError),
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

// ---------------------------------------------------------------------------
// Uploaded image — loads server image in-place, then hands off to NoteItem.
// ---------------------------------------------------------------------------

/// Loads the server image behind a shimmer overlay. Once loaded, reveals the
/// real image and a decorative footer matching NoteItem's layout, then calls
/// [PendingUploads.completeUpload] to remove the ghost.
class _UploadedImageContent extends ConsumerStatefulWidget {
  const _UploadedImageContent({required this.upload});
  final PendingUpload upload;

  @override
  ConsumerState<_UploadedImageContent> createState() =>
      _UploadedImageContentState();
}

class _UploadedImageContentState extends ConsumerState<_UploadedImageContent> {
  bool _loaded = false;
  bool _completed = false;

  bool get _isGif => widget.upload.mimeType.toLowerCase() == 'image/gif';

  void _markLoaded() {
    if (!_loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _loaded = true);
          _complete();
        }
      });
    }
  }

  void _complete() {
    if (_completed) return;
    _completed = true;
    // Defer removal so the loaded frame renders first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(pendingUploadsProvider.notifier)
            .completeUpload(widget.upload.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final upload = widget.upload;
    final imageUrl = upload.serverImageUrl!;

    final displaySize = computeDisplaySize(
      width: upload.mediaWidth,
      height: upload.mediaHeight,
      maxWidth: kImageMaxWidth,
      maxHeight: kImageMaxHeight,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: displaySize.width,
          height: displaySize.height,
          child: Stack(
            children: [
              // Load real server image behind the shimmer.
              _isGif
                  ? Image.network(
                      imageUrl,
                      width: displaySize.width,
                      height: displaySize.height,
                      fit: BoxFit.cover,
                      frameBuilder: (context, child, frame, sync) {
                        if (frame != null || sync) _markLoaded();
                        return child;
                      },
                      errorBuilder: (context, error, stack) {
                        _markLoaded();
                        return const SizedBox.shrink();
                      },
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: displaySize.width,
                      height: displaySize.height,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      imageBuilder: (context, imageProvider) {
                        _markLoaded();
                        return Image(image: imageProvider, fit: BoxFit.cover);
                      },
                      errorWidget: (context, url, error) {
                        _markLoaded();
                        return const SizedBox.shrink();
                      },
                      placeholder: (context, url) => const SizedBox.shrink(),
                    ),
              // Shimmer overlay — removed once the server image loads.
              if (!_loaded)
                ShimmerPlaceholder(
                  width: displaySize.width,
                  height: displaySize.height,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loaded)
          _buildRealFooter()
        else if (_isGif)
          const _ShimmerFooter()
        else
          _buildFrozenProgressFooter(),
      ],
    );
  }

  /// Progress footer frozen at 100% — shown while the server image loads.
  /// Visually identical to the uploading footer so there's no intermediate state.
  Widget _buildFrozenProgressFooter() {
    final upload = widget.upload;
    const borderColor = Color(0xFFCE2161);
    final total = upload.fileSize > 0
        ? FileUtils.formatFileSize(upload.fileSize)
        : 'Done';
    return SizedBox(
      height: kFooterHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: 1.0,
            color: borderColor,
            backgroundColor: borderColor.withValues(alpha: 0.15),
            minHeight: 2,
          ),
          const Spacer(),
          Text(
            upload.fileSize > 0 ? '$total / $total' : 'Processing\u2026',
            style: TextStyle(
              fontSize: 11,
              color: const Color(0xFF00171F).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Decorative footer matching NoteItem's _NoteFooter layout.
  /// Non-interactive — ghost is removed almost immediately after this renders.
  Widget _buildRealFooter() {
    final createdAt = widget.upload.noteCreatedAt ?? DateTime.now();
    final iconColor = const Color(0xFF00171F).withValues(alpha: 0.5);

    return SizedBox(
      height: kFooterHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              FileUtils.formatDateTime(createdAt),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: iconColor),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PhosphorIcon(
                PhosphorIcons.pencilSimple(),
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 14),
              PhosphorIcon(
                PhosphorIcons.copySimple(),
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 14),
              PhosphorIcon(
                PhosphorIcons.archive(),
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 14),
              PhosphorIcon(
                PhosphorIcons.shareNetwork(),
                size: 20,
                color: iconColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two-part shimmer footer matching the real footer's timestamp + actions layout.
class _ShimmerFooter extends StatelessWidget {
  const _ShimmerFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kFooterHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Timestamp placeholder
          ShimmerPlaceholder(width: 120, height: 14),
          // Action icons placeholder (4 icons × 20 + 3 gaps × 14 = 122)
          ShimmerPlaceholder(width: 122, height: 14),
        ],
      ),
    );
  }
}

/// On mobile viewports, notes span full width; on desktop, capped at 600px.
/// Shared by [NoteItem] and [PendingNoteWidget].
class NoteConstraints extends StatelessWidget {
  const NoteConstraints({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return child;
    }
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, minWidth: 350),
        child: child,
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
