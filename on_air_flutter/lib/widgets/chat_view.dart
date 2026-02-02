import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:on_air_client/on_air_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import 'link_preview_card.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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

    return currentChannelAsync.when(
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
    );
  }

  Widget _buildNoteItem(Note note, int channelId) {
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
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
