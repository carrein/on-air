import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../utils/file_utils.dart';
import 'audio_attachment_widget.dart';
import 'document_attachment_widget.dart';
import 'full_screen_image_view.dart';
import 'video_attachment_widget.dart';

/// Max display width for inline images in chat.
const kImageMaxWidth = 300.0;

/// Max display height for inline images in chat.
const kImageMaxHeight = 250.0;

/// Max display width for media-only notes (no card chrome).
const kMediaNoteMaxWidth = 400.0;

/// Max display height for media-only notes (no card chrome).
const kMediaNoteMaxHeight = 350.0;

/// Compute display size from attachment metadata, clamped to max constraints.
/// Maintains aspect ratio. Falls back to [fallback] if dimensions are null.
Size computeDisplaySize({
  int? width,
  int? height,
  required double maxWidth,
  required double maxHeight,
  Size fallback = const Size(300, 200),
}) {
  if (width == null || height == null || width == 0 || height == 0) {
    return fallback;
  }

  final double w = width.toDouble();
  final double h = height.toDouble();
  final double scale = math.min(maxWidth / w, maxHeight / h).clamp(0.0, 1.0);

  return Size(
    (w * scale).clamp(1.0, maxWidth),
    (h * scale).clamp(1.0, maxHeight),
  );
}

/// Widget for displaying a media attachment inline in chat.
/// Routes to either image or document widget based on MIME type.
class MediaAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;
  final List<String> allImageUrls;
  final int initialImageIndex;
  final bool isMediaNote;

  const MediaAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
    this.allImageUrls = const [],
    this.initialImageIndex = 0,
    this.isMediaNote = false,
  });

  bool get _isImage {
    final mime = attachment.mimeType.toLowerCase();
    return mime.startsWith('image/');
  }

  bool get _isVideo {
    final mime = attachment.mimeType.toLowerCase();
    return mime.startsWith('video/');
  }

  bool get _isAudio {
    final mime = attachment.mimeType.toLowerCase();
    if (mime.startsWith('audio/')) return true;
    final ext = FileUtils.getExtension(attachment.originalFilename);
    return FileUtils.isAudio(ext);
  }

  @override
  Widget build(BuildContext context) {
    // Route to appropriate widget based on type
    if (_isImage) {
      return _ImageAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
        allImageUrls: allImageUrls,
        initialImageIndex: initialImageIndex,
        isMediaNote: isMediaNote,
      );
    } else if (_isVideo) {
      return VideoAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
        maxWidth: isMediaNote ? kMediaNoteMaxWidth : 400,
        maxHeight: isMediaNote ? kMediaNoteMaxHeight : 300,
      );
    } else if (_isAudio) {
      return AudioAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
      );
    } else {
      return DocumentAttachmentWidget(
        attachment: attachment,
        serverUrl: serverUrl,
      );
    }
  }
}

/// Internal widget for displaying image attachments.
class _ImageAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;
  final List<String> allImageUrls;
  final int initialImageIndex;
  final bool isMediaNote;

  const _ImageAttachmentWidget({
    required this.attachment,
    required this.serverUrl,
    required this.allImageUrls,
    required this.initialImageIndex,
    this.isMediaNote = false,
  });

  bool get _isGif => attachment.mimeType.toLowerCase() == 'image/gif';

  @override
  Widget build(BuildContext context) {
    final imageUrl = FileUtils.buildMediaUrl(
      serverUrl,
      attachment.filePath,
      attachment.contentHash,
    );

    final effectiveMaxWidth = isMediaNote ? kMediaNoteMaxWidth : kImageMaxWidth;
    final effectiveMaxHeight = isMediaNote
        ? kMediaNoteMaxHeight
        : kImageMaxHeight;

    final displaySize = computeDisplaySize(
      width: attachment.width,
      height: attachment.height,
      maxWidth: effectiveMaxWidth,
      maxHeight: effectiveMaxHeight,
    );

    return GestureDetector(
      onTap: () {
        FullScreenImageView.show(
          context,
          imageUrls: allImageUrls.isNotEmpty ? allImageUrls : [imageUrl],
          initialIndex: allImageUrls.isNotEmpty ? initialImageIndex : 0,
        );
      },
      child: Stack(
        children: [
          SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: _isGif
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded || frame != null) {
                            return child;
                          }
                          return ShimmerPlaceholder(
                            width: displaySize.width,
                            height: displaySize.height,
                          );
                        },
                    errorBuilder: (context, error, stack) {
                      return _buildErrorWidget(displaySize, error);
                    },
                  )
                : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (context, url) => ShimmerPlaceholder(
                      width: displaySize.width,
                      height: displaySize.height,
                    ),
                    errorWidget: (context, url, error) {
                      return _buildErrorWidget(displaySize, error);
                    },
                  ),
          ),
          // Compressed indicator (hidden for media-only notes)
          if (attachment.compressed && !isMediaNote)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIcons.arrowsInSimple(),
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'Compressed',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Size displaySize, Object error) {
    return Container(
      width: displaySize.width,
      height: displaySize.height,
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.imageBroken(),
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.toString().substring(0, math.min(50, error.toString().length))}...',
              style: const TextStyle(color: Color(0xFFDB0000), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated shimmer placeholder sized to the given dimensions.
class ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 0,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [
                Colors.grey[800]!,
                Colors.grey[700]!,
                Colors.grey[800]!,
              ],
            ),
          ),
        );
      },
    );
  }
}
