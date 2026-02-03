import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:on_air_client/on_air_client.dart';
import '../providers/channels_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/notes_provider.dart';
import '../utils/toast_utils.dart';

/// Sidebar displaying channels list and add channel button.
/// Draggable on web with two positions: emoji-only (60px) or full (250px).
/// Always emoji-only on mobile.
class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  static const double _collapsedWidth = 70.0;
  static const double _expandedWidth = 250.0;
  double _currentWidth = _expandedWidth;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Force collapsed on mobile
    if (!kIsWeb) {
      _currentWidth = _collapsedWidth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCollapsed = _currentWidth < 150;
    final channelsAsync = ref.watch(channelsProvider);
    final currentChannelAsync = ref.watch(currentChannelProvider);

    return Row(
      children: [
        Container(
          width: _currentWidth,
          decoration: BoxDecoration(
            color: Colors.grey[200],
          ),
          child: Column(
            children: [
              // Channels list
              Expanded(
                child: channelsAsync.when(
                  data: (channels) => ListView.separated(
                    itemCount: channels.length,
                    separatorBuilder: (context, index) {
                      // Add divider between pinned and unpinned channels
                      final currentChannel = channels[index];
                      final nextChannel = index + 1 < channels.length ? channels[index + 1] : null;

                      if (currentChannel.pinned && nextChannel != null && !nextChannel.pinned) {
                        return Column(
                          children: [
                            const SizedBox(height: 4),
                            Divider(height: 1, color: Colors.grey[400]),
                            const SizedBox(height: 4),
                          ],
                        );
                      }
                      return const SizedBox(height: 4);
                    },
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      final isSelected = currentChannelAsync.value == channel.id;

                      return _buildChannelItem(
                        channel,
                        isSelected,
                        isCollapsed,
                        context,
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                ),
              ),
              // Add channel button
              const SizedBox(height: 8),
              _buildAddButton(isCollapsed, context),
            ],
          ),
        ),
        // Draggable divider (web only)
        if (kIsWeb)
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              onHorizontalDragStart: (_) => setState(() => _isDragging = true),
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _currentWidth += details.delta.dx;
                  _currentWidth = _currentWidth.clamp(_collapsedWidth, _expandedWidth);
                });
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _isDragging = false;
                  // Snap to nearest position
                  if (_currentWidth < 150) {
                    _currentWidth = _collapsedWidth;
                  } else {
                    _currentWidth = _expandedWidth;
                  }
                });
              },
              child: Container(
                width: 8,
                color: _isDragging ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChannelItem(
    Channel channel,
    bool isSelected,
    bool isCollapsed,
    BuildContext context,
  ) {
    // Get latest note for preview
    final notesAsync = ref.watch(notesProvider(channel.id!));
    final latestNote = notesAsync.value?.isNotEmpty == true ? notesAsync.value!.first : null;

    return Material(
      color: isSelected ? Colors.blue[100] : Colors.transparent,
      child: InkWell(
        onTap: () => _switchChannel(ref, channel.id!),
        onSecondaryTapDown: (details) => _showContextMenu(context, channel, details.globalPosition),
        onLongPress: () => _showContextMenu(context, channel, null),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              // Emoji avatar (no pin icon overlay)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    channel.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              // Channel name and message preview (only when expanded)
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (latestNote != null && _shouldShowPreview(latestNote))
                        Text(
                          _getPreviewText(latestNote),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                // Pin icon at the end
                if (channel.pinned)
                  Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Colors.blue[700],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(bool isCollapsed, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreateChannelDialog(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(Icons.add, size: isCollapsed ? 24 : 20),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('New Channel', overflow: TextOverflow.ellipsis),
                      SizedBox(height: 16), // Match height of preview text
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowPreview(Note note) {
    if (note.content.isNotEmpty) return true;
    if (note.attachments != null && note.attachments!.isNotEmpty) return true;
    if (note.linkPreview != null) return true;
    return false;
  }

  String _getPreviewText(Note note) {
    if (note.content.isNotEmpty) {
      return note.content.replaceAll(RegExp(r'\s+'), ' ');
    }
    if (note.attachments != null && note.attachments!.isNotEmpty) {
      final count = note.attachments!.length;
      if (count == 1) {
        final attachment = note.attachments!.first;
        final type = attachment.mimeType.startsWith('image/')
            ? 'Image'
            : (attachment.mimeType.startsWith('video/') ? 'Video' : 'File');
        return '$type: ${attachment.originalFilename}';
      }
      return '$count files';
    }
    if (note.linkPreview != null && note.linkPreview!.title != null) {
      return 'Link: ${note.linkPreview!.title}';
    }
    return '';
  }

  void _showContextMenu(BuildContext context, Channel channel, Offset? globalPosition) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    // Use provided position (right-click) or calculate from widget (long-press)
    final Offset position;
    if (globalPosition != null) {
      position = globalPosition;
    } else {
      final RenderBox button = context.findRenderObject() as RenderBox;
      position = button.localToGlobal(Offset.zero, ancestor: overlay);
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
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: channel.pinned ? 'unpin' : 'pin',
          child: Text(channel.pinned ? 'Unpin' : 'Pin'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ).then((value) {
      if (value == null) return;
      switch (value) {
        case 'edit':
          _showEditChannelDialog(context, ref, channel);
          break;
        case 'pin':
          _togglePin(ref, channel.id!, true);
          break;
        case 'unpin':
          _togglePin(ref, channel.id!, false);
          break;
        case 'delete':
          _deleteChannel(context, ref, channel.id!, channel.name);
          break;
      }
    });
  }

  void _switchChannel(WidgetRef ref, int channelId) {
    // Discard any editing state when switching channels
    ref.read(editingNoteProvider.notifier).cancelEditing();
    ref.read(currentChannelProvider.notifier).switchChannel(channelId);
  }

  void _deleteChannel(
    BuildContext context,
    WidgetRef ref,
    int channelId,
    String channelName,
  ) async {
    try {
      await ref.read(channelsProvider.notifier).deleteChannel(channelId);
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Cannot delete channel: $e', type: ToastType.error);
      }
    }
  }

  void _togglePin(WidgetRef ref, int channelId, bool pinned) async {
    await ref.read(channelsProvider.notifier).updateChannel(
          channelId,
          pinned: pinned,
        );
  }

  void _showCreateChannelDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedEmoji = '💬';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Channel'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Channel Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Emoji: '),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEmojiPicker(context, (emoji) {
                        setState(() => selectedEmoji = emoji);
                      }),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Tap to change', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final channel = await ref.read(channelsProvider.notifier).createChannel(
                        name,
                        emoji: selectedEmoji,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    // Switch to the newly created channel
                    ref.read(currentChannelProvider.notifier).switchChannel(channel.id!);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditChannelDialog(
    BuildContext context,
    WidgetRef ref,
    Channel channel,
  ) {
    final nameController = TextEditingController(text: channel.name);
    String selectedEmoji = channel.emoji;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Channel'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Channel Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Emoji: '),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEmojiPicker(context, (emoji) {
                        setState(() => selectedEmoji = emoji);
                      }),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(selectedEmoji, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Tap to change', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  await ref.read(channelsProvider.notifier).updateChannel(
                        channel.id!,
                        name: name,
                        emoji: selectedEmoji,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, Function(String) onEmojiSelected) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: 300,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            onEmojiSelected(emoji.emoji);
            Navigator.pop(ctx);
          },
          config: const Config(
            height: 256,
            checkPlatformCompatibility: true,
            emojiViewConfig: EmojiViewConfig(
              emojiSizeMax: 28,
              columns: 7,
            ),
          ),
        ),
      ),
    );
  }
}
