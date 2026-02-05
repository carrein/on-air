import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show serverUrl;
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/media_provider.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';
import '../models/upload_file_data.dart';
import 'link_preview_card.dart';
import 'media_attachment_widget.dart';
import 'file_upload_dialog.dart';
import 'multi_file_upload_dialog.dart';
import 'media_sidebar.dart';

// Web-only imports
import 'dart:html' as html show window, document, ClipboardEvent, FileReader;

/// Chat view displaying notes in an inverted list (newest at bottom).
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (kIsWeb) {
      _setupWebEventListeners();
    }
  }

  void _setupWebEventListeners() {
    // Paste event listener
    html.window.addEventListener('paste', (event) {
      final pasteEvent = event as html.ClipboardEvent;
      _handleWebPaste(pasteEvent);
    });

    // Drag and drop event listeners
    html.document.addEventListener('dragover', (event) {
      event.preventDefault();
      // Check if dragging files
      try {
        final dataTransfer = (event as dynamic).dataTransfer;
        if (dataTransfer?.types?.contains('Files') ?? false) {
          setState(() => _isDragOver = true);
        }
      } catch (e) {
        // Ignore
      }
    });

    html.document.addEventListener('dragleave', (event) {
      setState(() => _isDragOver = false);
    });

    html.document.addEventListener('drop', (event) {
      event.preventDefault();
      setState(() => _isDragOver = false);
      _handleWebDrop(event);
    });
  }

  void _onScroll() {
    // Load more when scrolling near top (in reversed list)
    if (_scrollController.position.pixels < 100) {
      final channelId = ref.read(currentChannelProvider).value;
      if (channelId != null) {
        ref.read(notesProvider(channelId).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannelAsync = ref.watch(currentChannelProvider);

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: currentChannelAsync.when(
      data: (channelId) {
        final notesAsync = ref.watch(notesProvider(channelId));

        return notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return const Center(
                child: Text('No notes yet. Start typing below!'),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              reverse: true, // Newest at bottom
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteItem(note, channelId);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
        // Drag-over indicator
        if (_isDragOver)
          Container(
            color: Colors.blue.withValues(alpha: 0.2),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Drop file here to upload',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Media sidebar button (mobile/tablet only)
        if (!ResponsiveUtils.isDesktop(context))
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () => _showMediaSidebarBottomSheet(context),
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.photo_library, color: Colors.white),
            ),
          ),
      ],
    );
  }

  void _showMediaSidebarBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Media & Links',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Media sidebar content
              const Expanded(
                child: MediaSidebar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(Note note, int channelId) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Listener(
        onPointerDown: (event) {
          // Check for secondary button (right-click)
          if (event.buttons == 2) {
            _showNoteContextMenu(context, note, channelId, event.position);
          }
        },
        child: GestureDetector(
          onLongPress: () => _showNoteContextMenu(context, note, channelId, null),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Note content
                _buildNoteContent(note),
                const SizedBox(height: 8),
                // Timestamp
                Text(
                  _formatDateTime(note.createdAt),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteContent(Note note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show content only if not empty
        if (note.content.isNotEmpty)
          MarkdownBody(
            data: note.content,
            selectable: true,
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.tryParse(href);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: const TextStyle(fontSize: 16),
              a: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

        // Media attachments
        if (note.attachments != null && note.attachments!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              ...note.attachments!.map(
                (attachment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MediaAttachmentWidget(
                    attachment: attachment,
                    serverUrl: serverUrl,
                  ),
                ),
              ),
            ],
          ),

        // Link preview card
        if (note.linkPreview != null)
          LinkPreviewCard(preview: note.linkPreview!),
      ],
    );
  }

  void _showNoteContextMenu(BuildContext context, Note note, int channelId, Offset? globalPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // Use provided position (right-click) or calculate from center (long-press)
    final Offset position;
    if (globalPosition != null) {
      position = globalPosition;
    } else {
      // For long-press, use center of screen
      position = Offset(overlay.size.width / 2, overlay.size.height / 2);
    }

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy, size: 18),
              SizedBox(width: 12),
              Text('Copy'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18),
              SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'copy':
          _copyToClipboard(note.content);
          break;
        case 'edit':
          _startEditing(note);
          break;
        case 'delete':
          _deleteNote(note, channelId);
          break;
      }
    });
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));

    // Create preview: remove markdown line breaks and truncate
    final cleanContent = content.replaceAll('  \n', ' ').replaceAll('\n', ' ');
    final preview = cleanContent.length > 20
        ? '${cleanContent.substring(0, 20)}...'
        : cleanContent;

    ToastUtils.show(context, 'Copied: $preview', type: ToastType.info);
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _startEditing(Note note) {
    ref.read(editingNoteProvider.notifier).startEditing(note.id!);
  }

  void _deleteNote(Note note, int channelId) {
    ref.read(notesProvider(channelId).notifier).deleteNote(note.id!);
  }

  Future<void> _handleWebPaste(html.ClipboardEvent event) async {
    if (!mounted) return;

    try {
      // Check if paste target is input/textarea - let browser handle it
      final activeElement = html.document.activeElement;
      if (activeElement != null) {
        final activeTagName = activeElement.tagName.toLowerCase();
        if (activeTagName == 'input' ||
            activeTagName == 'textarea' ||
            activeElement.contentEditable == 'true') {
          return; // Let browser handle paste in editable elements
        }
      }

      final target = event.target;
      final targetTagName = (target as dynamic)?.tagName?.toLowerCase();
      if (targetTagName == 'input' || targetTagName == 'textarea') {
        return;
      }

      event.preventDefault();
      final clipboardData = event.clipboardData;
      if (clipboardData == null) return;

      final items = clipboardData.items;
      if (items == null) return;

      final length = items.length;
      if (length == null) return;

      // Collect all image/video files from clipboard
      final List<UploadFileData> uploadFiles = [];

      for (var i = 0; i < length; i++) {
        final item = items[i];
        final itemType = item.type;
        if (itemType != null && (itemType.startsWith('image/') || itemType.startsWith('video/'))) {
          final file = item.getAsFile();
          if (file == null) continue;

          // Read file as bytes
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;

          if (reader.result != null) {
            // FileReader result can be either ByteBuffer or Uint8List depending on browser
            final result = reader.result!;
            final Uint8List uint8List;
            if (result is ByteBuffer) {
              uint8List = result.asUint8List();
            } else {
              uint8List = result as Uint8List;
            }

            // Generate filename
            final extension = itemType.split('/').last;
            final fileName = 'pasted_file_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';

            uploadFiles.add(UploadFileData(
              bytes: uint8List,
              fileName: fileName,
              extension: extension,
              compress: true,
            ));
          }
        }
      }

      // Show appropriate dialog based on number of files
      if (uploadFiles.isEmpty) return;

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
      // Silently ignore paste errors
    }
  }

  Future<void> _handleWebDrop(dynamic event) async {
    if (!mounted) return;

    try {
      final dataTransfer = event.dataTransfer;
      if (dataTransfer == null) return;

      final files = dataTransfer.files;
      if (files == null || files.isEmpty) return;

      // Allowed MIME types (images, videos, and documents)
      const allowedTypes = [
        'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic',
        'video/mp4', 'video/quicktime', 'video/webm', 'video/x-msvideo', 'video/x-matroska',
        'application/pdf', 'text/plain', 'text/markdown',
        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'application/zip', 'application/x-zip-compressed',
      ];

      // Collect all valid files
      final List<UploadFileData> uploadFiles = [];

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final fileType = file.type.toLowerCase();

        if (allowedTypes.contains(fileType) || fileType.startsWith('image/') || fileType.startsWith('video/')) {
          // Read file as bytes
          final reader = html.FileReader();
          reader.readAsArrayBuffer(file);
          await reader.onLoadEnd.first;

          if (reader.result != null) {
            // FileReader result can be either ByteBuffer or Uint8List depending on browser
            final result = reader.result!;
            final Uint8List uint8List;
            if (result is ByteBuffer) {
              uint8List = result.asUint8List();
            } else {
              uint8List = result as Uint8List;
            }

            // Extract extension from filename
            final parts = file.name.split('.');
            final extension = parts.length > 1 ? parts.last : '';

            uploadFiles.add(UploadFileData(
              bytes: uint8List,
              fileName: file.name,
              extension: extension,
              compress: true,
            ));
          }
        }
      }

      // Show appropriate dialog based on number of files
      if (uploadFiles.isEmpty) return;

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
      // Silently ignore drop errors
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
            // Upload file and create note with empty content
            await ref.read(mediaUploadProvider.notifier).uploadImageAndCreateNote(
              channelId: channelId,
              noteContent: '',
              imageBytes: fileBytes,
              fileName: fileName,
              compress: compress,
            );

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

    if (mounted) {
      ToastUtils.show(context, '${uploadFiles.length} files uploaded', type: ToastType.success);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
