import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:on_air_client/on_air_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show serverUrl;
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/media_provider.dart';
import 'link_preview_card.dart';
import 'media_attachment_widget.dart';
import 'image_upload_dialog.dart';

// Web-only imports
import 'dart:html' as html show window, document, ClipboardEvent, File, FileReader, MouseEvent;
import 'dart:ui' as ui;

/// Chat view displaying notes in an inverted list (newest at bottom).
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _NotificationData {
  final OverlayEntry entry;
  final ValueNotifier<double> topNotifier;

  _NotificationData(this.entry, this.topNotifier);

  void remove() {
    entry.remove();
  }
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();
  bool _userScrolling = false;
  final List<_NotificationData> _activeNotifications = [];
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

    // Track if user is scrolling history
    _userScrolling = _scrollController.position.pixels > 50;
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
            color: Colors.blue.withOpacity(0.2),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Drop image here to upload',
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
      ],
    );
  }

  Widget _buildNoteItem(Note note, int channelId) {
    print('=== Building Note ===');
    print('Note ID: ${note.id}');
    print('Has attachments: ${note.attachments != null}');
    print('Attachment count: ${note.attachments?.length ?? 0}');
    if (note.attachments != null) {
      for (var att in note.attachments!) {
        print('  - Attachment ${att.id}: ${att.filePath}');
      }
    }
    print('===================');

    return ListTile(
      title: Column(
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
      ),
      subtitle: Text(
        _formatDateTime(note.createdAt),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onLongPress: () => _startEditing(note),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () => _copyToClipboard(note.content),
            tooltip: 'Copy',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _deleteNote(note, channelId),
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));

    // Create preview: remove markdown line breaks and truncate
    final cleanContent = content.replaceAll('  \n', ' ').replaceAll('\n', ' ');
    final preview = cleanContent.length > 20
        ? '${cleanContent.substring(0, 20)}...'
        : cleanContent;

    _showCopyNotification(preview);
  }

  void _showCopyNotification(String preview) {
    final overlay = Overlay.of(context);

    // Maximum 3 notifications - dismiss oldest if at limit
    if (_activeNotifications.length >= 3) {
      final oldest = _activeNotifications.removeAt(0);
      oldest.remove();
      // Recalculate positions for remaining notifications
      _updateNotificationPositions();
    }

    late _NotificationData notificationData;
    final topNotifier = ValueNotifier<double>(20.0 + (_activeNotifications.length * 48.0));

    final overlayEntry = OverlayEntry(
      builder: (context) => _CopyNotification(
        message: 'Copied: $preview',
        topNotifier: topNotifier,
        onDismiss: () {
          notificationData.remove();
          _activeNotifications.remove(notificationData);
          // Recalculate positions for remaining notifications
          _updateNotificationPositions();
        },
      ),
    );

    notificationData = _NotificationData(overlayEntry, topNotifier);
    _activeNotifications.add(notificationData);
    overlay.insert(overlayEntry);
  }

  void _updateNotificationPositions() {
    for (int i = 0; i < _activeNotifications.length; i++) {
      _activeNotifications[i].topNotifier.value = 20.0 + (i * 48.0);
    }
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
      event.preventDefault();
      final clipboardData = event.clipboardData;
      if (clipboardData == null) return;

      final items = clipboardData.items;
      if (items == null) return;

      final length = items.length;
      if (length == null) return;

      // Look for image files in clipboard
      for (var i = 0; i < length; i++) {
        final item = items[i];
        final itemType = item.type;
        if (itemType != null && itemType.startsWith('image/')) {
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
            final fileName = 'pasted_image_${DateTime.now().millisecondsSinceEpoch}.$extension';

            // Show upload dialog
            await _showImageUploadDialog(uint8List, fileName);
            return;
          }
        }
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

      // Process the first image file
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        if (file.type.startsWith('image/')) {
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

            // Show upload dialog
            await _showImageUploadDialog(uint8List, file.name);
            return;
          }
        }
      }
    } catch (e) {
      // Silently ignore drop errors
    }
  }

  Future<void> _showImageUploadDialog(Uint8List imageBytes, String fileName) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    await showDialog(
      context: context,
      builder: (context) => ImageUploadDialog(
        imageSource: imageBytes,
        fileName: fileName,
        onSend: (compress) async {
          try {
            // Upload image and create note with empty content
            await ref.read(mediaUploadProvider.notifier).uploadImageAndCreateNote(
              channelId: channelId,
              noteContent: '',
              imageBytes: imageBytes,
              fileName: fileName,
              compress: compress,
            );

            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image uploaded successfully')),
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
    _scrollController.dispose();
    super.dispose();
  }
}

/// Animated notification widget that fades in and out
class _CopyNotification extends StatefulWidget {
  final String message;
  final ValueNotifier<double> topNotifier;
  final VoidCallback onDismiss;

  const _CopyNotification({
    required this.message,
    required this.topNotifier,
    required this.onDismiss,
  });

  @override
  State<_CopyNotification> createState() => _CopyNotificationState();
}

class _CopyNotificationState extends State<_CopyNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start fade in
    _controller.forward();

    // Wait, then fade out
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismiss();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.topNotifier,
      builder: (context, top, child) {
        return AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          top: top,
          right: 20,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
