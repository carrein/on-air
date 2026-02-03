import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:on_air_client/on_air_client.dart';
import 'package:video_player/video_player.dart';

import '../utils/file_utils.dart';

/// Widget for displaying a video attachment inline in chat.
/// Shows thumbnail with play button overlay. Tapping opens full-screen player.
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
    // Build URLs
    final videoUrl = _buildVideoUrl();
    final thumbnailUrl = _buildThumbnailUrl();

    return GestureDetector(
      onTap: () {
        // Open full screen video player
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FullScreenVideoPlayer(
              videoUrl: videoUrl,
              attachment: attachment,
            ),
          ),
        );
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail
          Container(
            constraints: const BoxConstraints(
              maxWidth: 400,
              maxHeight: 300,
            ),
            child: thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return _defaultVideoThumbnail();
                    },
                  )
                : _defaultVideoThumbnail(),
          ),

          // Play button overlay
          Container(
            decoration: BoxDecoration(
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

          // Duration badge (if available)
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

  /// Build video URL with cache busting.
  String _buildVideoUrl() {
    return FileUtils.buildMediaUrl(serverUrl, attachment.filePath, attachment.contentHash);
  }

  /// Build thumbnail URL with cache busting.
  String? _buildThumbnailUrl() {
    if (attachment.thumbnailPath == null) return null;

    // Thumbnail path is relative to channel directory
    final parts = attachment.filePath.split('/');
    if (parts.length >= 2) {
      final channelPath = parts.take(parts.length - 1).join('/');
      final path = '$channelPath/${attachment.thumbnailPath}';
      return FileUtils.buildMediaUrl(serverUrl, path, attachment.contentHash);
    }

    return null;
  }

  /// Default video thumbnail (icon + filename).
  Widget _defaultVideoThumbnail() {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              color: Colors.grey[400],
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              attachment.originalFilename,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Format duration in seconds to MM:SS.
  String _formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final secs = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Full-screen video player.
class FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final MediaAttachment attachment;

  const FullScreenVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.attachment,
  });

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

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
        setState(() {
          _isInitialized = true;
        });

        // Auto-play
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.attachment.originalFilename),
      ),
      body: Center(
        child: _hasError
            ? _buildErrorWidget()
            : !_isInitialized
                ? const CircularProgressIndicator()
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
        const SizedBox(height: 20),
        _buildControls(),
      ],
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.grey[800]!,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            _formatPosition(),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatPosition() {
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    return '${_formatDuration(position)} / ${_formatDuration(duration)}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
