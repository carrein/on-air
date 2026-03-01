import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../main.dart' show client;
import '../providers/archive_items_provider.dart';
import '../utils/icon_utils.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';
import 'note_item.dart';

/// Archive view showing a mixed list of archived notes and channels.
class ArchiveView extends ConsumerWidget {
  const ArchiveView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archiveAsync = ref.watch(archiveItemsProvider);

    return archiveAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: _EmptyStateBox(
              icon: PhosphorIconsRegular.empty,
              message: 'It\'s quiet in here...',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.type == 'note' && item.note != null) {
              return NoteItem(note: item.note!, channelId: -1);
            } else if (item.type == 'channel' && item.channel != null) {
              return _ArchivedChannelItem(channel: item.channel!);
            }
            return const SizedBox.shrink();
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => const Center(
        child: Text('Unable to load notes. Check your connection.'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _ArchivedChannelItem extends ConsumerWidget {
  final Channel channel;
  const _ArchivedChannelItem({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const borderColor = Color(0xFFCE2161);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Listener(
                        onPointerDown: (event) {
                          if (event.buttons == 2) {
                            _showContextMenu(context, ref, event.position);
                          }
                        },
                        child: GestureDetector(
                          onLongPress: () =>
                              _showContextMenu(context, ref, null),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F0ED),
                              border: Border.all(
                                color: borderColor,
                                width: 1.0,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PhosphorIcon(
                                  getChannelIcon(channel.emoji),
                                  size: 24,
                                  color: const Color(0xFF00171F),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    channel.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF00171F),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDADDD8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Channel',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(
                                        0xFF00171F,
                                      ).withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButtonStyled(
                    icon: PhosphorIcons.arrowCounterClockwise(),
                    color: const Color(0xFF00171F),
                    onPressed: () => _restoreChannel(context, ref),
                  ),
                  const SizedBox(width: 8),
                  IconButtonStyled(
                    icon: PhosphorIcons.x(),
                    color: const Color(0xFF00171F),
                    onPressed: () => _showDeleteConfirmation(context, ref),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset? globalPosition,
  ) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final Offset position =
        globalPosition ??
        Offset(overlay.size.width / 2, overlay.size.height / 2);

    final value = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [
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
      ],
    );

    if (value == null) return;
    if (!context.mounted) return;
    switch (value) {
      case 'restore':
        _restoreChannel(context, ref);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref);
        break;
    }
  }

  void _restoreChannel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(archiveItemsProvider.notifier).restoreChannel(channel.id!);
      if (context.mounted) {
        ToastUtils.show(context, 'Channel restored', type: ToastType.success);
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

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    int noteCount = 0;
    try {
      noteCount = await client.chat.getArchivedChannelNoteCount(channel.id!);
    } catch (_) {}

    if (!context.mounted) return;

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
            'Delete ${channel.name} and $noteCount note${noteCount == 1 ? '' : 's'} permanently?',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00171F),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ref
                      .read(archiveItemsProvider.notifier)
                      .deleteChannel(channel.id!);
                  if (context.mounted) {
                    ToastUtils.show(
                      context,
                      'Channel deleted permanently',
                      type: ToastType.success,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ToastUtils.show(
                      context,
                      'Failed to delete: $e',
                      type: ToastType.error,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB0000),
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared empty-state container used throughout the archive and chat views.
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
