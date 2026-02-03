import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../utils/file_utils.dart';

/// Dialog for uploading files (images or documents).
/// Shows appropriate preview based on file type.
class FileUploadDialog extends StatefulWidget {
  final Uint8List fileBytes;
  final String fileName;
  final String fileExtension;
  final Future<void> Function(bool compress) onSend;

  const FileUploadDialog({
    super.key,
    required this.fileBytes,
    required this.fileName,
    required this.fileExtension,
    required this.onSend,
  });

  @override
  State<FileUploadDialog> createState() => _FileUploadDialogState();
}

class _FileUploadDialogState extends State<FileUploadDialog> {
  bool _compress = true;
  bool _uploading = false;

  bool get _isImage {
    final ext = widget.fileExtension.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
  }

  bool get _isVideo {
    final ext = widget.fileExtension.toLowerCase();
    return ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);
  }

  IconData get _fileIcon => FileUtils.getFileIcon(widget.fileExtension);

  String get _fileSizeFormatted => FileUtils.formatFileSize(widget.fileBytes.length);

  @override
  Widget build(BuildContext context) {
    final String title = _isImage
        ? 'Upload Image'
        : _isVideo
            ? 'Upload Video'
            : 'Upload File';
    final double dialogWidth = (_isImage || _isVideo) ? 400 : 300;

    return AlertDialog(
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
                  child: Image.memory(
                    widget.fileBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            else if (_isVideo)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.video_library, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      widget.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fileSizeFormatted,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(_fileIcon, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      widget.fileName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fileSizeFormatted,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Compression option (images and videos)
            if (_isImage || _isVideo)
              CheckboxListTile(
                title: Text(_isVideo ? 'Compress video' : 'Compress image'),
                subtitle: Text(_isVideo
                    ? kIsWeb
                        ? 'Server-side compression to 720p (recommended)'
                        : 'Reduces file size to 720p, maintains quality'
                    : 'Reduces file size, maintains quality'),
                value: _compress,
                onChanged: _uploading
                    ? null
                    : (value) => setState(() => _compress = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _uploading ? null : _handleSend,
          child: _uploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
    );
  }

  Future<void> _handleSend() async {
    setState(() => _uploading = true);

    try {
      // For documents, compression is N/A, pass false
      final shouldCompress = (_isImage || _isVideo) ? _compress : false;
      await widget.onSend(shouldCompress);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _uploading = false);
      rethrow; // Let parent handle error display
    }
  }
}
