import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../providers/audio_player_provider.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';

import '../utils/download_tracker.dart';
import '../utils/file_utils.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';

/// Inline audio player for audio file attachments.
///
/// Web:    uses the browser's native HTMLAudioElement via universal_html.
/// Mobile: uses the audioplayers package (ExoPlayer on Android).
class AudioAttachmentWidget extends ConsumerStatefulWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  const AudioAttachmentWidget({
    super.key,
    required this.attachment,
    required this.serverUrl,
  });

  @override
  ConsumerState<AudioAttachmentWidget> createState() =>
      _AudioAttachmentWidgetState();
}

class _AudioAttachmentWidgetState extends ConsumerState<AudioAttachmentWidget> {
  static const _textPrimary = Color(0xFF00171F);
  static const _accent = Color(0xFF3450A3);

  // ── web ──────────────────────────────────────────────────────────────────
  html.AudioElement? _webAudio;

  // ── mobile ───────────────────────────────────────────────────────────────
  AudioPlayer? _mobilePlayer;
  PlayerState _mobileState = PlayerState.stopped;

  // ── shared state ─────────────────────────────────────────────────────────
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _seeking = false;
  String? _error;

  final _tracker = DownloadTracker.instance;

  String get _downloadKey => widget.attachment.filePath;
  bool get _isDownloading =>
      _tracker[_downloadKey]?.status == DownloadStatus.downloading;

  final List<StreamSubscription<dynamic>> _subs = [];

  String get _audioId => widget.attachment.filePath;

  String get _audioUrl => FileUtils.buildMediaUrl(
    widget.serverUrl,
    widget.attachment.filePath,
    widget.attachment.contentHash,
  );

