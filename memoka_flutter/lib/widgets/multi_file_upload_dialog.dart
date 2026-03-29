import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/upload_file_data.dart';
import '../utils/video_thumbnail_web.dart'
    if (dart.library.io) '../utils/video_thumbnail_native.dart'
    as vt;
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

  /// Key for the currently open dialog instance (if any).
  static final activeKey = GlobalKey<_MultiFileUploadDialogState>();

  /// Whether a dialog is currently open.
  static bool get isOpen => activeKey.currentState != null;

  /// Add files to the currently open dialog.
  static void addFiles(List<UploadFileData> files) {
    activeKey.currentState?._addFiles(files);
  }

  @override
  State<MultiFileUploadDialog> createState() => _MultiFileUploadDialogState();
}

/// Cache width for preview images — 2x dialog width for retina sharpness.
/// Must match between _precacheMedia and the Image widgets so cache keys align.
const _kPreviewCacheWidth = 1200;

class _MultiFileUploadDialogState extends State<MultiFileUploadDialog> {
  late List<UploadFileData> _files;
  final Map<UploadFileData, double> _aspectRatios = {};
  final Map<UploadFileData, Uint8List> _videoThumbnails = {};
  final Set<UploadFileData> _precachedFiles = {};

  /// True once all aspect ratios are resolved AND all images are precached.
  bool _loaded = false;

  /// Generation counter — prevents a stale _resolveAndPrecache from setting
  /// _loaded = true after _addFiles starts a newer resolution pass.
  int _resolveGeneration = 0;

  @override
  void initState() {
    super.initState();
    _files = List.of(widget.files);
    _resolveAndPrecache();
  }

  /// Add new files to the existing dialog, resolve their previews.
  void _addFiles(List<UploadFileData> newFiles) {
    _files.addAll(newFiles);
    _loaded = false;
    setState(() {});
    _resolveAndPrecache();
  }

  // ---------------------------------------------------------------------------
  // Resolution + precaching
  // ---------------------------------------------------------------------------

  Future<void> _resolveAndPrecache() async {
    final gen = ++_resolveGeneration;
    final media = _files.where((f) => f.isMedia).toList();

    // Phase 1: Resolve aspect ratios + generate video thumbnails.
    await Future.wait(
      media.map((file) async {
        if (file.isVideo && !_videoThumbnails.containsKey(file)) {
          await _resolveVideoThumbnail(file);
        }
        if (!_aspectRatios.containsKey(file)) {
          _aspectRatios[file] = await _getAspectRatio(file);
        }
      }),
    );
    if (gen != _resolveGeneration) return;

    // Phase 2: Precache media not yet cached.
    await Future.wait(
      media.where((f) => !_precachedFiles.contains(f)).map((file) async {
        await _precacheMedia(file);
        _precachedFiles.add(file);
      }),
    );
    if (gen != _resolveGeneration) return;

    if (mounted) setState(() => _loaded = true);
  }

  /// Precache an image or video thumbnail so it's fully decoded in memory.
  Future<void> _precacheMedia(UploadFileData file) async {
    try {
      ImageProvider? provider;
      if (file.isVideo) {
        final thumb = _videoThumbnails[file];
        if (thumb != null) {
          provider = MemoryImage(thumb);
        }
      } else if (!kIsWeb && file.filePath != null) {
        provider = ResizeImage(
          FileImage(File(file.filePath!)),
          width: _kPreviewCacheWidth,
        );
      } else if (file.bytes != null) {
        provider = ResizeImage(
          MemoryImage(file.bytes!),
          width: _kPreviewCacheWidth,
        );
      }
      if (provider != null && mounted) {
        await precacheImage(provider, context);
      }
    } catch (_) {
      // Precaching failed — image will decode on render (acceptable).
    }
  }

  /// Generate a thumbnail for a video file and store it in _videoThumbnails.
  Future<void> _resolveVideoThumbnail(UploadFileData file) async {
    try {
      final thumb = await vt.extractVideoThumbnail(
        file.filePath ?? '',
        mimeType: file.mimeType,
        bytes: file.bytes,
      );
      if (thumb != null && thumb.isNotEmpty) {
        _videoThumbnails[file] = thumb;
      }
    } catch (_) {
      // Thumbnail generation failed — will use placeholder.
    }
  }

