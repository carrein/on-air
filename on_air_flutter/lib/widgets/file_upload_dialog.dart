import 'dart:typed_data';
import 'package:flutter/material.dart';

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

  IconData get _fileIcon {
    final ext = widget.fileExtension.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'txt':
      case 'md':
        return Icons.description;
      case 'doc':
      case 'docx':
        return Icons.article;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String get _fileSizeFormatted {
    final bytes = widget.fileBytes.length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isImage ? 'Upload Image' : 'Upload File'),
      content: SizedBox(
        width: _isImage ? 400 : 300,
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

            // Compression option (images only)
            if (_isImage)
              CheckboxListTile(
                title: const Text('Compress image'),
                subtitle: const Text('Reduces file size, maintains quality'),
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
      await widget.onSend(_isImage ? _compress : false);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _uploading = false);
      rethrow; // Let parent handle error display
    }
  }
}