  // ── init / dispose ────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_onTrackerChanged);
    if (!kIsWeb) {
      final entry = _tracker[_downloadKey];
      if (entry != null && entry.status == DownloadStatus.completed) {
        _tracker.acknowledge(_downloadKey);
      }
    }
    if (kIsWeb) {
      _initWeb();
    } else {
      _initMobile();
    }
  }

  void _initWeb() {
    _webAudio = html.AudioElement()
      ..src = _audioUrl
      ..preload = 'metadata';

    _subs.addAll([
      _webAudio!.onPlay.listen((_) {
        if (mounted) setState(() => _isPlaying = true);
      }),
      _webAudio!.onPause.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      }),
      _webAudio!.onTimeUpdate.listen((_) {
        if (!mounted || _seeking) return;
        final secs = ((_webAudio! as dynamic).currentTime ?? 0).toDouble();
        setState(() => _position = _secsToDuration(secs));
      }),
      _webAudio!.onDurationChange.listen((_) {
        if (!mounted) return;
        final d = ((_webAudio! as dynamic).duration ?? double.nan).toDouble();
        if (!d.isNaN && !d.isInfinite && d > 0) {
          setState(() => _duration = _secsToDuration(d));
        }
      }),
      _webAudio!.onEnded.listen((_) {
        if (!mounted) return;
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        (_webAudio! as dynamic).currentTime = 0;
      }),
    ]);
  }

  void _initMobile() {
    _mobilePlayer = AudioPlayer();

    _subs.addAll([
      _mobilePlayer!.onPlayerStateChanged.listen((state) {
        if (!mounted) return;
        setState(() {
          _mobileState = state;
          _isPlaying = state == PlayerState.playing;
        });
        if (state == PlayerState.completed) {
          _mobilePlayer!.seek(Duration.zero);
          setState(() => _position = Duration.zero);
        }
      }),
      _mobilePlayer!.onPositionChanged.listen((pos) {
        if (!mounted || _seeking) return;
        setState(() => _position = pos);
      }),
      _mobilePlayer!.onDurationChanged.listen((dur) {
        if (!mounted) return;
        setState(() => _duration = dur);
      }),
    ]);
  }

  @override
  void dispose() {
    _tracker.removeListener(_onTrackerChanged);
    for (final s in _subs) {
      s.cancel();
    }
    if (kIsWeb) {
      _webAudio?.pause();
      _webAudio?.src = '';
    } else {
      _mobilePlayer?.dispose();
    }
    super.dispose();
  }

  // ── playback controls ─────────────────────────────────────────────────────

  Future<void> _togglePlay() async {
    try {
      setState(() => _error = null);
      if (_isPlaying) {
        _pause();
      } else {
        ref.read(activeAudioIdProvider.notifier).state = _audioId;
        await _play();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _play() async {
    if (kIsWeb) {
      await _webAudio!.play();
    } else {
      if (_mobileState == PlayerState.paused) {
        await _mobilePlayer!.resume();
      } else {
        await _mobilePlayer!.play(UrlSource(_audioUrl));
      }
    }
  }

  void _pause() {
    if (kIsWeb) {
      _webAudio!.pause();
    } else {
      _mobilePlayer!.pause();
    }
  }

  Future<void> _seekTo(double seconds) async {
    _seeking = false;
    final dur = Duration(milliseconds: (seconds * 1000).toInt());
    if (kIsWeb) {
      (_webAudio! as dynamic).currentTime = seconds.toInt();
      if (mounted) setState(() => _position = dur);
    } else {
      await _mobilePlayer!.seek(dur);
    }
  }

  void _onActiveIdChanged(String? previous, String? next) {
    if (next != _audioId && _isPlaying) _pause();
  }

  // ── download ─────────────────────────────────────────────────────────────

  void _onTrackerChanged() {
    if (!mounted) return;
    final entry = _tracker[_downloadKey];
    if (entry != null && entry.status == DownloadStatus.completed) {
      final path = entry.cachedPath;
      _tracker.acknowledge(_downloadKey);
      if (path != null) {
        _dispatchDownloadedFile(path);
      }
    }
    setState(() {});
  }

  Future<void> _dispatchDownloadedFile(String path) async {
    final mime = widget.attachment.mimeType.toLowerCase();
    if (mime.startsWith('image/')) {
      await Gal.putImage(path);
      if (mounted) {
        ToastUtils.show(context, 'Saved to gallery', type: ToastType.success);
      }
    } else if (mime.startsWith('video/')) {
      await Gal.putVideo(path);
      if (mounted) {
        ToastUtils.show(context, 'Saved to gallery', type: ToastType.success);
      }
    } else {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && mounted) {
        ToastUtils.show(context, 'Could not open file', type: ToastType.error);
      }
    }
  }

  void _cancelDownload() {
    _tracker.cancel(_downloadKey);
  }

  void _handleDownload() {
    if (kIsWeb) {
      html.AnchorElement()
        ..href = _audioUrl
        ..setAttribute('download', widget.attachment.originalFilename)
        ..click();
    } else {
      _tracker.startCacheDownload(
        _downloadKey,
        _audioUrl,
        widget.attachment.originalFilename,
      );
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Duration _secsToDuration(double secs) =>
      Duration(milliseconds: (secs * 1000).toInt());

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(activeAudioIdProvider, _onActiveIdChanged);

    final totalSeconds = _duration.inSeconds.toDouble();
    final posSeconds = _position.inSeconds.toDouble().clamp(
      0.0,
      totalSeconds > 0 ? totalSeconds : 1.0,
    );
    final hasDuration = _duration > Duration.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // File icon — mirrors document attachment style
            PhosphorIcon(
              PhosphorIcons.fileAudio(),
              color: _textPrimary,
              size: 32,
            ),
            const SizedBox(width: 12),

            // Filename + controls
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Audio error: $_error',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFDB0000),
                        ),
                      ),
                    ),

                  Text(
                    widget.attachment.originalFilename,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // play | scrubber | time | download
                  Row(
                    children: [
                      IconButtonStyled(
                        icon: _isPlaying
                            ? PhosphorIcons.pause()
                            : PhosphorIcons.play(),
                        onPressed: _togglePlay,
                        size: IconButtonStyled.sm,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: _accent,
                            inactiveTrackColor: _textPrimary.withValues(
                              alpha: 0.15,
                            ),
                            thumbColor: _accent,
                            overlayColor: _accent.withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            trackHeight: 3,
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: posSeconds,
                            min: 0,
                            max: totalSeconds > 0 ? totalSeconds : 1.0,
                            onChangeStart: (_) =>
                                setState(() => _seeking = true),
                            onChanged: hasDuration
                                ? (v) => setState(
                                    () => _position = Duration(
                                      seconds: v.toInt(),
                                    ),
                                  )
                                : null,
                            onChangeEnd: (v) => _seekTo(v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasDuration
                            ? '${FileUtils.formatDuration(_position.inSeconds.toDouble())} / ${FileUtils.formatDuration(_duration.inSeconds.toDouble())}'
                            : '--:-- / --:--',
                        style: TextStyle(
                          fontSize: 11,
                          color: _textPrimary.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButtonStyled(
                        icon: PhosphorIcons.handEye(),
                        onPressed: () async {
                          final uri = Uri.parse(_audioUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        size: IconButtonStyled.sm,
                      ),
                      const SizedBox(width: 4),
                      IconButtonStyled(
                        icon: _isDownloading
                            ? PhosphorIcons.x()
                            : PhosphorIcons.downloadSimple(),
                        onPressed: _isDownloading
                            ? _cancelDownload
                            : _handleDownload,
                        size: IconButtonStyled.sm,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_isDownloading) ...[
          const SizedBox(height: 6),
          Builder(
            builder: (_) {
              final entry = _tracker[_downloadKey];
              final received = entry?.receivedBytes ?? 0;
              final total = entry?.totalBytes ?? -1;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: total > 0 ? received / total : null,
                    color: _accent,
                    backgroundColor: _accent.withValues(alpha: 0.15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total > 0
                        ? '${FileUtils.formatFileSize(received)} / ${FileUtils.formatFileSize(total)}'
                        : FileUtils.formatFileSize(received),
                    style: TextStyle(
                      fontSize: 10,
                      color: _textPrimary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}
