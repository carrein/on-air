import 'dart:async' show unawaited;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../main.dart' show serverUrl;
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/pending_uploads_provider.dart';
import '../providers/scroll_to_note_provider.dart';
import '../providers/background_provider.dart';
import '../providers/connection_provider.dart' as conn;
import '../utils/file_utils.dart';
import '../models/upload_file_data.dart';
import 'archive_view.dart';
import 'file_upload_dialog.dart';
import 'note_item.dart';
import 'multi_file_upload_dialog.dart';
import 'pending_note_widget.dart';

// Cross-platform HTML imports
import 'package:universal_html/html.dart' as html;

/// Shared empty-state container used in the chat and archive views.
class _EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyStateBox({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0ED),
        border: Border.all(color: const Color(0xFFCE2161), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(icon, size: 48, color: const Color(0xFF00171F)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF00171F),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat view displaying notes in an inverted list (newest at bottom).
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _highlightedNoteId;
  bool _isDragOver = false;

  // Channel switch animation
  late final AnimationController _fadeController;
  int? _displayedChannelId;
  bool _isAnimating = false;
  bool _isAnimatingIn = true;
  int? _pendingChannelId; // queued target when an animation is already running

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
      value: 1.0,
    );
    if (kIsWeb) {
      _setupWebEventListeners();
    }
  }

  Future<void> _animateChannelSwitch(int newChannelId) async {
    // Direct tap (direction == 0): snap with no animation
    if (ref.read(channelSwitchDirectionProvider) == 0) {
      if (mounted) setState(() => _displayedChannelId = newChannelId);
      _fadeController.value = 1.0;
      return;
    }

    // If already animating, queue the latest target and let the loop pick it up.
    _pendingChannelId = newChannelId;
    if (_isAnimating) return;

    _isAnimating = true;
    while (_pendingChannelId != null) {
      final target = _pendingChannelId!;
      _pendingChannelId = null;

      if (!mounted) break;
      setState(() => _isAnimatingIn = false);
      await _fadeController.animateTo(0.0, curve: Curves.easeIn);
      if (!mounted) break;

      setState(() {
        _displayedChannelId = target;
        _isAnimatingIn = true;
      });

      await _fadeController.animateTo(1.0, curve: Curves.easeOut);
      if (!mounted) break;
    }
    _isAnimating = false;
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
    // Load more when the highest visible index is near the end of the list
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final maxIndex = positions
        .map((p) => p.index)
        .reduce((a, b) => a > b ? a : b);
    final channelId = _displayedChannelId;
    if (channelId == null || channelId == -1) return;

    final notes = ref.read(notesProvider(channelId)).value;
    if (notes == null) return;

    // In a reversed list, higher indices = older notes (top of screen).
    // Load more when within 10 items of the oldest loaded note.
    // Offset by pending count since pending items occupy the lowest indices.
    final pending = ref
        .read(pendingUploadsProvider)
        .where((p) => p.channelId == channelId)
        .toList();
    final noteIndex = maxIndex - pending.length;
    if (noteIndex >= notes.length - 10) {
      ref.read(notesProvider(channelId).notifier).loadMore();
    }
  }

  void _scrollToNote(int noteId) {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;
    final notes = ref.read(notesProvider(channelId)).value;
    if (notes == null) return;

    final pending = ref
        .read(pendingUploadsProvider)
        .where((p) => p.channelId == channelId)
        .toList();

    final index = notes.indexWhere((n) => n.id == noteId);
    if (index == -1) return;

    _itemScrollController.scrollTo(
      index: index + pending.length,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.0,
    );

    // Highlight the note briefly
    setState(() => _highlightedNoteId = noteId);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedNoteId = null);
    });
  }

  // Number of most-recent images to warm into the memory cache.
  // Covers a typical viewport without over-allocating memory.
  static const _kPrecacheImageCount = 20;

  void _precacheRecentImages(List<Note> notes) {
    var count = 0;
    for (final note in notes) {
      if (!mounted) return;
      for (final attachment in note.attachments ?? []) {
        if (!attachment.mimeType.toLowerCase().startsWith('image/')) continue;
        final url = FileUtils.buildMediaUrl(
          serverUrl,
          attachment.filePath,
          attachment.contentHash,
        );
        unawaited(precacheImage(CachedNetworkImageProvider(url), context));
        if (++count >= _kPrecacheImageCount) return;
      }
    }
  }

  Widget _buildDisplayedContent() {
    final channelId = _displayedChannelId;
    if (channelId == null) {
      final isDisconnected =
          ref.watch(conn.connectionProvider) ==
          conn.ConnectionState.disconnected;
      if (isDisconnected) {
        return const Center(
          child: _EmptyStateBox(
            icon: PhosphorIconsRegular.plugs,
            message: 'Server unreachable...',
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    if (channelId == -1) return const ArchiveView();

    final notesAsync = ref.watch(notesProvider(channelId));
    final pending = ref
        .watch(pendingUploadsProvider)
        .where((p) => p.channelId == channelId)
        .toList();

    return notesAsync.when(
      data: (allNotes) {
        // Filter out notes that already have an "uploaded" ghost note to
        // prevent duplicates during the brief overlap window.
        final uploadedNoteIds = pending
            .where(
              (p) =>
                  p.status == UploadStatus.uploaded && p.serverNoteId != null,
            )
            .map((p) => p.serverNoteId!)
            .toSet();
        final notes = uploadedNoteIds.isEmpty
            ? allNotes
            : allNotes.where((n) => !uploadedNoteIds.contains(n.id)).toList();

        if (notes.isEmpty && pending.isEmpty) {
          return const Center(
            child: _EmptyStateBox(
              icon: PhosphorIconsRegular.empty,
              message: 'It\'s quiet in here...',
            ),
          );
        }

        final allImageUrls = notes.reversed
            .expand(
              (n) => (n.attachments ?? [])
                  .where((a) => a.mimeType.toLowerCase().startsWith('image/'))
                  .map(
                    (a) => FileUtils.buildMediaUrl(
                      serverUrl,
                      a.filePath,
                      a.contentHash,
                    ),
                  ),
            )
            .toList();

        // Total items = pending ghost notes + real notes.
        // In the reversed list, index 0 is the bottom (newest).
        // Pending uploads occupy indices 0..<pending.length>,
        // real notes occupy indices pending.length..<totalItems>.
        final totalItems = notes.length + pending.length;

        return ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          physics: const ClampingScrollPhysics(),
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // Pending ghost notes at bottom (lowest indices in reversed list)
            if (index < pending.length) {
              return PendingNoteWidget(upload: pending[index]);
            }

            // Real notes
            final noteIndex = index - pending.length;
            final note = notes[noteIndex];
            final previousNote = noteIndex > 0 ? notes[noteIndex - 1] : null;
            final needsSeparator =
                previousNote != null &&
                !_isSameDay(note.createdAt, previousNote.createdAt);
            final isHighlighted = _highlightedNoteId == note.id;
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? const Color(0xFFCE2161).withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: NoteItem(
                    note: note,
                    channelId: channelId,
                    allImageUrls: allImageUrls,
                  ),
                ),
                if (needsSeparator) _buildDateSeparator(previousNote.createdAt),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(
        child: Text('Unable to load notes. Check your connection.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final currentBackground = ref.watch(backgroundPreferenceProvider);

    // Initialise displayed channel on first load
    if (_displayedChannelId == null &&
        currentChannelAsync.valueOrNull != null) {
      _displayedChannelId = currentChannelAsync.valueOrNull;
    }

    // Animate when the active channel changes
    ref.listen(currentChannelProvider, (prev, next) {
      next.whenData((newId) {
        if (newId != _displayedChannelId) _animateChannelSwitch(newId);
      });
    });

    // Precache the most recent images whenever notes load for the displayed channel
    final displayedChannelId = _displayedChannelId;
    if (displayedChannelId != null && displayedChannelId != -1) {
      ref.listen(notesProvider(displayedChannelId), (_, next) {
        next.whenData(_precacheRecentImages);
      });
    }

    // Listen for scroll-to-note requests from media panel
    ref.listen(scrollToNoteProvider, (prev, noteId) {
      if (noteId != null) {
        _scrollToNote(noteId);
        Future.microtask(
          () => ref.read(scrollToNoteProvider.notifier).state = null,
        );
      }
    });

    return Stack(
      children: [
        // Static background — never animates
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(currentBackground.assetPath),
                repeat: ImageRepeat.repeat,
                scale: 1.0,
              ),
            ),
          ),
        ),
        // Animated notes layer
        AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            final direction = ref.read(channelSwitchDirectionProvider);
            final t = _fadeController.value;
            final xOffset = _isAnimatingIn
                ? (1.0 - t) * direction * 40.0
                : (1.0 - t) * -direction * 40.0;
            return ClipRect(
              child: Transform.translate(
                offset: Offset(xOffset, 0),
                child: Opacity(opacity: t, child: child),
              ),
            );
          },
          child: _buildDisplayedContent(),
        ),
        // Drag-over indicator
        if (_isDragOver)
          Container(
            color: const Color(0xFF0F52BA).withValues(alpha: 0.2),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PhosphorIcon(
                    PhosphorIcons.uploadSimple(),
                    size: 64,
                    color: const Color(0xFF0F52BA),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Drop file here to upload',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F52BA),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
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
          color: const Color(0xFFCE2161),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          dateText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }

  Future<void> _handleWebPaste(html.ClipboardEvent event) async {
    if (!mounted) return;

    try {
      final clipboardData = event.clipboardData;
      if (clipboardData == null) return;

      final items = clipboardData.items;
      if (items == null) return;

      final length = items.length;
      if (length == null) return;

      // Collect all file-kind items — includes Finder-copied files which may
      // have an empty MIME type but are still valid file uploads.
      final List<html.File> fileItems = [];
      for (var i = 0; i < length; i++) {
        final item = items[i];
        if (item.kind == 'file') {
          final file = item.getAsFile();
          if (file != null) fileItems.add(file);
        }
      }

      // No files — let browser handle normally (e.g. text paste into input)
      if (fileItems.isEmpty) return;

      // Files found — prevent default so browser doesn't paste filename as text
      event.preventDefault();

      final uploadFiles = await _collectWebFiles(
        fileItems,
        generateFilenames: true,
      );
      await _showUploadDialogs(uploadFiles);
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

      final uploadFiles = await _collectWebFiles(List.from(files));
      await _showUploadDialogs(uploadFiles);
    } catch (e) {
      // Silently ignore drop errors
    }
  }

  /// Reads a list of [html.File] objects into [UploadFileData] instances.
  /// When [generateFilenames] is true, files with empty names (e.g. clipboard
  /// screenshots) get a generated name based on MIME type and timestamp.
  Future<List<UploadFileData>> _collectWebFiles(
    List<html.File> files, {
    bool generateFilenames = false,
  }) async {
    final List<UploadFileData> result = [];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;
      if (reader.result == null) continue;

      final raw = reader.result!;
      final Uint8List uint8List;
      if (raw is ByteBuffer) {
        uint8List = raw.asUint8List();
      } else {
        uint8List = raw as Uint8List;
      }

      final String fileName;
      final String extension;
      if (file.name.isNotEmpty) {
        fileName = file.name;
        final parts = file.name.split('.');
        extension = parts.length > 1 ? parts.last : '';
      } else if (generateFilenames) {
        final mimeType = file.type.isNotEmpty
            ? file.type
            : 'application/octet-stream';
        extension = mimeType.split('/').last;
        fileName =
            'pasted_file_${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
      } else {
        final parts = file.name.split('.');
        extension = parts.length > 1 ? parts.last : '';
        fileName = file.name;
      }

      result.add(
        UploadFileData(
          bytes: uint8List,
          fileName: fileName,
          extension: extension,
        ),
      );
    }
    return result;
  }

  /// Shows the appropriate upload dialog for the collected files.
  Future<void> _showUploadDialogs(List<UploadFileData> uploadFiles) async {
    if (uploadFiles.isEmpty) return;
    if (uploadFiles.length == 1) {
      await _showFileUploadDialog(uploadFiles.first);
    } else {
      await _showMultiFileUploadDialog(uploadFiles);
    }
  }

  Future<void> _showFileUploadDialog(UploadFileData file) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    await showDialog(
      context: context,
      builder: (_) => FileUploadDialog(
        file: file,
        onSend: (compress) {
          // Enqueue optimistic upload — fire-and-forget
          ref
              .read(pendingUploadsProvider.notifier)
              .enqueue(
                channelId: channelId,
                filePath: file.filePath,
                fileBytes: file.bytes,
                fileName: file.fileName,
                noteContent: '',
                compress: compress,
              );
        },
      ),
    );
  }

  Future<void> _showMultiFileUploadDialog(
    List<UploadFileData> uploadFiles,
  ) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;

    await showDialog(
      context: context,
      builder: (_) => MultiFileUploadDialog(
        files: uploadFiles,
        onSend: (files) {
          for (final file in files) {
            ref
                .read(pendingUploadsProvider.notifier)
                .enqueue(
                  channelId: channelId,
                  filePath: file.filePath,
                  fileBytes: file.bytes,
                  fileName: file.fileName,
                  noteContent: '',
                  compress: file.compress,
                );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _fadeController.dispose();
    super.dispose();
  }
}
