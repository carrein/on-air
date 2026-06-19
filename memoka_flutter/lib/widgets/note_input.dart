import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/input_focus_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/pending_uploads_provider.dart';
import '../services/klipy_service.dart';
import '../utils/toast_utils.dart';
import '../utils/url_utils.dart';
import '../models/upload_file_data.dart';
import 'input_link_preview.dart';
import 'gif_picker_sheet.dart';
import 'multi_file_upload_dialog.dart';
import 'icon_button_styled.dart';

/// Note input for creating and editing notes.
class NoteInput extends ConsumerStatefulWidget {
  const NoteInput({super.key});

  @override
  ConsumerState<NoteInput> createState() => _NoteInputState();
}

class _NoteInputState extends ConsumerState<NoteInput>
    with WidgetsBindingObserver {
  // -- Colors (from DesignSystem.md) --
  static const _barBackground = Color(0xFFFFFDF6);
  static const _fieldFill = Colors.transparent;
  static const _borderColor = Color(0xFF3450A3);
  static const _iconColor = Color(0xFF3450A3);
  static const _iconDisabledAlpha = 0.4;
  static const _hintTextColor = Color(0xFF00171F);
  static const _hintTextAlpha = 0.4;

  // -- Layout --
  static const _barPadding = EdgeInsets.only(
    left: 10,
    top: 8,
    bottom: 8,
    right: 6,
  );
  static const _fieldContentPadding = EdgeInsets.zero;
  static const _iconGap = 2.0;
  static const _fieldBorderRadius = 0.0; // no border radius

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _previewUrl;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      ref.read(noteSelectionProvider.notifier).clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && _focusNode.hasFocus) {
      // Android dismisses the keyboard when the window loses focus on
      // background. Wait one frame for Flutter's InputConnection to
      // re-establish, then re-show the keyboard.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focusNode.hasFocus) {
          SystemChannels.textInput.invokeMethod('TextInput.show');
        }
      });
    }
  }

  String? _extractFirstUrl(String text) {
    final match = urlPattern.firstMatch(text);
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

    // Listen for Ctrl+K focus requests from ChatScreen.
    ref.listen(inputFocusRequestProvider, (prev, next) {
      if (next) {
        _focusNode.requestFocus();
        ref.read(inputFocusRequestProvider.notifier).consume();
      }
    });

    // Listen for editing state changes to populate the field
    ref.listen(editingNoteProvider, (prev, next) {
      if (next != null && prev != next) {
        _populateEditingNote(next);
      } else if (next == null && prev != null) {
        // Edit mode cancelled externally (e.g. sidebar switching channels).
        // Clear the field so stale note content doesn't bleed into the new channel.
        setState(() {
          _controller.clear();
          _previewUrl = null;
          _showPreview = true;
        });
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

        // NoteInput
        Container(
          padding: _barPadding,
          decoration: const BoxDecoration(
            color: _barBackground,
            border: Border(top: BorderSide(color: _borderColor, width: 1)),
          ),
          child: Row(
            children: [
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
                      style: const TextStyle(color: Color(0xFF00171F)),
                      cursorColor: _iconColor,
                      decoration: InputDecoration(
                        isDense: false,
                        hintText: isEditMode
                            ? 'Edit note... (Shift+Enter for new line)'
                            : 'Keyboard goes brrrr...',
                        hintStyle: TextStyle(
                          color: _hintTextColor.withValues(
                            alpha: _hintTextAlpha,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            _fieldBorderRadius,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: _fieldFill,
                        hoverColor: Colors.transparent,
                        contentPadding: _fieldContentPadding,
                      ),
                      onChanged: _onTextChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _iconGap),
              if (isEditMode) ...[
                IconButtonStyled(
                  icon: PhosphorIcons.xCircle(),
                  onPressed: _cancelEditing,
                ),
                const SizedBox(width: 4),
                IconButtonStyled(
                  icon: PhosphorIcons.highlighter(),
                  onPressed: _submit,
                  color: _controller.text.trim().isEmpty
                      ? _iconColor.withValues(alpha: _iconDisabledAlpha)
                      : _iconColor,
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
      ref
          .read(notesProvider(channelId).notifier)
          .updateNote(
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

  static const _animDuration = Duration(milliseconds: 200);
  static const _animCurve = Curves.easeInOut;

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
                      icon: PhosphorIcons.camera(),
                      onPressed: _capturePhoto,
                    ),
            ),
          ),
        // Gap between camera and GIF
        if (!kIsWeb)
          AnimatedSize(
            duration: _animDuration,
            curve: _animCurve,
            child: hasText ? const SizedBox.shrink() : const SizedBox(width: 2),
          ),
        // GIF button — fades out when text is present
        if (KlipyService.isAvailable)
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
                      icon: PhosphorIcons.cat(),
                      onPressed: _pickGif,
                    ),
            ),
          ),
        // Gap between GIF and attachment/send
        if (KlipyService.isAvailable)
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
                  icon: PhosphorIcons.paperPlaneRight(),
                  onPressed: _submit,
                )
              : IconButtonStyled(
                  key: const ValueKey('attach'),
                  icon: PhosphorIcons.paperclip(),
                  onPressed: _pickFile,
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

      final fileName = photo.name;
      final ext = fileName.split('.').last;

      await _showMultiFileUploadDialog([
        UploadFileData(
          filePath: photo.path,
          fileName: fileName,
          extension: ext,
        ),
      ]);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Camera failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _pickGif() async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    final gif = await showModalBottomSheet<KlipyGif>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GifPickerSheet(),
    );
    if (gif == null || !mounted) return;

    try {
      final response = await http.get(Uri.parse(gif.url));
      if (response.statusCode != 200) {
        if (mounted) {
          ToastUtils.show(
            context,
            'Failed to download GIF',
            type: ToastType.error,
          );
        }
        return;
      }

      final fileName = '${gif.id}.gif';

      ref
          .read(pendingUploadsProvider.notifier)
          .enqueue(
            channelId: channelId,
            fileBytes: response.bodyBytes,
            fileName: fileName,
            noteContent: '',
            mediaWidth: gif.width,
            mediaHeight: gif.height,
          );
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          'Failed to send GIF: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb, // Only load bytes on web
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Collect all valid files
      final List<UploadFileData> uploadFiles = [];
      for (final file in result.files) {
        if (kIsWeb) {
          // Web: must use bytes
          if (file.bytes != null) {
            uploadFiles.add(
              UploadFileData(
                bytes: file.bytes!,
                fileName: file.name,
                extension: file.extension ?? '',
              ),
            );
          }
        } else {
          // Native: use file path (no bytes loaded into memory)
          if (file.path != null) {
            uploadFiles.add(
              UploadFileData(
                filePath: file.path!,
                fileName: file.name,
                extension: file.extension ?? '',
              ),
            );
          }
        }
      }

      if (uploadFiles.isEmpty) {
        if (mounted) {
          ToastUtils.show(
            context,
            'Failed to read files',
            type: ToastType.error,
          );
        }
        return;
      }

      // Show appropriate dialog based on number of files
      await _showMultiFileUploadDialog(uploadFiles);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          'Failed to pick file: $e',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _showMultiFileUploadDialog(
    List<UploadFileData> uploadFiles,
  ) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    // If dialog is already open, add files to it instead of opening a second.
    if (MultiFileUploadDialog.isOpen) {
      MultiFileUploadDialog.addFiles(uploadFiles);
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => MultiFileUploadDialog(
        key: MultiFileUploadDialog.activeKey,
        files: uploadFiles,
        onSend: (files) {
          // Enqueue all files — ghost notes appear immediately,
          // uploads proceed sequentially in the queue.
          for (final file in files) {
            ref
                .read(pendingUploadsProvider.notifier)
                .enqueue(
                  channelId: channelId,
                  filePath: file.filePath,
                  fileBytes: file.bytes,
                  fileName: file.fileName,
                  noteContent: '',
                  thumbnailBytes: file.thumbnailBytes,
                );
          }
        },
      ),
    );

    _controller.clear();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class _SubmitIntent extends Intent {
  const _SubmitIntent();
}
