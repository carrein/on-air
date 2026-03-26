import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart' show serverUrl, client;
import '../utils/download_utils.dart';
import '../providers/notes_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/page_watch_provider.dart';
import '../providers/channel_page_watches_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/channel_reminders_provider.dart';
import '../utils/reminder_picker.dart';
import '../utils/url_utils.dart';
import '../utils/image_clipboard.dart';
import '../utils/toast_utils.dart';
import '../utils/file_utils.dart';
import '../utils/responsive_utils.dart';

import 'link_preview_card.dart';
import 'media_attachment_widget.dart';
import 'pending_note_widget.dart' show kFooterHeight, NoteConstraints;

/// Returns true when a note should render without card chrome —
/// i.e. empty text, no link preview, and all attachments are image/video.
bool isMediaOnlyNote(Note note) {
  if (note.content.trim().isNotEmpty) return false;
  if (note.linkPreview != null) return false;
  final atts = note.attachments;
  if (atts == null || atts.isEmpty) return false;
  return atts.every((a) {
    final mime = a.mimeType.toLowerCase();
    return mime.startsWith('image/') || mime.startsWith('video/');
  });
}

/// Individual note card with content, footer actions, and context menu.
class NoteItem extends ConsumerWidget {
  const NoteItem({
    super.key,
    required this.note,
    required this.channelId,
    this.allImageUrls = const [],
    this.isHighlighted = false,
  });

