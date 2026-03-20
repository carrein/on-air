import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../models/upload_file_data.dart';

/// Dialog for uploading files (images or documents).
/// Shows appropriate preview based on file type.
///
/// Accepts an [UploadFileData] which may hold either a [filePath] (native)
/// or raw [bytes] (web).
class FileUploadDialog extends StatefulWidget {
  final UploadFileData file;
  final void Function(bool compress) onSend;

  const FileUploadDialog({
    super.key,
    required this.file,
    required this.onSend,
  });

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  bool _compress = false;

  bool get _isImage => widget.file.isImage;
  bool get _isVideo => widget.file.isVideo;

  IconData get _fileIcon => widget.file.fileIcon;
  String get _fileSizeFormatted => widget.file.fileSizeFormatted;

  @override
  Widget build(BuildContext context) {
    final String title = _isImage
        ? 'Upload Image'
        : _isVideo
        ? 'Upload Video'
        : 'Upload File';
    final double dialogWidth = (_isImage || _isVideo) ? 400 : 300;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): _SendIntent(),
      },
      child: Actions(
        actions: {
          _SendIntent: CallbackAction<_SendIntent>(
            onInvoke: (_) {
              _handleSend();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: dialogWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview
                  if (_isImage)
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: _buildImagePreview(),
                      ),
                    )
                  else if (_isVideo)
                    Center(
                      child: Column(
                        children: [
                          PhosphorIcon(
                            PhosphorIcons.filmStrip(),
                            size: 64,
                            color: const Color(
                              0xFF00171F,
                            ).withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.file.fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fileSizeFormatted,
                            style: TextStyle(
                              color: const Color(
                                0xFF00171F,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            _fileIcon,
                            size: 64,
                            color: const Color(
                              0xFF00171F,
                            ).withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.file.fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _fileSizeFormatted,
                            style: TextStyle(
                              color: const Color(
                                0xFF00171F,
                              ).withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Compression option (videos only)
                  if (_isVideo)
                    CheckboxListTile(
                      title: const Text('Compress video'),
                      subtitle: const Text(
                        'Server-side compression to 720p (recommended)',
                      ),
                      value: _compress,
                      onChanged: (value) =>
                          setState(() => _compress = value ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _handleSend,
                child: const Text('Send'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (!kIsWeb && widget.file.filePath != null) {
      return Image.file(
        File(widget.file.filePath!),
        fit: BoxFit.contain,
        cacheWidth: 800,
      );
    }
    if (widget.file.bytes != null) {
      return Image.memory(
        widget.file.bytes!,
        fit: BoxFit.contain,
        cacheWidth: 800,
      );
    }
    return const SizedBox.shrink();
  }

  void _handleSend() {
    final shouldCompress = _isVideo ? _compress : false;
    Navigator.of(context).pop();
    widget.onSend(shouldCompress);
  }
}

class _SendIntent extends Intent {
  const _SendIntent();
}
