import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/media_provider.dart';
import '../providers/drafts_provider.dart';
import '../utils/toast_utils.dart';
import '../models/upload_file_data.dart';
import 'input_link_preview.dart';
import 'file_upload_dialog.dart';
import 'multi_file_upload_dialog.dart';
import 'icon_button_styled.dart';

/// Input bar for creating and editing notes.
class InputBar extends ConsumerStatefulWidget {
  const InputBar({super.key});

  @override
  ConsumerState<InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<InputBar> {
  // -- Colors (from Theme.md) --
  static const _barBackground = Color(0xFF191C2F);
  static const _fieldFill = Colors.transparent;
  static const _iconColor = Color(0xFFFF52A1);        // brand.accent
  static const _iconDisabledAlpha = 0.4;
  static const _hintTextColor = Color(0xFFFF52A1);    // brand.accent
  static const _hintTextAlpha = 0.8;

  // -- Layout --
  static const _barPadding = EdgeInsets.only(left: 10, top: 8, bottom: 8, right: 6);
  static const _fieldContentPadding = EdgeInsets.zero;
  static const _iconGap = 2.0;
  static const _fieldBorderRadius = 0.0;              // no border radius
  static const _iconSize = 24.0;

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

    // Listen for channel changes to save/load drafts
    ref.listen(currentChannelProvider, (prev, next) {
      if (isEditMode) return; // Don't save/load drafts while editing

      next.whenData((nextChannelId) {
        // Get previous channel ID
        final prevChannelId = prev?.valueOrNull;

        // Save draft for previous channel if switching
        if (prevChannelId != null && prevChannelId != nextChannelId) {
          final currentText = _controller.text;
          ref.read(draftsProvider.notifier).saveDraft(prevChannelId, currentText);
        }

        // Load draft for new channel
        if (nextChannelId != prevChannelId) {
          final draft = ref.read(draftsProvider.notifier).getDraft(nextChannelId);
          _controller.text = draft;
        }
      });
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
          padding: _barPadding,
          decoration: const BoxDecoration(
            color: _barBackground,
          ),
          child: Row(
            children: [
              if (isEditMode)
                IconButton(
                  icon: Icon(Icons.close, color: _iconColor),
                  onPressed: _cancelEditing,
                ),
              Expanded(
                child: Shortcuts(
                  shortcuts: const {
                    SingleActivator(LogicalKeyboardKey.enter): _SubmitIntent(),
                  },
                  child: Actions(
                    actions: {
                      _SubmitIntent: CallbackAction<_SubmitIntent>(
                        onInvoke: (_) {
                          _submit();
                          return null;
                        },
                      ),
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: _iconColor,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: isEditMode ? 'Edit note... (Shift+Enter for new line)' : 'Keyboard goes brrrr...',
                        hintStyle: TextStyle(
                          color: _hintTextColor.withValues(alpha: _hintTextAlpha),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(_fieldBorderRadius),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _fieldFill,
                        contentPadding: _fieldContentPadding,
                      ),
                      onChanged: _onTextChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _iconGap),
              if (isEditMode) ...[
                IconButton(
                  icon: Icon(
                    Icons.check,
                    color: _controller.text.trim().isEmpty
                        ? _iconColor.withValues(alpha: _iconDisabledAlpha)
                        : _iconColor,
                  ),
                  onPressed: _controller.text.trim().isEmpty ? null : _submit,
                ),
              ] else ...[
                _buildActionIcons(),
              ],
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
      // Clear draft after sending
      ref.read(draftsProvider.notifier).clearDraft(channelId);
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

  static const _animDuration = Duration(milliseconds: 250);
  static const _animCurve = Curves.easeInOut;
  static const _duotoneColor = Color(0xFFF9A302);

  Widget _buildActionIcons() {
    final hasText = _controller.text.trim().isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Camera — fades in/out
        if (!kIsWeb)
          AnimatedOpacity(
            opacity: hasText ? 0.0 : 1.0,
            duration: _animDuration,
            curve: _animCurve,
            child: AnimatedSize(
              duration: _animDuration,
              curve: _animCurve,
              child: hasText
                  ? const SizedBox.shrink()
                  : IconButtonStyled(
                      icon: PhosphorIconsDuotone.camera,
                      onPressed: _capturePhoto,

                      size: _iconSize,
                      duotoneSecondaryColor: _duotoneColor,
                    ),
            ),
          ),
        // Gap between camera and attachment/send
        if (!kIsWeb)
          AnimatedSize(
            duration: _animDuration,
            curve: _animCurve,
            child: hasText ? const SizedBox.shrink() : const SizedBox(width: 2),
          ),
        // Attachment zooms out / Send zooms in (shared slot)
        AnimatedSwitcher(
          duration: _animDuration,
          switchInCurve: _animCurve,
          switchOutCurve: _animCurve,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: child,
          ),
          child: hasText
              ? IconButtonStyled(
                  key: const ValueKey('send'),
                  icon: PhosphorIconsDuotone.paperPlaneRight,
                  onPressed: _submit,

                  size: _iconSize,
                  duotoneSecondaryColor: _duotoneColor,
                )
              : IconButtonStyled(
                  key: const ValueKey('attach'),
                  icon: PhosphorIconsDuotone.paperclip,
                  onPressed: _pickFile,

                  size: _iconSize,
                  duotoneSecondaryColor: _duotoneColor,
                ),
        ),
      ],
    );
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

  Future<void> _capturePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      final fileName = photo.name;
      final ext = fileName.split('.').last;

      await _showFileUploadDialog(bytes, fileName, ext);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Camera failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', // Images
          'mp4', 'mov', 'webm', 'avi', 'mkv', // Videos
          'pdf', 'txt', 'md', // Documents
          'doc', 'docx', 'xls', 'xlsx', // Office
          'zip', // Archives
        ],
        withData: true, // Get bytes for web
        allowMultiple: true, // Allow multiple file selection
      );

      if (result == null || result.files.isEmpty) return;

      // Collect all valid files
      final List<UploadFileData> uploadFiles = [];
      for (final file in result.files) {
        if (file.bytes != null) {
          uploadFiles.add(UploadFileData(
            bytes: file.bytes!,
            fileName: file.name,
            extension: file.extension ?? '',
          ));
        }
      }

      if (uploadFiles.isEmpty) {
        if (mounted) {
          ToastUtils.show(context, 'Failed to read files', type: ToastType.error);
        }
        return;
      }

      // Show appropriate dialog based on number of files
      if (uploadFiles.length == 1) {
        await _showFileUploadDialog(
          uploadFiles.first.bytes,
          uploadFiles.first.fileName,
          uploadFiles.first.extension,
        );
      } else {
        await _showMultiFileUploadDialog(uploadFiles);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Failed to pick file: $e', type: ToastType.error);
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
              ToastUtils.show(context, 'File uploaded successfully', type: ToastType.success);
            }
          } catch (e) {
            // Show error message
            if (mounted) {
              ToastUtils.show(context, 'Upload failed: $e', type: ToastType.error);
            }
          }
        },
      ),
    );
  }

  Future<void> _showMultiFileUploadDialog(List<UploadFileData> uploadFiles) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    await showDialog(
      context: context,
      builder: (context) => MultiFileUploadDialog(
        files: uploadFiles,
        onSend: (files) async {
          for (final file in files) {
            try {
              await ref.read(mediaUploadProvider.notifier).uploadImageAndCreateNote(
                channelId: channelId,
                noteContent: '',
                imageBytes: file.bytes,
                fileName: file.fileName,
                compress: file.compress,
              );
            } catch (e) {
              if (mounted) {
                ToastUtils.show(context, 'Upload failed for ${file.fileName}: $e', type: ToastType.error);
              }
            }
          }
        },
      ),
    );

    _controller.clear();
    if (mounted) {
      ToastUtils.show(context, '${uploadFiles.length} files uploaded', type: ToastType.success);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}
