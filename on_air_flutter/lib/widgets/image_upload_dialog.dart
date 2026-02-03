import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Dialog for confirming image upload with compression option.
class ImageUploadDialog extends StatefulWidget {
  final dynamic imageSource; // File or Uint8List
  final String? fileName;
  final Function(bool compress) onSend;

  const ImageUploadDialog({
    super.key,
    required this.imageSource,
    this.fileName,
    required this.onSend,
  });

  @override
  State<ImageUploadDialog> createState() => _ImageUploadDialogState();
}

class _ImageUploadDialogState extends State<ImageUploadDialog> {
  bool _compress = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              'Upload Image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Image preview
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: Center(
                  child: _buildImagePreview(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File name
            if (widget.fileName != null)
              Text(
                widget.fileName!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 16),

            // Compression checkbox
            Row(
              children: [
                Checkbox(
                  value: _compress,
                  onChanged: (value) {
                    setState(() {
                      _compress = value ?? true;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                Expanded(
                  child: Text(
                    'Compress image (recommended)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSend(_compress);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (widget.imageSource is File) {
      return Image.file(
        widget.imageSource as File,
        fit: BoxFit.contain,
      );
    } else if (widget.imageSource is Uint8List) {
      return Image.memory(
        widget.imageSource as Uint8List,
        fit: BoxFit.contain,
      );
    } else {
      return const Icon(
        Icons.broken_image,
        color: Colors.grey,
        size: 48,
      );
    }
  }
}
