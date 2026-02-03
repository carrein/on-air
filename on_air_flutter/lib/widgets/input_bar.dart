import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/media_provider.dart';
import 'input_link_preview.dart';
import 'file_upload_dialog.dart';

/// Input bar for creating and editing notes.
class InputBar extends ConsumerStatefulWidget {
  const InputBar({super.key});

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _previewUrl;
  bool _showPreview = true;

  String? _extractFirstUrl(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(text);
    return match?.group(0);
  }

  void _onTextChanged(String text) {
    setState(() {
      final url = _extractFirstUrl(text);
      if (url != _previewUrl) {
        _previewUrl = url;
        _showPreview = url != null;
      }
    });
  }

  void _populateEditingNote(int noteId) {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    final notes = ref.read(notesProvider(channelId)).value;
    if (notes == null) return;

    final note = notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => notes.first,
    );

    _controller.text = note.content;
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final editingNoteId = ref.watch(editingNoteProvider);
    final isEditMode = editingNoteId != null;

    // Listen for editing state changes to populate the field
    ref.listen(editingNoteProvider, (prev, next) {
      if (next != null && prev != next) {
        _populateEditingNote(next);
      }
    });

    return Column(
      children: [
        // Link preview (show above input when URL detected)
        if (_showPreview && _previewUrl != null && !isEditMode)
          InputLinkPreview(
            url: _previewUrl!,
            onDismiss: () => setState(() => _showPreview = false),
          ),

        // Input bar
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
          ),
          child: Row(
            children: [
              if (isEditMode)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelEditing,
                  tooltip: 'Cancel',
                ),
              Expanded(
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      // Handle Enter key
                      if (event.logicalKey == LogicalKeyboardKey.enter) {
                        // Check if Shift is NOT pressed
                        if (!HardwareKeyboard.instance.isShiftPressed) {
                          _submit();
                        }
                        // If Shift IS pressed, do nothing and let TextField handle it
                      }
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: isEditMode ? 'Edit note... (Shift+Enter for new line)' : 'Type a note... (Shift+Enter for new line)',
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isEditMode)
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickFile,
                  tooltip: 'Upload file',
                ),
              IconButton(
                icon: Icon(isEditMode ? Icons.save : Icons.send),
                onPressed: _controller.text.trim().isEmpty ? null : _submit,
                tooltip: isEditMode ? 'Save' : 'Send',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submit() {
    final rawContent = _controller.text.trim();
    if (rawContent.isEmpty) return;

    // Convert newlines to markdown line breaks (two spaces + newline)
    final content = rawContent.replaceAll('\n', '  \n');

    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    final editingNoteId = ref.read(editingNoteProvider);

    if (editingNoteId != null) {
      // Update existing note
      ref.read(notesProvider(channelId).notifier).updateNote(
            editingNoteId,
            content,
          );
      ref.read(editingNoteProvider.notifier).cancelEditing();
    } else {
      // Create new note
      ref.read(notesProvider(channelId).notifier).createNote(content);
    }

    // Reset preview state and clear text field
    setState(() {
      _controller.clear();
      _previewUrl = null;
      _showPreview = true;
    });

    // Refocus after clearing
    _focusNode.requestFocus();
  }

  void _cancelEditing() {
    ref.read(editingNoteProvider.notifier).cancelEditing();

    // Reset preview state and clear text field
    setState(() {
      _controller.clear();
      _previewUrl = null;
      _showPreview = true;
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', // Images
          'pdf', 'txt', 'md', // Documents
          'doc', 'docx', 'xls', 'xlsx', // Office
          'zip', // Archives
        ],
        withData: true, // Get bytes for web
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to read file')),
          );
        }
        return;
      }

      // Show upload dialog
      await _showFileUploadDialog(bytes, file.name, file.extension ?? '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _showFileUploadDialog(Uint8List fileBytes, String fileName, String extension) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    await showDialog(
      context: context,
      builder: (context) => FileUploadDialog(
        fileBytes: fileBytes,
        fileName: fileName,
        fileExtension: extension,
        onSend: (compress) async {
          try {
            // Get current text content
            final noteContent = _controller.text.trim().isEmpty
                ? ''
                : _controller.text.trim();

            // Upload file and create note
            await ref.read(mediaUploadProvider.notifier).uploadImageAndCreateNote(
              channelId: channelId,
              noteContent: noteContent,
              imageBytes: fileBytes,
              fileName: fileName,
              compress: compress,
            );

            // Clear text field
            _controller.clear();
            setState(() {
              _previewUrl = null;
              _showPreview = true;
            });

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File uploaded successfully')),
              );
            }
          } catch (e) {
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upload failed: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
