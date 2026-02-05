import 'package:flutter/material.dart';

import '../models/upload_file_data.dart';

/// Dialog for uploading multiple files.
class MultiFileUploadDialog extends StatefulWidget {
  final List<UploadFileData> files;
  final Future<void> Function(List<UploadFileData> files) onSend;

  const MultiFileUploadDialog({
    super.key,
    required this.files,
    required this.onSend,
  });

  @override
  State<MultiFileUploadDialog> createState() => _MultiFileUploadDialogState();
}

class _MultiFileUploadDialogState extends State<MultiFileUploadDialog> {
  bool _uploading = false;
  int _uploadedCount = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Upload ${widget.files.length} files'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // File list
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

            if (_uploading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _uploadedCount / widget.files.length,
              ),
              const SizedBox(height: 8),
              Text('Uploading $_uploadedCount of ${widget.files.length}...'),
            ],
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
              : const Text('Upload All'),
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
                  child: Image.memory(
                    file.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(file.fileIcon, size: 40);
                    },
                  ),
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
                  onChanged: _uploading
                      ? null
                      : (value) {
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

  Future<void> _handleSend() async {
    setState(() {
      _uploading = true;
      _uploadedCount = 0;
    });

    try {
      // Upload files one by one to avoid overwhelming the server
      for (var i = 0; i < widget.files.length; i++) {
        await widget.onSend([widget.files[i]]);

        if (mounted) {
          setState(() {
            _uploadedCount = i + 1;
          });
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _uploading = false);
      rethrow; // Let parent handle error display
    }
  }
}
