import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart' show serverUrl, client;
import '../providers/notes_provider.dart';
import '../providers/archive_items_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/media_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/background_provider.dart';
import '../utils/toast_utils.dart';
import '../utils/responsive_utils.dart';
import '../models/upload_file_data.dart';
import 'link_preview_card.dart';
import 'media_attachment_widget.dart';
import 'file_upload_dialog.dart';
import 'multi_file_upload_dialog.dart';
import 'media_sidebar.dart';
import 'styled_tooltip.dart';

// Cross-platform HTML imports
import 'package:universal_html/html.dart' as html;

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
    // Use 20% of max scroll extent or 500px, whichever is larger
    final threshold = (_scrollController.position.maxScrollExtent * 0.2).clamp(500.0, double.infinity);

    if (_scrollController.position.pixels < threshold) {
      final channelId = ref.read(currentChannelProvider).value;
      if (channelId != null) {
        ref.read(notesProvider(channelId).notifier).loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final selection = ref.watch(noteSelectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final currentBackground = ref.watch(backgroundPreferenceProvider);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(currentBackground.assetPath),
              repeat: ImageRepeat.repeat,
              scale: 1.0, // Original tile size
            ),
          ),
          child: currentChannelAsync.when(
      data: (channelId) {
        // Use archive items provider for Archive Crate
        if (channelId == -1) {
          return _buildArchiveView();
        }

        final notesAsync = ref.watch(notesProvider(channelId));

        return notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFFF52A1), width: 1.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/images/labs.svg',
                        width: 48,
                        height: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'It\'s quiet in here...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C1C),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final previousNote = index > 0 ? notes[index - 1] : null;

                // Check if we need a date separator
                final needsSeparator = previousNote != null &&
                    !_isSameDay(note.createdAt, previousNote.createdAt);

                return Column(
                  children: [
                    _buildNoteItem(note, channelId),
                    if (needsSeparator) _buildDateSeparator(previousNote.createdAt),
                  ],
                );
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
                      fontSize: 10,
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
        // Selection action bar (on top of everything)
        if (isSelectionMode)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Material(
              elevation: 0,
              color: const Color(0xFFFF52A1),
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          ref.read(noteSelectionProvider.notifier).clear();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${selection.length} selected',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/recycle.svg',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          final channelId = ref.read(currentChannelProvider).value;
                          if (channelId != null) {
                            _deleteSelectedNotes(channelId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
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
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {}, // Absorb taps on the sheet itself
          child: DraggableScrollableSheet(
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
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Media sidebar content with tabs
                  const Expanded(
                    child: MediaSidebar(fixedWidth: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(Note note, int channelId) {
    final selection = ref.watch(noteSelectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final isSelected = selection.contains(note.id);

    // Border color: consistent pink for all notes
    const borderColor = Color(0xFFCE2161);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection checkbox (visible in selection mode)
          if (isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: GestureDetector(
                onTap: () {
                  ref.read(noteSelectionProvider.notifier).toggle(note.id!);
                },
                child: isSelected
                    ? SvgPicture.asset(
                        'assets/images/checkmark.svg',
                        width: 24,
                        height: 24,
                      )
                    : const SizedBox(width: 24, height: 24),
              ),
            ),
          // Note content
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Listener(
                      onPointerDown: (event) {
                        // Check for secondary button (right-click)
                        if (event.buttons == 2) {
                          _showNoteContextMenu(context, note, channelId, event.position);
                        }
                      },
                      child: GestureDetector(
                        onTap: isSelectionMode
                            ? () {
                                ref.read(noteSelectionProvider.notifier).toggle(note.id!);
                              }
                            : null,
                        onLongPress: () {
                          if (isSelectionMode) {
                            ref.read(noteSelectionProvider.notifier).toggle(note.id!);
                          } else {
                            _showNoteContextMenu(context, note, channelId, null);
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
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
                                style: TextStyle(fontSize: 12, color: const Color(0xFF1C1C1C).withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Action buttons outside the note container
                  if (channelId == -1) ...[
                    // Restore button for Archive
                    const SizedBox(width: 12),
                    StyledTooltip(
                      message: 'Restore note',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _restoreNote(note),
                          child: SvgPicture.asset(
                            'assets/images/restore.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                    // Delete button for Archive
                    const SizedBox(width: 8),
                    StyledTooltip(
                      message: 'Delete note',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _deleteNote(note, channelId),
                          child: SvgPicture.asset(
                            'assets/images/cancel.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Archive button for regular channels
                    const SizedBox(width: 12),
                    StyledTooltip(
                      message: 'Archive note',
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _deleteNote(note, channelId),
                          child: SvgPicture.asset(
                            'assets/images/recycle.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveView() {
    final archiveAsync = ref.watch(archiveItemsProvider);

    return archiveAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFF52A1), width: 1.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/labs.svg',
                    width: 48,
                    height: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'It\'s quiet in here...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.type == 'note' && item.note != null) {
              return _buildNoteItem(item.note!, -1);
            } else if (item.type == 'channel' && item.channel != null) {
              return _buildArchivedChannelItem(item.channel!);
            }
            return const SizedBox.shrink();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildArchivedChannelItem(Channel channel) {
    const borderColor = Color(0xFFCE2161);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Listener(
                      onPointerDown: (event) {
                        if (event.buttons == 2) {
                          _showChannelArchiveContextMenu(context, channel, event.position);
                        }
                      },
                      child: GestureDetector(
                        onLongPress: () {
                          _showChannelArchiveContextMenu(context, channel, null);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: borderColor,
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                channel.emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  channel.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1C1C1C),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDADDD8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Channel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  StyledTooltip(
                    message: 'Restore channel',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _restoreChannel(channel),
                        child: SvgPicture.asset(
                          'assets/images/restore.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StyledTooltip(
                    message: 'Delete channel',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showDeleteChannelConfirmation(channel),
                        child: SvgPicture.asset(
                          'assets/images/cancel.svg',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChannelArchiveContextMenu(BuildContext context, Channel channel, Offset? globalPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset position;
    if (globalPosition != null) {
      position = globalPosition;
    } else {
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
          value: 'restore',
          child: Row(
            children: [
              Icon(Icons.restore, size: 18),
              SizedBox(width: 12),
              Text('Restore'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever, size: 18),
              SizedBox(width: 12),
              Text('Delete'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'restore':
          _restoreChannel(channel);
          break;
        case 'delete':
          _showDeleteChannelConfirmation(channel);
          break;
      }
    });
  }

  void _restoreChannel(Channel channel) async {
    try {
      await ref.read(archiveItemsProvider.notifier).restoreChannel(channel.id!);
      if (mounted) {
        ToastUtils.show(context, 'Channel restored', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Failed to restore: $e', type: ToastType.error);
      }
    }
  }

  void _showDeleteChannelConfirmation(Channel channel) async {
    // Fetch note count
    int noteCount = 0;
    try {
      noteCount = await client.chat.getArchivedChannelNoteCount(channel.id!);
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: Theme.of(context).copyWith(
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF00171F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
        child: AlertDialog(
          title: const Text(
            'Delete Channel',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Delete ${channel.emoji} ${channel.name} and $noteCount note${noteCount == 1 ? '' : 's'} permanently?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00171F),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(archiveItemsProvider.notifier).deleteChannel(channel.id!);
                  if (mounted) {
                    ToastUtils.show(context, 'Channel deleted permanently', type: ToastType.success);
                  }
                } catch (e) {
                  if (mounted) {
                    ToastUtils.show(context, 'Failed to delete: $e', type: ToastType.error);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: const Text('Delete'),
            ),
          ],
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
              p: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1C)),
              a: const TextStyle(
                fontSize: 10,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
              h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
              h4: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
              h5: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
              h6: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1C)),
              code: const TextStyle(color: Color(0xFF1C1C1C), backgroundColor: Color(0xFFDADDD8)),
              blockquote: const TextStyle(color: Color(0xFF1C1C1C)),
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

    // Check if in Archive channel
    final isArchiveChannel = channelId == -1;

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
        // Edit only in regular channels
        if (!isArchiveChannel)
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
        // Archive: show Restore + Delete; Regular: show Archive
        if (isArchiveChannel) ...[
          const PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                Icon(Icons.restore, size: 18),
                SizedBox(width: 12),
                Text('Restore'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_forever, size: 18),
                SizedBox(width: 12),
                Text('Delete'),
              ],
            ),
          ),
        ] else
          const PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                Icon(Icons.archive, size: 18),
                SizedBox(width: 12),
                Text('Archive'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'select',
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 18),
              SizedBox(width: 12),
              Text('Select'),
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
        case 'archive':
        case 'delete':
          _deleteNote(note, channelId);
          break;
        case 'restore':
          _restoreNote(note);
          break;
        case 'select':
          _enterSelectionMode(note.id!);
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
    // Convert to local time
    final localTime = dt.toLocal();

    // Format as "Jan 5, 2:30 PM" or "Jan 5, 14:30" for 24h
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[localTime.month - 1];
    final day = localTime.day;

    // 12-hour format with AM/PM
    final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';

    return '$month $day, $hour:$minute $period';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final aLocal = a.toLocal();
    final bLocal = b.toLocal();
    return aLocal.year == bLocal.year &&
           aLocal.month == bLocal.month &&
           aLocal.day == bLocal.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final localDate = date.toLocal();
    final now = DateTime.now();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));

    String dateText;
    if (_isSameDay(localDate, now)) {
      dateText = 'Today';
    } else if (_isSameDay(localDate, yesterday)) {
      dateText = 'Yesterday';
    } else {
      // Format as "February 6" or "February 6, 2025" if different year
      final months = ['January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December'];
      final month = months[localDate.month - 1];
      dateText = localDate.year == now.year
          ? '$month ${localDate.day}'
          : '$month ${localDate.day}, ${localDate.year}';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFDADDD8).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1C1C1C),
          ),
        ),
      ),
    );
  }

  void _startEditing(Note note) {
    ref.read(editingNoteProvider.notifier).startEditing(note.id!);
  }

  void _deleteNote(Note note, int channelId) {
    ref.read(notesProvider(channelId).notifier).deleteNote(note.id!);
  }

  void _restoreNote(Note note) async {
    try {
      await client.chat.restoreNote(note.id!);
      if (mounted) {
        ToastUtils.show(context, 'Note restored', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Failed to restore: $e', type: ToastType.error);
      }
    }
  }

  void _enterSelectionMode(int noteId) {
    ref.read(noteSelectionProvider.notifier).select(noteId);
  }

  void _deleteSelectedNotes(int channelId) async {
    final selection = ref.read(noteSelectionProvider);
    final notifier = ref.read(notesProvider(channelId).notifier);

    // Delete all selected notes
    for (final noteId in selection) {
      await notifier.deleteNote(noteId);
    }

    // Clear selection
    ref.read(noteSelectionProvider.notifier).clear();

    if (mounted) {
      ToastUtils.show(
        context,
        'Deleted ${selection.length} note${selection.length > 1 ? 's' : ''}',
        type: ToastType.success,
      );
    }
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
