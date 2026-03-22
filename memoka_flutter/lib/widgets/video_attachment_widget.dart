import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';

import '../utils/file_utils.dart';
import 'icon_button_styled.dart';
import 'media_attachment_widget.dart';
import 'app_spinner.dart';

/// Widget for displaying a video attachment inline in chat.
/// Shows thumbnail with play button overlay. Tapping opens lightbox player.
class VideoAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;
  final double maxWidth;
  final double maxHeight;

  const VideoAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
    this.maxWidth = 400,
    this.maxHeight = 300,
  });

  @override
  Widget build(BuildContext context) {
    final videoUrl = _buildVideoUrl();
    final thumbnailUrl = _buildThumbnailUrl();

    final displaySize = computeDisplaySize(
      width: attachment.width,
      height: attachment.height,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    return GestureDetector(
      onTap: () {
        _VideoLightbox.show(context, videoUrl: videoUrl);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: displaySize.width,
            height: displaySize.height,
            child: thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) => ShimmerPlaceholder(
                      width: displaySize.width,
                      height: displaySize.height,
                    ),
                    errorWidget: (context, url, error) {
                      return _defaultVideoThumbnail(displaySize);
                    },
                  )
                : _defaultVideoThumbnail(displaySize),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: PhosphorIcon(
              PhosphorIcons.play(),
              color: const Color(0xFF3450A3),
              size: 28,
            ),
          ),
          if (attachment.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  FileUtils.formatDuration(attachment.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _buildVideoUrl() {
    return FileUtils.buildMediaUrl(
      serverUrl,
      attachment.filePath,
      attachment.contentHash,
    );
  }

  String? _buildThumbnailUrl() {
    return FileUtils.buildThumbnailUrl(serverUrl, attachment);
  }

  Widget _defaultVideoThumbnail(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIcons.video(),
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              attachment.originalFilename,
              style: TextStyle(color: Colors.grey[300], fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen video lightbox overlay, matching the image lightbox pattern.
class _VideoLightbox extends StatefulWidget {
  final String videoUrl;

  const _VideoLightbox({required this.videoUrl});

  static void show(BuildContext context, {required String videoUrl}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      useSafeArea: false,
      builder: (context) => _VideoLightbox(videoUrl: videoUrl),
    );
  }

  @override
  State<_VideoLightbox> createState() => _VideoLightboxState();
}

class _VideoLightboxState extends State<_VideoLightbox> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.play();
        _controller.addListener(_onVideoUpdate);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _togglePlayPause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Video player centered
            Center(
              child: GestureDetector(
                onTap: () {}, // absorb tap so it doesn't close
                child: _buildPlayer(),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: IconButtonStyled(
                icon: PhosphorIcons.x(),
                onPressed: () => Navigator.of(context).pop(),
                color: Colors.white,
                size: IconButtonStyled.lg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_hasError) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIcons.warning(),
            color: const Color(0xFFDB0000),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return AppSpinner();
    }

    final screenSize = MediaQuery.sizeOf(context);
    final videoAspect = _controller.value.aspectRatio;
    // Fit video within 90% of screen
    final maxW = screenSize.width * 0.9;
    final maxH = screenSize.height * 0.85;
    double videoW = maxW;
    double videoH = videoW / videoAspect;
    if (videoH > maxH) {
      videoH = maxH;
      videoW = videoH * videoAspect;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _togglePlayPause,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: videoW,
                height: videoH,
                child: VideoPlayer(_controller),
              ),
              if (!_controller.value.isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.75),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: PhosphorIcon(
                    PhosphorIcons.play(),
                    color: const Color(0xFF3450A3),
                    size: 30,
                  ),
                ),
            ],
          ),
        ),
        // Controls bar
        Container(
          width: videoW,
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButtonStyled(
                icon: _controller.value.isPlaying
                    ? PhosphorIcons.pause()
                    : PhosphorIcons.play(),
                onPressed: _togglePlayPause,
                color: Colors.white,
                padding: 4,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: const Color(0xFF3450A3),
                    bufferedColor: Colors.grey[600]!,
                    backgroundColor: Colors.grey[800]!,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatPosition(),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPosition() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    return '${FileUtils.formatDuration(position.inSeconds.toDouble())} / ${FileUtils.formatDuration(duration.inSeconds.toDouble())}';
  }
}