  Future<double> _getAspectRatio(UploadFileData file) async {
    try {
      if (file.isVideo) {
        final thumb = _videoThumbnails[file];
        if (thumb != null) return _aspectRatioFromBytes(thumb);
        return 16 / 9;
      }

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
      if (image == null || image.height == 0) return 1.0;
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
    if (image == null || image.height == 0) return 16 / 9;
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
    _videoThumbnails.remove(file);
    _precachedFiles.remove(file);
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
    const maxItemsPerRow = 3;

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

      if (rowHeight <= targetRowHeight || currentRow.length >= maxItemsPerRow) {
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

      if (lastHeight > targetRowHeight * 1.5 &&
          prevRow.length > 1 &&
          lastRow.length < maxItemsPerRow) {
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

  /// Compute dialog width so a single media item fits within the viewport.
  double _computeDialogWidth(BuildContext context) {
    const maxWidth = 600.0;
    const minWidth = 300.0;

    final media = _mediaFiles;
    if (!_loaded || media.length != 1) return maxWidth;

    final ar = _aspectRatios[media.first] ?? 1.0;
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final safeVertical = mq.viewPadding.top + mq.viewPadding.bottom;

    // Vertical space consumed by non-media elements:
    // - AlertDialog insets: 24 top + 24 bottom = 48
    // - contentPadding: 12 top + 12 bottom = 24
    // - button row height: ~44
    // - gap between media and buttons: 12
    // - safe area
    final chromeHeight = 48.0 + 24.0 + 44.0 + 12.0 + safeVertical;
    final maxMediaHeight = screenHeight - chromeHeight;

    return (maxMediaHeight * ar).clamp(minWidth, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final media = _mediaFiles;
    final others = _otherFiles;
    final dialogWidth = _computeDialogWidth(context);

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (kIsWeb &&
            event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter &&
            _files.isNotEmpty) {
          _handleSend();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        shape: const RoundedRectangleBorder(),
        backgroundColor: const Color(0xFFF6F0ED),
        contentPadding: const EdgeInsets.all(12),
        content: SizedBox(
          width: dialogWidth,
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
                            final rows = _buildRows(
                              media,
                              constraints.maxWidth,
                            );
                            return SingleChildScrollView(
                              child: Column(
                                children: rows.map((row) {
                                  return Row(
                                    children: _buildRowWidgets(row),
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
      ),
    );
  }

  List<Widget> _buildRowWidgets(List<_RowItem> row) {
    return row.map((item) {
      return SizedBox(
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
      );
    }).toList();
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
    if (file.isVideo) return _buildVideoPreview(file);
    return _buildImagePreview(file);
  }

  Widget _buildImagePreview(UploadFileData file) {
    if (!kIsWeb && file.filePath != null) {
      return Image.file(
        File(file.filePath!),
        fit: BoxFit.cover,
        cacheWidth: _kPreviewCacheWidth,
        errorBuilder: (_, _, _) => Icon(file.fileIcon, size: 40),
      );
    }
    if (file.bytes != null) {
      return Image.memory(
        file.bytes!,
        fit: BoxFit.cover,
        cacheWidth: _kPreviewCacheWidth,
        errorBuilder: (_, _, _) => Icon(file.fileIcon, size: 40),
      );
    }
    return Icon(file.fileIcon, size: 40);
  }

  Widget _buildVideoPreview(UploadFileData file) {
    final thumb = _videoThumbnails[file];
    if (thumb != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            thumb,
            fit: BoxFit.cover,
            cacheWidth: _kPreviewCacheWidth,
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
    // Enrich video files with thumbnail bytes generated during preview.
    final enriched = _files.map((f) {
      final thumb = _videoThumbnails[f];
      if (f.isVideo && thumb != null) {
        return UploadFileData(
          bytes: f.bytes,
          filePath: f.filePath,
          fileName: f.fileName,
          extension: f.extension,
          thumbnailBytes: thumb,
        );
      }
      return f;
    }).toList();
    widget.onSend(enriched);
  }
}

class _RowItem {
  final UploadFileData file;
  final double width;
  final double height;

  _RowItem({required this.file, required this.width, required this.height});
}
