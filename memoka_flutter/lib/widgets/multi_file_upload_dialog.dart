import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/upload_file_data.dart';
import '../utils/video_thumbnail_web.dart'
    if (dart.library.io) '../utils/video_thumbnail_stub.dart'
    as vt_web;
import 'app_text_button.dart';
import 'icon_button_styled.dart';
import 'app_spinner.dart';

/// Dialog for uploading multiple files.
///
/// Shows images and videos in a justified grid (rows with equal height, media
/// scaled proportionally to fill the full width) and non-media files in a
/// compact list below. Each item has an X button to remove it.
///
/// Shows a spinner until all media (images + video thumbnails) are fully
/// decoded, then reveals everything at once.
class MultiFileUploadDialog extends StatefulWidget {
  final List<UploadFileData> files;
  final void Function(List<UploadFileData> files) onSend;

  const MultiFileUploadDialog({
    super.key,
    required this.files,
    required this.onSend,
  });

  @override
  State<MultiFileUploadDialog> createState() => _MultiFileUploadDialogState();
}

class _MultiFileUploadDialogState extends State<MultiFileUploadDialog> {
  late List<UploadFileData> _files;
  final Map<UploadFileData, double> _aspectRatios = {};

  /// True once all aspect ratios are resolved AND all images are precached.
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _files = List.of(widget.files);
    _resolveAndPrecache();
  }

  // ---------------------------------------------------------------------------
  // Resolution + precaching
  // ---------------------------------------------------------------------------

  Future<void> _resolveAndPrecache() async {
    final media = _files.where((f) => f.isMedia).toList();

    // Phase 1: Resolve aspect ratios + generate video thumbnails.
    await Future.wait(
      media.map((file) async {
        if (file.isVideo) {
          await _resolveVideoThumbnail(file);
        }
        final ratio = await _getAspectRatio(file);
        _aspectRatios[file] = ratio;
      }),
    );

    // Phase 2: Precache all media so images are fully decoded before showing.
    await Future.wait(
      media.map((file) => _precacheMedia(file)),
    );

    if (mounted) setState(() => _loaded = true);
  }

  /// Precache an image or video thumbnail so it's fully decoded in memory.
  Future<void> _precacheMedia(UploadFileData file) async {
    try {
      ImageProvider? provider;
      if (file.isVideo) {
        if (file.thumbnailBytes != null) {
          provider = MemoryImage(file.thumbnailBytes!);
        }
      } else if (!kIsWeb && file.filePath != null) {
        provider = ResizeImage(
          FileImage(File(file.filePath!)),
          width: 800,
        );
      } else if (file.bytes != null) {
        provider = ResizeImage(MemoryImage(file.bytes!), width: 800);
      }
      if (provider != null && mounted) {
        await precacheImage(provider, context);
      }
    } catch (_) {
      // Precaching failed — image will decode on render (acceptable).
    }
  }

  /// Generate a thumbnail for a video file and store it on the model.
  Future<void> _resolveVideoThumbnail(UploadFileData file) async {
    try {
      if (kIsWeb) {
        // Use HTML video API to extract a frame on web.
        if (file.bytes != null) {
          final thumb = await vt_web.extractVideoThumbnail(file.bytes!);
          if (thumb != null && thumb.isNotEmpty) {
            file.thumbnailBytes = thumb;
          }
        }
        return;
      }

      if (file.filePath == null) return;

      // Get video duration to extract frame from the middle.
      int timeMs = 0;
      try {
        final controller = VideoPlayerController.file(File(file.filePath!));
        await controller.initialize();
        timeMs = controller.value.duration.inMilliseconds ~/ 2;
        await controller.dispose();
      } catch (_) {
        // Fall back to 0ms if duration detection fails.
      }

      final thumb = await VideoThumbnail.thumbnailData(
        video: file.filePath!,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 800,
        quality: 75,
        timeMs: timeMs,
      );
      if (thumb != null && thumb.isNotEmpty) {
        file.thumbnailBytes = thumb;
      }
    } catch (e) {
      debugPrint('Video thumbnail generation failed: $e');
    }
  }

  Future<double> _getAspectRatio(UploadFileData file) async {
    try {
      // For videos, use the generated thumbnail bytes.
      if (file.isVideo) {
        if (file.thumbnailBytes != null) {
          return _aspectRatioFromBytes(file.thumbnailBytes!);
        }
        return 16 / 9;
      }

      // For images, resolve from file/bytes.
      final completer = Completer<ui.Image?>();
      late ImageProvider provider;
      if (!kIsWeb && file.filePath != null) {
        provider = FileImage(File(file.filePath!));
      } else if (file.bytes != null) {
        provider = MemoryImage(file.bytes!);
      } else {
        return 1.0;
      }
      final stream = provider.resolve(ImageConfiguration.empty);
      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          completer.complete(info.image);
          stream.removeListener(listener);
        },
        onError: (error, _) {
          if (!completer.isCompleted) completer.complete(null);
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      final image = await completer.future;
      if (image == null) return 1.0;
      return image.width / image.height;
    } catch (_) {
      return 1.0;
    }
  }

  Future<double> _aspectRatioFromBytes(Uint8List bytes) async {
    final completer = Completer<ui.Image?>();
    final provider = MemoryImage(bytes);
    final stream = provider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        completer.complete(info.image);
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) completer.complete(null);
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    final image = await completer.future;
    if (image == null) return 16 / 9;
    return image.width / image.height;
  }

  // ---------------------------------------------------------------------------
  // File lists
  // ---------------------------------------------------------------------------

  List<UploadFileData> get _mediaFiles =>
      _files.where((f) => f.isMedia).toList();

  List<UploadFileData> get _otherFiles =>
      _files.where((f) => !f.isMedia).toList();

  void _removeFile(UploadFileData file) {
    _files.remove(file);
    _aspectRatios.remove(file);
    if (_files.isEmpty) {
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  // ---------------------------------------------------------------------------
  // Justified row layout
  // ---------------------------------------------------------------------------

  List<List<_RowItem>> _buildRows(
    List<UploadFileData> media,
    double containerWidth,
  ) {
    const spacing = 0.0;
    const targetRowHeight = 220.0;

    if (media.isEmpty) return [];
    if (media.length == 1) {
      return [_finalizeRow(media, containerWidth, spacing)];
    }

    final rowPartitions = <List<UploadFileData>>[];
    var currentRow = <UploadFileData>[];
    var sumAr = 0.0;

    for (final img in media) {
      final ar = _aspectRatios[img] ?? 1.0;
      currentRow.add(img);
      sumAr += ar;

      final gaps = (currentRow.length - 1) * spacing;
      final rowHeight = (containerWidth - gaps) / sumAr;

      if (rowHeight <= targetRowHeight) {
        rowPartitions.add(List.of(currentRow));
        currentRow = [];
        sumAr = 0;
      }
    }
    if (currentRow.isNotEmpty) {
      rowPartitions.add(currentRow);
    }

    while (rowPartitions.length >= 2) {
      final lastRow = rowPartitions.last;
      final prevRow = rowPartitions[rowPartitions.length - 2];

      final lastSumAr = lastRow.fold(
        0.0,
        (s, f) => s + (_aspectRatios[f] ?? 1.0),
      );
      final lastGaps = (lastRow.length - 1) * spacing;
      final lastHeight = (containerWidth - lastGaps) / lastSumAr;

      if (lastHeight > targetRowHeight * 1.5 && prevRow.length > 1) {
        final stolen = prevRow.removeLast();
        lastRow.insert(0, stolen);
      } else {
        break;
      }
    }

    return rowPartitions
        .map((files) => _finalizeRow(files, containerWidth, spacing))
        .toList();
  }

  List<_RowItem> _finalizeRow(
    List<UploadFileData> files,
    double containerWidth,
    double spacing,
  ) {
    final sumAr = files.fold(0.0, (sum, f) => sum + (_aspectRatios[f] ?? 1.0));
    final gaps = (files.length - 1) * spacing;
    final height = (containerWidth - gaps) / sumAr;
    return files.map((f) {
      final ar = _aspectRatios[f] ?? 1.0;
      return _RowItem(file: f, width: height * ar, height: height);
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final media = _mediaFiles;
    final others = _otherFiles;

    return AlertDialog(
      shape: const RoundedRectangleBorder(),
      backgroundColor: const Color(0xFFF6F0ED),
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: 600,
        child: !_loaded && media.isNotEmpty
            ? const SizedBox(
                height: 100,
                child: Center(child: AppSpinner(size: 32)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (media.isNotEmpty)
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final rows = _buildRows(media, constraints.maxWidth);
                          return SingleChildScrollView(
                            child: Column(
                              children: rows.map((row) {
                                return Padding(
                                  padding: EdgeInsets.zero,
                                  child: Row(
                                    children: _buildRowWidgets(row),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  if (others.isNotEmpty) ...[
                    if (media.isNotEmpty) const SizedBox(height: 8),
                    ...others.map((file) => _buildOtherFileRow(file)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppTextButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                        variant: AppTextButtonVariant.secondary,
                      ),
                      const SizedBox(width: 8),
                      AppTextButton(
                        label: 'Upload All',
                        onPressed: _files.isEmpty ? null : _handleSend,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildRowWidgets(List<_RowItem> row) {
    final widgets = <Widget>[];
    for (var i = 0; i < row.length; i++) {
      final item = row[i];
      widgets.add(
        SizedBox(
          width: item.width,
          height: item.height,
          child: Stack(
            children: [
              SizedBox.expand(child: _buildMediaPreview(item.file)),
              Positioned(
                top: 6,
                right: 6,
                child: IconButtonStyled(
                  icon: PhosphorIcons.trashSimple(),
                  size: IconButtonStyled.xs,
                  color: Colors.white,
                  onPressed: () => _removeFile(item.file),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildOtherFileRow(UploadFileData file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            file.fileIcon,
            size: 24,
            color: const Color(0xFF00171F).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.fileName,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButtonStyled(
            icon: PhosphorIcons.trashSimple(),
            size: IconButtonStyled.xs,
            onPressed: () => _removeFile(file),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Media preview (images + videos)
  // ---------------------------------------------------------------------------

  Widget _buildMediaPreview(UploadFileData file) {
    if (file.isVideo) {
      return _buildVideoPreview(file);
    }
    return _buildImagePreview(file);
  }

  Widget _buildImagePreview(UploadFileData file) {
    if (!kIsWeb && file.filePath != null) {
      return Image.file(
        File(file.filePath!),
        fit: BoxFit.cover,
        cacheWidth: 800,
        errorBuilder: (context, error, stackTrace) {
          return Icon(file.fileIcon, size: 40);
        },
      );
    }
    if (file.bytes != null) {
      return Image.memory(
        file.bytes!,
        fit: BoxFit.cover,
        cacheWidth: 800,
        errorBuilder: (context, error, stackTrace) {
          return Icon(file.fileIcon, size: 40);
        },
      );
    }
    return Icon(file.fileIcon, size: 40);
  }

  Widget _buildVideoPreview(UploadFileData file) {
    if (file.thumbnailBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            file.thumbnailBytes!,
            fit: BoxFit.cover,
            cacheWidth: 800,
            errorBuilder: (_, _, _) => _videoPlaceholder(),
          ),
          _playIconOverlay(),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _videoPlaceholder(),
        _playIconOverlay(),
      ],
    );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          PhosphorIcons.videoCamera(PhosphorIconsStyle.fill),
          color: Colors.white54,
          size: 40,
        ),
      ),
    );
  }

  Widget _playIconOverlay() {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  void _handleSend() {
    Navigator.of(context).pop();
    widget.onSend(_files);
  }
}

class _RowItem {
  final UploadFileData file;
  final double width;
  final double height;

  _RowItem({required this.file, required this.width, required this.height});
}