  final Note note;
  final int channelId;
  final List<String> allImageUrls;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(noteSelectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final isSelected = selection.contains(note.id);
    final mediaOnly = isMediaOnlyNote(note);

    const borderColor = Color(0xFF3450A3);

    final noteRow = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated checkbox area — slides in/out on selection mode change
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
            width: isSelectionMode ? 32 : 0,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: PhosphorIcon(
                isSelected
                    ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
                    : PhosphorIcons.circle(),
                size: 24,
                color: const Color(0xFF3450A3),
              ),
            ),
          ),
          // Note content
          Flexible(
            child: mediaOnly
                ? _buildMediaOnlyNote(context, ref)
                : _buildCardNote(context, ref, borderColor),
          ),
        ],
      ),
    );

    // Stack children order must be stable so AnimatedContainer keeps its state.
    // The highlight Positioned is always present (transparent when inactive)
    // to prevent index shifts that would recreate the AbsorbPointer subtree.
    return SizedBox(
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -14,
            right: -14,
            top: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              color: isSelectionMode && isSelected
                  ? const Color(0xFF3450A3).withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
          ),
          AbsorbPointer(
            absorbing: isSelectionMode,
            child: noteRow,
          ),
          if (isSelectionMode)
            Positioned(
              left: -14,
              right: -14,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () =>
                    ref.read(noteSelectionProvider.notifier).toggle(note.id!),
                onLongPress: () =>
                    ref.read(noteSelectionProvider.notifier).toggle(note.id!),
              ),
            ),
        ],
      ),
    );
  }

  /// Standard card rendering (cream bg, blue border, footer).
  Widget _buildCardNote(
    BuildContext context,
    WidgetRef ref,
    Color borderColor,
  ) {
    return _wrapConstraints(
      hasTable: note.content.contains(RegExp(r'^\|', multiLine: true)),
      child: Listener(
        onPointerDown: (event) {
          if (event.buttons == 2) {
            _showContextMenu(context, ref, event.position);
          }
        },
        child: GestureDetector(
          onLongPress: () {
            if (ResponsiveUtils.isMobile(context)) {
              HapticFeedback.mediumImpact();
              ref.read(noteSelectionProvider.notifier).select(note.id!);
            } else {
              _showContextMenu(context, ref, null);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF6),
              border: Border.all(
                color: borderColor,
                width: isHighlighted ? 2.0 : 1.0,
              ),
            ),
            padding: EdgeInsets.all(isHighlighted ? 11 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContent(context, ref),
                const SizedBox(height: 6),
                _NoteFooter(
                  note: note,
                  channelId: channelId,
                  onEdit: () => ref
                      .read(editingNoteProvider.notifier)
                      .startEditing(note.id!),
                  onArchive: () => ref
                      .read(notesProvider(channelId).notifier)
                      .deleteNote(note.id!),
                  onRestore: () => _restoreNote(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Media-only rendering: no card chrome, timestamp pill overlay.
  Widget _buildMediaOnlyNote(
    BuildContext context,
    WidgetRef ref,
  ) {
    final attachments = note.attachments!;

    // Build media widgets
    final mediaWidgets = <Widget>[];
    for (var i = 0; i < attachments.length; i++) {
      if (i > 0) mediaWidgets.add(const SizedBox(height: 4));
      final attachment = attachments[i];
      final url = FileUtils.buildMediaUrl(
        serverUrl,
        attachment.filePath,
        attachment.contentHash,
      );
      final imageIndex = allImageUrls.indexOf(url);
      mediaWidgets.add(
        MediaAttachmentWidget(
          attachment: attachment,
          serverUrl: serverUrl,
          allImageUrls: allImageUrls,
          initialImageIndex: imageIndex >= 0 ? imageIndex : 0,
          isMediaNote: true,
        ),
      );
    }

    Widget content = Container(
      decoration: isHighlighted
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFF3450A3), width: 2.0),
            )
          : null,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: mediaWidgets,
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: _TimestampPill(dateTime: note.createdAt),
          ),
        ],
      ),
    );

    return Listener(
      onPointerDown: (event) {
        if (event.buttons == 2) {
          _showContextMenu(context, ref, event.position);
        }
      },
      child: GestureDetector(
        onLongPress: () {
          if (ResponsiveUtils.isMobile(context)) {
            HapticFeedback.mediumImpact();
            ref.read(noteSelectionProvider.notifier).select(note.id!);
          } else {
            _showContextMenu(context, ref, null);
          }
        },
        child: content,
      ),
    );
  }

  Widget _wrapConstraints({required bool hasTable, required Widget child}) {
    if (hasTable) return child;
    return NoteConstraints(child: child);
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final parts = <Widget>[];
    int checkboxIndex = 0;

    if (note.content.isNotEmpty) {
      // Convert HTML break tags to markdown line breaks (two trailing spaces).
      final content = note.content.replaceAll(RegExp(r'<br\s*/?>'), '  \n');
      parts.add(
        MarkdownBody(
          data: content,
          selectable: kIsWeb,
          listItemCrossAxisAlignment: MarkdownListItemCrossAxisAlignment.start,
          onTapLink: (text, href, title) async {
            if (href != null) {
              final uri = Uri.tryParse(href);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          inlineSyntaxes: [md.EmojiSyntax()],
          builders: {
            'pre': _CodeBlockBuilder(),
            'blockquote': _BlockquoteBuilder(),
          },
          paddingBuilders: {
            'code': _CodePaddingBuilder(),
          },
          checkboxBuilder: (checked) {
            final idx = checkboxIndex++;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _toggleCheckbox(ref, idx),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, top: 4),
                  child: PhosphorIcon(
                    checked
                        ? PhosphorIcons.checkSquare(PhosphorIconsStyle.fill)
                        : PhosphorIcons.square(),
                    size: 16,
                    color: const Color(0xFF3450A3),
                  ),
                ),
              ),
            );
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(fontSize: 16, color: Color(0xFF00171F)),
            a: const TextStyle(
              fontSize: 16,
              color: Color(0xFF0F52BA),
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dashed,
              decorationColor: Color(0xFF0F52BA),
            ),
            h1: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
            h2: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
            h3: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
            h4: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
            h5: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
            h6: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
            code: TextStyle(
              color: const Color(0xFFFFFDF6),
              backgroundColor: const Color(0xFF00171F),
              fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
              fontSize: 14,
            ),
            codeblockDecoration: const BoxDecoration(),
            blockquoteDecoration: const BoxDecoration(),
            blockquotePadding: EdgeInsets.zero,
            listIndent: 16,
            horizontalRuleDecoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFF00171F),
                  width: 2,
                ),
              ),
            ),
            superscriptFontFeatureTag: 'numr',
          ),
        ),
      );
    }

    if (note.attachments != null && note.attachments!.isNotEmpty) {
      final attachments = note.attachments!;
      for (var i = 0; i < attachments.length; i++) {
        if (parts.isNotEmpty || i > 0) parts.add(const SizedBox(height: 12));
        final attachment = attachments[i];
        final url = FileUtils.buildMediaUrl(
          serverUrl,
          attachment.filePath,
          attachment.contentHash,
        );
        final imageIndex = allImageUrls.indexOf(url);
        parts.add(
          MediaAttachmentWidget(
            attachment: attachment,
            serverUrl: serverUrl,
            allImageUrls: allImageUrls,
            initialImageIndex: imageIndex >= 0 ? imageIndex : 0,
          ),
        );
      }
    }

    if (note.linkPreview != null) {
      if (parts.isNotEmpty) parts.add(const SizedBox(height: 4));
      parts.add(LinkPreviewCard(preview: note.linkPreview!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts,
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset? globalPosition,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final isArchive = channelId == -1;
    final isMediaOnly = !isArchive && isMediaOnlyNote(note);
    final hasReminder =
        ref
            .read(channelRemindersProvider(channelId))
            .value
            ?.any((r) => r.noteId == note.id) ??
        false;

    final Offset position =
        globalPosition ??
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
        if (isMediaOnly)
          PopupMenuItem(
            value: 'save',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.downloadSimple(), size: 18),
                const SizedBox(width: 12),
                const Text('Save'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              PhosphorIcon(PhosphorIcons.copySimple(), size: 18),
              const SizedBox(width: 12),
              const Text('Copy'),
            ],
          ),
        ),
        if (!isMediaOnly &&
            kIsWeb &&
            (note.attachments?.any(
                  (a) => a.mimeType.toLowerCase().startsWith('image/'),
                ) ??
                false))
          PopupMenuItem(
            value: 'copy_image',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.image(), size: 18),
                const SizedBox(width: 12),
                const Text('Copy Image'),
              ],
            ),
          ),
        if (!isMediaOnly && !isArchive)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.pencilSimple(), size: 18),
                const SizedBox(width: 12),
                const Text('Edit'),
              ],
            ),
          ),
        if (isArchive) ...[
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
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.trash(), size: 18),
                const SizedBox(width: 12),
                const Text('Delete'),
              ],
            ),
          ),
        ] else
          PopupMenuItem(
            value: 'archive',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.archive(), size: 18),
                const SizedBox(width: 12),
                const Text('Archive'),
              ],
            ),
          ),
        if (!isArchive)
          PopupMenuItem(
            value: hasReminder ? 'remove_reminder' : 'reminder',
            child: Row(
              children: [
                PhosphorIcon(PhosphorIcons.siren(), size: 18),
                const SizedBox(width: 12),
                Text(hasReminder ? 'Remove Reminder' : 'Set Reminder'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'select',
          child: Row(
            children: [
              PhosphorIcon(PhosphorIcons.checkCircle(), size: 18),
              const SizedBox(width: 12),
              const Text('Select'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (!context.mounted) return;
      switch (value) {
        case 'save':
          _saveMedia(context);
          break;
        case 'copy':
          if (isMediaOnly) {
            _copyMedia(context);
          } else {
            _copyToClipboard(context, note.content);
          }
          break;
        case 'copy_image':
          _copyImageToClipboard(context).ignore();
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
        case 'reminder':
          _setReminder(context, ref);
          break;
        case 'remove_reminder':
          _removeReminder(context, ref);
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

  Future<void> _copyImageToClipboard(BuildContext context) async {
    MediaAttachment? imageAttachment;
    for (final a in note.attachments ?? []) {
      if (a.mimeType.toLowerCase().startsWith('image/')) {
        imageAttachment = a;
        break;
      }
    }
    if (imageAttachment == null) return;
    final url = FileUtils.buildMediaUrl(
      serverUrl,
      imageAttachment.filePath,
      imageAttachment.contentHash,
    );
    final success = await copyImageToClipboard(url);
    if (!context.mounted) return;
    if (success) {
      ToastUtils.show(
        context,
        'Image copied to clipboard',
        type: ToastType.success,
      );
    } else {
      ToastUtils.show(context, 'Failed to copy image', type: ToastType.error);
    }
  }

  void _setReminder(BuildContext context, WidgetRef ref) async {
    if (note.id == null) return;
    final result = await showReminderPicker(context);
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(reminderProvider(note.id!).notifier)
          .createReminder(
            result.scheduledAt,
            recurrenceRule: result.recurrenceRule,
            recurrenceEndAt: result.recurrenceEndAt,
          );
      ref.invalidate(channelRemindersProvider(channelId));
      if (context.mounted) {
        ToastUtils.show(context, 'Reminder set', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Failed: $e', type: ToastType.error);
      }
    }
  }

  void _saveMedia(BuildContext context) async {
    final attachments = note.attachments;
    if (attachments == null || attachments.isEmpty) return;
    final attachment = attachments.first;
    final url = FileUtils.buildMediaUrl(
      serverUrl,
      attachment.filePath,
      attachment.contentHash,
    );
    if (kIsWeb) {
      try {
        final request = await html.HttpRequest.request(
          url,
          responseType: 'blob',
        );
        final blob = request.response as html.Blob;
        final objectUrl = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement()
          ..href = objectUrl
          ..setAttribute('download', attachment.originalFilename)
          ..click();
        html.Url.revokeObjectUrl(objectUrl);
      } catch (e) {
        if (context.mounted) {
          ToastUtils.show(context, 'Download failed', type: ToastType.error);
        }
      }
    } else {
      ToastUtils.show(context, 'Downloading...', type: ToastType.info);
      DownloadUtils.downloadToDevice(
        context,
        url,
        attachment.originalFilename,
        mimeType: attachment.mimeType,
      );
    }
  }

  void _copyMedia(BuildContext context) {
    final attachments = note.attachments;
    if (attachments == null || attachments.isEmpty) return;
    final attachment = attachments.first;
    if (kIsWeb && attachment.mimeType.toLowerCase().startsWith('image/')) {
      _copyImageToClipboard(context).ignore();
    } else {
      final url = FileUtils.buildMediaUrl(
        serverUrl,
        attachment.filePath,
        attachment.contentHash,
      );
      Clipboard.setData(ClipboardData(text: url));
      if (context.mounted) {
        ToastUtils.show(context, 'URL copied', type: ToastType.info);
      }
    }
  }

  void _removeReminder(BuildContext context, WidgetRef ref) async {
    if (note.id == null) return;
    try {
      await ref.read(reminderProvider(note.id!).notifier).deleteReminder();
      ref.invalidate(channelRemindersProvider(channelId));
      if (context.mounted) {
        ToastUtils.show(
          context,
          'Reminder removed',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Failed: $e', type: ToastType.error);
      }
    }
  }

  void _toggleCheckbox(WidgetRef ref, int index) {
    if (note.id == null) return;
    int count = 0;
    final regex = RegExp(r'- \[([ xX])\]');
    final newContent = note.content.replaceAllMapped(regex, (match) {
      if (count++ == index) {
        final isChecked = match.group(1) != ' ';
        return isChecked ? '- [ ]' : '- [x]';
      }
      return match.group(0)!;
    });
    if (newContent != note.content) {
      ref
          .read(notesProvider(channelId).notifier)
          .updateNote(note.id!, newContent);
    }
  }

  Future<void> _restoreNote(BuildContext context, WidgetRef ref) async {
    try {
      await client.chat.restoreNote(note.id!);
      if (context.mounted) {
        ToastUtils.show(context, 'Note restored', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(
          context,
          'Failed to restore: $e',
          type: ToastType.error,
        );
      }
    }
  }
}

/// Semi-transparent timestamp pill for media-only notes.
class _TimestampPill extends StatelessWidget {
  const _TimestampPill({required this.dateTime});

  final DateTime dateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        FileUtils.formatDateTime(dateTime),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _NoteFooter extends ConsumerWidget {
  const _NoteFooter({
    required this.note,
    required this.channelId,
    this.onEdit,
    this.onArchive,
    this.onRestore,
  });

  final Note note;
  final int channelId;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onRestore;

  static const _iconColor = Color(0xFF00171F);
  static const _iconAlpha = 0.6;

  bool get _isDocumentOnly {
    final atts = note.attachments;
    if (atts == null || atts.isEmpty) return false;
    return !atts.any((a) {
      final mime = a.mimeType.toLowerCase();
      return mime.startsWith('image/') ||
          mime.startsWith('video/') ||
          mime.startsWith('audio/');
    });
  }

  bool get _hasCopyableContent {
    if (note.content.isNotEmpty) return true;
    if (kIsWeb) {
      return (note.attachments ?? []).any(
        (a) => a.mimeType.toLowerCase().startsWith('image/'),
      );
    }
    return false;
  }

  bool get _canShare {
    if (note.content.isNotEmpty) return true;
    if (kIsWeb) return false;
    final atts = note.attachments;
    return atts != null && atts.isNotEmpty;
  }

  Future<void> _onShareTap(BuildContext context) async {
    if (note.content.isNotEmpty) {
      Share.share(note.content);
      return;
    }

    final atts = note.attachments;
    if (atts == null || atts.isEmpty || kIsWeb) return;

    final xFiles = <XFile>[];
    for (final a in atts) {
      final url = FileUtils.buildMediaUrl(serverUrl, a.filePath, a.contentHash);
      final filename = a.originalFilename;
      final completer = Completer<String?>();
      DownloadUtils.downloadToCache(
        url,
        filename,
        onSuccess: (path) => completer.complete(path),
        onError: (e) => completer.complete(null),
      );
      final path = await completer.future;
      if (path != null) {
        xFiles.add(XFile(path, mimeType: a.mimeType));
      }
    }

    if (xFiles.isNotEmpty) {
      Share.shareXFiles(xFiles);
    }
  }

  Future<void> _onCopyTap(BuildContext context) async {
    // Prefer media: try to copy the first image attachment to clipboard.
    for (final a in note.attachments ?? []) {
      if (a.mimeType.toLowerCase().startsWith('image/')) {
        final url = FileUtils.buildMediaUrl(
          serverUrl,
          a.filePath,
          a.contentHash,
        );
        final success = await copyImageToClipboard(url);
        if (!context.mounted) return;
        if (success) {
          ToastUtils.show(
            context,
            'Image copied to clipboard',
            type: ToastType.success,
          );
          return;
        }
        break; // image copy unsupported on this platform, fall through
      }
    }
    // Fallback: copy text content.
    if (note.content.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: note.content));
      if (context.mounted) {
        ToastUtils.show(
          context,
          'Copied to clipboard',
          type: ToastType.success,
        );
      }
    }
  }

  /// Whether the note contains exactly one URL (eligible for page watch).
  bool get _hasSingleUrl {
    if (note.content.isEmpty) return false;
    final urls = urlPattern.allMatches(note.content).toList();
    return urls.length == 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchive = channelId == -1;
    final color = _iconColor.withValues(alpha: _iconAlpha);
    return SizedBox(
      height: kFooterHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              FileUtils.formatDateTime(note.createdAt),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isArchive && note.id != null) ...[
                _ReminderSiren(
                  noteId: note.id!,
                  channelId: channelId,
                  color: color,
                ),
              ],
              if (!isArchive && _hasSingleUrl && note.id != null) ...[
                _PageWatchBell(
                  noteId: note.id!,
                  channelId: channelId,
                  color: color,
                ),
                const SizedBox(width: 14),
              ],
              if (!isArchive && !_isDocumentOnly) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Icon(
                      PhosphorIcons.pencilSimple(),
                      size: 20,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              if (_hasCopyableContent) ...[
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _onCopyTap(context),
                    child: Icon(
                      PhosphorIcons.copySimple(),
                      size: 20,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
              ],
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: isArchive ? onRestore : onArchive,
                  child: Icon(
                    isArchive
                        ? PhosphorIcons.arrowCounterClockwise()
                        : PhosphorIcons.archive(),
                    size: 20,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              MouseRegion(
                cursor: _canShare
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: _canShare ? () => _onShareTap(context) : null,
                  child: Icon(
                    PhosphorIcons.shareNetwork(),
                    size: 20,
                    color: _canShare ? color : color.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bell icon for toggling page watch on a single-URL note.
/// Uses the batch channelPageWatchesProvider (1 RPC per channel) instead of
/// per-note pageWatchProvider to avoid N fetches while scrolling.
/// States: outline (not watching), filled (watching), filled+pink dot (change),
/// red (error/disabled after failures).
class _PageWatchBell extends ConsumerWidget {
  const _PageWatchBell({
    required this.noteId,
    required this.channelId,
    required this.color,
  });

  final int noteId;
  final int channelId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchesAsync = ref.watch(channelPageWatchesProvider(channelId));

    return watchesAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => Icon(
        PhosphorIcons.bell(),
        size: 20,
        color: color.withValues(alpha: 0.3),
      ),
      error: (_, _) => Icon(
        PhosphorIcons.bell(),
        size: 20,
        color: color,
      ),
      data: (watches) {
        final watch = watches.where((w) => w.noteId == noteId).firstOrNull;
        final isWatching = watch != null && watch.enabled;
        final hasChange = watch?.hasUnacknowledgedChange ?? false;
        final hasError =
            watch != null && !watch.enabled && watch.consecutiveFailures >= 5;

        // Pick icon and color
        final IconData icon;
        final Color bellColor;
        if (hasError) {
          icon = PhosphorIcons.bellRinging(PhosphorIconsStyle.fill);
          bellColor = const Color(0xFFD32F2F); // red
        } else if (isWatching) {
          icon = PhosphorIcons.bell(PhosphorIconsStyle.fill);
          bellColor = color;
        } else {
          icon = PhosphorIcons.bell();
          bellColor = color;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _onTap(context, ref, watch),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: bellColor),
                if (hasChange)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3450A3), // pink
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    PageWatch? watch,
  ) async {
    final notifier = ref.read(pageWatchProvider(noteId).notifier);

    // If there's an unacknowledged change, acknowledge it
    if (watch != null && watch.hasUnacknowledgedChange) {
      try {
        await notifier.acknowledgeChange();
        ref.invalidate(channelPageWatchesProvider(channelId));
      } catch (e) {
        if (context.mounted) {
          ToastUtils.show(
            context,
            'Failed: $e',
            type: ToastType.error,
          );
        }
      }
      return;
    }

    try {
      final nowWatching = await notifier.toggleWatch();
      ref.invalidate(channelPageWatchesProvider(channelId));
      if (context.mounted) {
        ToastUtils.show(
          context,
          nowWatching ? 'Watching page for changes' : 'Stopped watching page',
          type: ToastType.info,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(
          context,
          'Failed: $e',
          type: ToastType.error,
        );
      }
    }
  }
}

/// Siren icon that appears when a note has an active (unfired) reminder.
/// Uses the batch channelRemindersProvider (1 RPC per channel) instead of
/// per-note reminderProvider to avoid N fetches while scrolling.
class _ReminderSiren extends ConsumerWidget {
  const _ReminderSiren({
    required this.noteId,
    required this.channelId,
    required this.color,
  });

  final int noteId;
  final int channelId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(channelRemindersProvider(channelId));

    return remindersAsync.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (reminders) {
        final hasReminder = reminders.any((r) => r.noteId == noteId);
        if (!hasReminder) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: PhosphorIcon(
            PhosphorIcons.siren(PhosphorIconsStyle.fill),
            size: 14,
            color: const Color(0xFF3450A3),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Custom renderers
// ---------------------------------------------------------------------------

class _BlockquoteBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final children = <Widget>[];
    _buildChildren(element, children);
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Color(0xFF3450A3), width: 3)),
      ),
      padding: const EdgeInsets.only(left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  void _buildChildren(md.Element element, List<Widget> widgets) {
    for (final child in element.children ?? []) {
      if (child is md.Element && child.tag == 'blockquote') {
        final nested = <Widget>[];
        _buildChildren(child, nested);
        widgets.add(
          Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF3450A3), width: 3),
              ),
            ),
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: nested,
            ),
          ),
        );
      } else {
        final text = child.textContent.trim();
        if (text.isNotEmpty) {
          widgets.add(
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF3450A3),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          );
        }
      }
    }
  }
}

class _CodePaddingBuilder extends MarkdownPaddingBuilder {
  @override
  EdgeInsets getPadding() => const EdgeInsets.symmetric(horizontal: 2);
}

class _CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    return const SizedBox.shrink();
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    String language = '';
    String code = '';
    if (element.children != null) {
      for (final child in element.children!) {
        if (child is md.Element && child.tag == 'code') {
          final cls = child.attributes['class'] ?? '';
          if (cls.startsWith('language-')) language = cls.substring(9);
          code = child.textContent;
          break;
        }
      }
    }
    return _CodeBlock(language: language, code: code);
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.language, required this.code});

  final String language;
  final String code;

  static const _bg = Color(0xFF00171F);
  static const _fg = Color(0xFFFFFDF6);

  @override
  Widget build(BuildContext context) {
    final displayCode = code.trimRight();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          decoration: BoxDecoration(
            color: _bg,
            border: Border(
              bottom: BorderSide(
                color: _fg.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              RichText(
                text: TextSpan(
                  text: language.isEmpty ? 'text' : language,
                  style: GoogleFonts.spaceGrotesk(
                    color: _fg.withValues(alpha: 0.55),
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: displayCode));
                    ToastUtils.show(context, 'Copied', type: ToastType.info);
                  },
                  child: PhosphorIcon(
                    PhosphorIcons.copySimple(),
                    size: 15,
                    color: _fg.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Code body
        Container(
          color: _bg,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          child: Text(
            displayCode,
            style: GoogleFonts.spaceGrotesk(
              color: _fg,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
