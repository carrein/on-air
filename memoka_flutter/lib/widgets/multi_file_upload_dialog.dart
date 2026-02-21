import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/upload_file_data.dart';

/// Dialog for uploading multiple files.
///
/// Shows a list of files with per-file compression toggles. On send, pops
/// immediately and lets the caller enqueue uploads optimistically.
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
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upload ${widget.files.length} files'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.files.length,
                itemBuilder: (context, index) {
                  final file = widget.files[index];
                  return _buildFileItem(file, index);
                },
              ),
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
          child: const Text('Upload All'),
        ),
      ],
    );
  }

  Widget _buildFileItem(UploadFileData file, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon/Preview
            if (file.isImage)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: _buildImagePreview(file),
                ),
              )
            else
              Icon(file.fileIcon, size: 40, color: Colors.grey[600]),

            const SizedBox(width: 12),

            // File info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    file.fileSizeFormatted,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Compress checkbox (for images and videos)
            if (file.isImage || file.isVideo)
              SizedBox(
                width: 140,
                child: CheckboxListTile(
                  title: const Text('Compress', style: TextStyle(fontSize: 12)),
                  value: file.compress,
                  dense: true,
                  onChanged: (value) {
                    setState(() {
                      file.compress = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(UploadFileData file) {
    if (!kIsWeb && file.filePath != null) {
      return Image.file(
        File(file.filePath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(file.fileIcon, size: 40);
        },
      );
    }
    if (file.bytes != null) {
      return Image.memory(
        file.bytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(file.fileIcon, size: 40);
        },
      );
    }
    return Icon(file.fileIcon, size: 40);
  }

  void _handleSend() {
    Navigator.of(context).pop();
    widget.onSend(widget.files);
  }
}
