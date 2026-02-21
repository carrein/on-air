import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../providers/channels_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/pending_uploads_provider.dart';
import '../utils/icon_utils.dart';
import '../utils/toast_utils.dart';

/// Dialog shown when content is shared to Memoka from another app.
/// Lets the user pick a channel and send text/files.
class ShareIntentDialog extends ConsumerStatefulWidget {
  final List<SharedMediaFile> sharedFiles;

  const ShareIntentDialog({super.key, required this.sharedFiles});

  @override
  ConsumerState<ShareIntentDialog> createState() => _ShareIntentDialogState();
}

class _ShareIntentDialogState extends ConsumerState<ShareIntentDialog> {
  static const _accent = Color(0xFFCE2161);
  static const _bgDark = Color(0xFF00171F);

  int? _selectedChannelId;
  final _textController = TextEditingController();
  final bool _sending = false;
  bool _compress = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with shared text if it's a text-only share
    final textItems = widget.sharedFiles
        .where(
          (f) =>
              f.type == SharedMediaType.text || f.type == SharedMediaType.url,
        )
        .toList();
    if (textItems.isNotEmpty) {
      _textController.text = textItems.map((f) => f.path).join('\n');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool get _hasMediaFiles => widget.sharedFiles.any(
    (f) =>
        f.type == SharedMediaType.image ||
        f.type == SharedMediaType.video ||
        f.type == SharedMediaType.file,
  );

  List<SharedMediaFile> get _mediaFiles => widget.sharedFiles
      .where(
        (f) =>
            f.type == SharedMediaType.image ||
            f.type == SharedMediaType.video ||
            f.type == SharedMediaType.file,
      )
      .toList();

  Future<void> _send() async {
    if (_selectedChannelId == null) return;

    final channelId = _selectedChannelId!;
    final text = _textController.text.trim();

    if (_hasMediaFiles) {
      // Enqueue each media file for optimistic upload — uses file path
      // directly (no readAsBytes OOM risk).
      for (final file in _mediaFiles) {
        final fileName = file.path.split('/').last;
        ref
            .read(pendingUploadsProvider.notifier)
            .enqueue(
              channelId: channelId,
              filePath: file.path,
              fileName: fileName,
              noteContent: text.isNotEmpty && file == _mediaFiles.first
                  ? text
                  : '',
              compress: _compress,
            );
      }
    } else if (text.isNotEmpty) {
      // Text-only share
      await ref.read(notesProvider(channelId).notifier).createNote(text);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ToastUtils.show(context, 'Shared successfully', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Dialog(
      backgroundColor: const Color(0xFFF6F0ED),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Share to Memoka',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _bgDark,
                ),
              ),
              const SizedBox(height: 16),

              // Channel picker
              channelsAsync.when(
                data: (channels) {
                  _selectedChannelId ??= channels.firstOrNull?.id;
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedChannelId,
                    decoration: InputDecoration(
                      labelText: 'Channel',
                      labelStyle: GoogleFonts.spaceGrotesk(),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: channels
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  getChannelIcon(c.emoji),
                                  size: 18,
                                  color: const Color(0xFF00171F),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.name,
                                  style: GoogleFonts.spaceGrotesk(),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _sending
                        ? null
                        : (id) => setState(() => _selectedChannelId = id),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Failed to load channels: $e'),
              ),
              const SizedBox(height: 12),

              // Text input
              TextField(
                controller: _textController,
                enabled: !_sending,
                maxLines: 3,
                style: GoogleFonts.spaceGrotesk(),
                decoration: InputDecoration(
                  hintText: 'Add a note...',
                  hintStyle: GoogleFonts.spaceGrotesk(color: Colors.black38),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),

              // Media preview
              if (_hasMediaFiles) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mediaFiles.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final file = _mediaFiles[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: file.type == SharedMediaType.image
                            ? Image.file(
                                File(file.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PhosphorIcon(
                                      file.type == SharedMediaType.video
                                          ? PhosphorIcons.video()
                                          : PhosphorIcons.file(),
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      file.path.split('/').last,
                                      style: const TextStyle(fontSize: 8),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),
                ),
                // Compress toggle
                CheckboxListTile(
                  value: _compress,
                  onChanged: _sending
                      ? null
                      : (v) => setState(() => _compress = v ?? false),
                  title: Text(
                    'Compress files',
                    style: GoogleFonts.spaceGrotesk(fontSize: 14),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.spaceGrotesk(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sending || _selectedChannelId == null
                        ? null
                        : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Send',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
