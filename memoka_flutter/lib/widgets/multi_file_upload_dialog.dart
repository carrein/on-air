import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/upload_file_data.dart';
import 'app_text_button.dart';
import 'icon_button_styled.dart';
import 'app_spinner.dart';

/// Dialog for uploading multiple files.
///
/// Shows images in a justified grid (rows with equal height, images scaled
/// proportionally to fill the full width) and non-image files in a compact
/// list below. Each item has an X button to remove it.
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
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _files = List.of(widget.files);
    _resolveAspectRatios();
  }

  Future<void> _resolveAspectRatios() async {
    final images = _files.where((f) => f.isImage).toList();
    await Future.wait(
      images.map((file) async {
        final ratio = await _getAspectRatio(file);
        _aspectRatios[file] = ratio;
      }),
    );
    if (mounted) setState(() => _loaded = true);
  }

  Future<double> _getAspectRatio(UploadFileData file) async {
    try {
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

  List<UploadFileData> get _imageFiles =>
      _files.where((f) => f.isImage).toList();

  List<UploadFileData> get _otherFiles =>
      _files.where((f) => !f.isImage).toList();

  void _removeFile(UploadFileData file) {
    _files.remove(file);
    _aspectRatios.remove(file);
    if (_files.isEmpty) {
      Navigator.of(context).pop();
    } else {
      setState(() {});
    }
  }

  /// Partition images into rows where every row fills [containerWidth]
  /// exactly, producing a flush rectangle on all sides.
  ///
  /// Uses a greedy algorithm then rebalances: if the last row would be
  /// too tall (too few items), steals images from previous rows until
  /// balanced.
  List<List<_RowItem>> _buildRows(
    List<UploadFileData> images,
    double containerWidth,
  ) {
    const spacing = 0.0;
    const targetRowHeight = 220.0;

    if (images.isEmpty) return [];
    if (images.length == 1) {
      return [_finalizeRow(images, containerWidth, spacing)];
    }

    // Greedy pass: partition into rows
    final rowPartitions = <List<UploadFileData>>[];
    var currentRow = <UploadFileData>[];
    var sumAr = 0.0;

    for (final img in images) {
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

    // Rebalance: if last row is much smaller than previous, redistribute.
    // Steal one item at a time from the previous row until balanced.
    while (rowPartitions.length >= 2) {
      final lastRow = rowPartitions.last;
      final prevRow = rowPartitions[rowPartitions.length - 2];

      final lastSumAr = lastRow.fold(
        0.0,
        (s, f) => s + (_aspectRatios[f] ?? 1.0),
      );
      final lastGaps = (lastRow.length - 1) * spacing;
      final lastHeight = (containerWidth - lastGaps) / lastSumAr;

      // If last row height is more than 1.5x target, steal from previous
      if (lastHeight > targetRowHeight * 1.5 && prevRow.length > 1) {
        final stolen = prevRow.removeLast();
        lastRow.insert(0, stolen);
      } else {
        break;
      }
    }

    // Finalize all rows to fill full width
    return rowPartitions
        .map((files) => _finalizeRow(files, containerWidth, spacing))
        .toList();
  }

  /// Scale images in [files] to a common height so they fill [containerWidth].
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

  @override
  Widget build(BuildContext context) {
    final images = _imageFiles;
    final others = _otherFiles;

    return AlertDialog(
      shape: const RoundedRectangleBorder(),
      backgroundColor: const Color(0xFFF6F0ED),
      contentPadding: const EdgeInsets.all(12),
      content: SizedBox(
        width: 600,
        child: !_loaded && images.isNotEmpty
            ? const SizedBox(
                height: 100,
                child: Center(child: AppSpinner(size: 32)),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (images.isNotEmpty)
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final rows = _buildRows(images, constraints.maxWidth);
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
                    if (images.isNotEmpty) const SizedBox(height: 8),
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
              SizedBox.expand(child: _buildImagePreview(item.file)),
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
          if (file.isVideo)
            SizedBox(
              height: 28,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: file.compress,
                    visualDensity: VisualDensity.compact,
                    onChanged: (value) {
                      setState(() {
                        file.compress = value ?? true;
                      });
                    },
                  ),
                  const Text('Compress', style: TextStyle(fontSize: 11)),
                ],
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
