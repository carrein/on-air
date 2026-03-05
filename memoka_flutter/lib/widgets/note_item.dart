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
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../main.dart' show serverUrl, client;
import '../utils/download_utils.dart';
import '../providers/notes_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/note_selection_provider.dart';
import '../utils/image_clipboard.dart';
import '../utils/toast_utils.dart';
import '../utils/file_utils.dart';
import '../utils/responsive_utils.dart';

import 'link_preview_card.dart';
import 'media_attachment_widget.dart';
import 'pending_note_widget.dart' show kFooterHeight, NoteConstraints;

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

    const borderColor = Color(0xFFCE2161);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection checkbox (visible in selection mode)
          if (isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(noteSelectionProvider.notifier).toggle(note.id!),
                child: isSelected
                    ? PhosphorIcon(
                        PhosphorIcons.checkCircle(),
                        size: 24,
                        color: const Color(0xFFCE2161),
                      )
                    : PhosphorIcon(
                        PhosphorIcons.circle(),
                        size: 24,
                        color: const Color(0xFFCE2161),
                      ),
              ),
            ),
          // Note content — skip max-width constraint when note has a table
          Flexible(
            child: _wrapConstraints(
              hasTable: note.content.contains(RegExp(r'^\|', multiLine: true)),
              child: Listener(
                onPointerDown: (event) {
                  if (event.buttons == 2) {
                    _showContextMenu(context, ref, event.position);
                  }
                },
                child: GestureDetector(
                  onTap: isSelectionMode
                      ? () => ref
                            .read(noteSelectionProvider.notifier)
                            .toggle(note.id!)
                      : null,
                  onLongPress: () {
                    if (isSelectionMode) {
                      ref.read(noteSelectionProvider.notifier).toggle(note.id!);
                    } else if (ResponsiveUtils.isMobile(context)) {
                      ref.read(noteSelectionProvider.notifier).select(note.id!);
                    } else {
                      _showContextMenu(context, ref, null);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F0ED),
                      border: Border.all(
                        color: borderColor,
                        width: isHighlighted ? 2.0 : 1.0,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isHighlighted ? 11 : 12,
                      vertical: isHighlighted ? 9 : 10,
                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapConstraints({required bool hasTable, required Widget child}) {
    if (hasTable) return child;
    return NoteConstraints(child: child);
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final parts = <Widget>[];

    if (note.content.isNotEmpty) {
      // Convert HTML break tags to markdown line breaks (two trailing spaces).
      final content = note.content.replaceAll(RegExp(r'<br\s*/?>'), '  \n');
      parts.add(
        MarkdownBody(
          data: content,
          selectable: kIsWeb,
          onTapLink: (text, href, title) async {
            if (href != null) {
              final uri = Uri.tryParse(href);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          },
          builders: {'pre': _CodeBlockBuilder()},
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            p: const TextStyle(fontSize: 16, color: Color(0xFF00171F)),
            a: const TextStyle(
              fontSize: 16,
              color: Color(0xFF0F52BA),
              decoration: TextDecoration.none,
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
            code: const TextStyle(
              color: Color(0xFFF6F0ED),
              backgroundColor: Color(0xFF00171F),
            ),
            codeblockDecoration: const BoxDecoration(),
            blockquote: const TextStyle(color: Color(0xFF00171F)),
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
      if (parts.isNotEmpty) parts.add(const SizedBox(height: 12));
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
        if (kIsWeb &&
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
        if (!isArchive)
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
        case 'copy':
          _copyToClipboard(context, note.content);
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

class _NoteFooter extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
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

// ---------------------------------------------------------------------------
// Code-block custom renderer
// ---------------------------------------------------------------------------

class _CodeBlockBuilder extends MarkdownElementBuilder {
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
  static const _fg = Color(0xFFF6F0ED);

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
