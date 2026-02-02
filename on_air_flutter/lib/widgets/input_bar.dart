import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import 'input_link_preview.dart';

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
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      // Check if Shift is NOT pressed
                      if (!HardwareKeyboard.instance.isShiftPressed) {
                        _submit();
                      }
                      // If Shift IS pressed, do nothing and let TextField handle it
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
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
