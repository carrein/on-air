import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart' show serverUrl, client;
import '../providers/notes_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/note_selection_provider.dart';
import '../utils/toast_utils.dart';
import '../utils/file_utils.dart';
import 'link_preview_card.dart';
import 'media_attachment_widget.dart';

/// Individual note card with content, footer actions, and context menu.
class NoteItem extends ConsumerWidget {
  const NoteItem({
    super.key,
    required this.note,
    required this.channelId,
    this.allImageUrls = const [],
  });

  final Note note;
  final int channelId;
  final List<String> allImageUrls;

  static bool isMediaOnly(Note note) {
    if (note.content.isNotEmpty) return false;
    final attachments = note.attachments;
    if (attachments == null || attachments.isEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(noteSelectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final isSelected = selection.contains(note.id);

    const borderColor = Color(0xFFCE2161);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection checkbox (visible in selection mode)
          if (isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: GestureDetector(
                onTap: () => ref.read(noteSelectionProvider.notifier).toggle(note.id!),
                child: isSelected
                    ? PhosphorIcon(PhosphorIcons.checkCircle(), size: 24, color: const Color(0xFFCE2161))
                    : PhosphorIcon(PhosphorIcons.circle(), size: 24, color: const Color(0xFFCE2161)),
              ),
            ),
          // Note content
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                child: Listener(
                  onPointerDown: (event) {
                    if (event.buttons == 2) {
                      _showContextMenu(context, ref, event.position);
                    }
                  },
                  child: GestureDetector(
                    onTap: isSelectionMode
                        ? () => ref.read(noteSelectionProvider.notifier).toggle(note.id!)
                        : null,
                    onLongPress: () {
                      if (isSelectionMode) {
                        ref.read(noteSelectionProvider.notifier).toggle(note.id!);
                      } else if (MediaQuery.of(context).size.width < 600) {
                        ref.read(noteSelectionProvider.notifier).select(note.id!);
                      } else {
                        _showContextMenu(context, ref, null);
                      }
                    },
                    child: isMediaOnly(note)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContent(context, ref),
                              const SizedBox(height: 10),
                              _NoteFooter(note: note, channelId: channelId, ref: ref),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F0ED),
                              border: Border.all(color: borderColor, width: 1.0),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContent(context, ref),
                                const SizedBox(height: 14),
                                _NoteFooter(note: note, channelId: channelId, ref: ref),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            styleSheet: MarkdownStyleSheet.fromTheme(ThemeData()).copyWith(
              p: const TextStyle(fontSize: 16, color: Color(0xFF00171F)),
              a: const TextStyle(
                fontSize: 16,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
              h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00171F)),
              h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00171F)),
              h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00171F)),
              h4: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00171F)),
              h5: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00171F)),
              h6: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00171F)),
              code: const TextStyle(color: Color(0xFF00171F), backgroundColor: Color(0xFFDADDD8)),
              blockquote: const TextStyle(color: Color(0xFF00171F)),
            ),
          ),

        if (note.attachments != null && note.attachments!.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              ...note.attachments!.map(
                (attachment) {
                  final url = FileUtils.buildMediaUrl(serverUrl, attachment.filePath, attachment.contentHash);
                  final imageIndex = allImageUrls.indexOf(url);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MediaAttachmentWidget(
                      attachment: attachment,
                      serverUrl: serverUrl,
                      allImageUrls: allImageUrls,
                      initialImageIndex: imageIndex >= 0 ? imageIndex : 0,
                    ),
                  );
                },
              ),
            ],
          ),

        if (note.linkPreview != null)
          LinkPreviewCard(preview: note.linkPreview!),
      ],
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, Offset? globalPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final isArchive = channelId == -1;

    final Offset position = globalPosition ??
        Offset(overlay.size.width / 2, overlay.size.height / 2);

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
        if (!isArchive)
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
        if (channelId == -1) ...[
          PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.arrowCounterClockwise(), size: 18),
                const SizedBox(width: 12),
                const Text('Restore'),
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
          _copyToClipboard(context, note.content);
          break;
        case 'edit':
          ref.read(editingNoteProvider.notifier).startEditing(note.id!);
          break;
        case 'archive':
        case 'delete':
          ref.read(notesProvider(channelId).notifier).deleteNote(note.id!);
          break;
        case 'restore':
          _restoreNote(context, ref);
          break;
        case 'select':
          ref.read(noteSelectionProvider.notifier).select(note.id!);
          break;
      }
    });
  }

  void _copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    final cleanContent = content.replaceAll('  \n', ' ').replaceAll('\n', ' ');
    final preview = cleanContent.length > 20
        ? '${cleanContent.substring(0, 20)}...'
        : cleanContent;
    ToastUtils.show(context, 'Copied: $preview', type: ToastType.info);
  }

  Future<void> _restoreNote(BuildContext context, WidgetRef ref) async {
    try {
      await client.chat.restoreNote(note.id!);
      if (context.mounted) {
        ToastUtils.show(context, 'Note restored', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Failed to restore: $e', type: ToastType.error);
      }
    }
  }
}

class _NoteFooter extends StatelessWidget {
  const _NoteFooter({
    required this.note,
    required this.channelId,
    required this.ref,
  });

  final Note note;
  final int channelId;
  final WidgetRef ref;

  static String _formatDateTime(DateTime dt) {
    final localTime = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[localTime.month - 1];
    final day = localTime.day;
    final hour = localTime.hour > 12 ? localTime.hour - 12 : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isArchive = channelId == -1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDateTime(note.createdAt),
          style: TextStyle(fontSize: 12, color: const Color(0xFF00171F).withValues(alpha: 0.5)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isArchive) ...[
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => ref.read(editingNoteProvider.notifier).startEditing(note.id!),
                  child: PhosphorIcon(PhosphorIcons.pencilSimple(), size: 20, color: const Color(0xFF00171F).withValues(alpha: 0.5)),
                ),
              ),
              const SizedBox(width: 14),
            ],
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: note.content));
                  ToastUtils.show(context, 'Copied to clipboard', type: ToastType.success);
                },
                child: PhosphorIcon(PhosphorIcons.copySimple(), size: 20, color: const Color(0xFF00171F).withValues(alpha: 0.5)),
              ),
            ),
            const SizedBox(width: 14),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: isArchive
                    ? () async {
                        try {
                          await client.chat.restoreNote(note.id!);
                          if (context.mounted) {
                            ToastUtils.show(context, 'Note restored', type: ToastType.success);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ToastUtils.show(context, 'Failed to restore: $e', type: ToastType.error);
                          }
                        }
                      }
                    : () => ref.read(notesProvider(channelId).notifier).deleteNote(note.id!),
                child: PhosphorIcon(
                  isArchive ? PhosphorIcons.arrowCounterClockwise() : PhosphorIcons.archive(),
                  size: 20,
                  color: const Color(0xFF00171F).withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 14),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (note.content.isNotEmpty) Share.share(note.content);
                },
                child: PhosphorIcon(PhosphorIcons.shareNetwork(), size: 20, color: const Color(0xFF00171F).withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
