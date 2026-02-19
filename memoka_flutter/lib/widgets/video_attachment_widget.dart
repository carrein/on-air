import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:video_player/video_player.dart';

import '../utils/file_utils.dart';
import 'media_attachment_widget.dart';

/// Widget for displaying a video attachment inline in chat.
/// Shows thumbnail with play button overlay. Tapping opens lightbox player.
class VideoAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  const VideoAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final videoUrl = _buildVideoUrl();
    final thumbnailUrl = _buildThumbnailUrl();

    const double maxWidth = 400;
    const double maxHeight = 300;

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
                    fadeInDuration: const Duration(milliseconds: 150),
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
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
          ),
          if (attachment.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(attachment.duration!),
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
        serverUrl, attachment.filePath, attachment.contentHash);
  }

  String? _buildThumbnailUrl() {
    if (attachment.thumbnailPath == null) return null;
    final parts = attachment.filePath.split('/');
    if (parts.length >= 2) {
      final channelPath = parts.take(parts.length - 1).join('/');
      final path = '$channelPath/${attachment.thumbnailPath}';
      return FileUtils.buildMediaUrl(serverUrl, path, attachment.contentHash);
    }
    return null;
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
            Icon(Icons.videocam, color: Colors.grey[400], size: 64),
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

  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
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
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      );
    }

    if (!_isInitialized) {
      return const CircularProgressIndicator(color: Colors.white);
    }

    final screenSize = MediaQuery.of(context).size;
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
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 56,
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
              GestureDetector(
                onTap: _togglePlayPause,
                child: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: const Color(0xFFCE2161),
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
    return '${_durationStr(position)} / ${_durationStr(duration)}';
  }

  String _durationStr(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
