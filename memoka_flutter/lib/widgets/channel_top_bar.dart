import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/settings_view_provider.dart';
import '../providers/settings_page_provider.dart';
import '../utils/icon_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';
import 'media_sidebar.dart';
import 'new_channel_modal.dart';

/// Top bar displaying the current channel name and a menu button.
class ChannelTopBar extends ConsumerWidget {
  const ChannelTopBar({super.key});

  static const _backgroundColor = Color(0xFFF6F0ED);
  static const _borderColor = Color(0xFFCE2161);
  static const _textColor = Color(0xFF00171F);

  static const _titleStyle = TextStyle(
    color: _textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _padding = EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final channelsAsync = ref.watch(channelsProvider);

    return Container(
      padding: _padding,
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTitle(currentChannelAsync, channelsAsync)),
          IconButtonStyled(
            icon: PhosphorIcons.dotsThreeCircle(),
            onPressed: () => _showTopBarMenu(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(AsyncValue<int> currentChannelAsync, AsyncValue<List<Channel>> channelsAsync) {
    return currentChannelAsync.when(
      data: (channelId) {
        if (channelId == -1) {
          return Row(
            children: [
              Icon(PhosphorIcons.archive(), color: _textColor, size: 20),
              const SizedBox(width: 8),
              const Text('Archive', style: _titleStyle),
            ],
          );
        }
        return channelsAsync.when(
          data: (channels) {
            final channel = channels.where((c) => c.id == channelId).firstOrNull;
            if (channel == null) return const SizedBox.shrink();
            return Row(
              children: [
                PhosphorIcon(getChannelIcon(channel.emoji), color: _textColor, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    channel.name,
                    style: _titleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  void _showTopBarMenu(BuildContext context, WidgetRef ref) async {
    final currentChannelId = ref.read(currentChannelProvider).value;
    final channels = ref.read(channelsProvider).value ?? [];
    final channel = (currentChannelId != null && currentChannelId != -1)
        ? channels.where((c) => c.id == currentChannelId).firstOrNull
        : null;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final showMedia = !ResponsiveUtils.shouldShowMediaSidebar(context);

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        overlay.size.width,
        0,
        0,
        0,
      ),
      color: _backgroundColor,
      items: [
        // Channel-specific actions (only when viewing a real channel)
        if (channel != null) ...[
          PopupMenuItem(
            value: 'edit_channel',
            child: Row(
              children: [
                Icon(PhosphorIcons.pencilSimple(), color: _textColor, size: 20),
                const SizedBox(width: 12),
                const Text('Edit Channel', style: TextStyle(color: _textColor)),
              ],
            ),
          ),
          PopupMenuItem(
            value: channel.pinned ? 'unpin_channel' : 'pin_channel',
            child: Row(
              children: [
                Icon(
                  channel.pinned ? PhosphorIcons.pushPinSlash() : PhosphorIcons.pushPin(),
                  color: _textColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  channel.pinned ? 'Unpin' : 'Pin',
                  style: const TextStyle(color: _textColor),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'archive_channel',
            child: Row(
              children: [
                Icon(PhosphorIcons.archive(), color: _textColor, size: 20),
                const SizedBox(width: 12),
                const Text('Archive Channel', style: TextStyle(color: _textColor)),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],
        // Global actions
        PopupMenuItem(
          value: 'new_channel',
          child: Row(
            children: [
              Icon(PhosphorIcons.plusCircle(), color: _textColor, size: 20),
              const SizedBox(width: 12),
              const Text('New Channel', style: TextStyle(color: _textColor)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive_crate',
          child: Row(
            children: [
              Icon(PhosphorIcons.archive(), color: _textColor, size: 20),
              const SizedBox(width: 12),
              const Text('Archive Crate', style: TextStyle(color: _textColor)),
            ],
          ),
        ),
        if (showMedia)
          PopupMenuItem(
            value: 'media',
            child: Row(
              children: [
                Icon(PhosphorIcons.images(), color: _textColor, size: 20),
                const SizedBox(width: 12),
                const Text('Media', style: TextStyle(color: _textColor)),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(PhosphorIcons.gear(), color: _textColor, size: 20),
              const SizedBox(width: 12),
              const Text('Settings', style: TextStyle(color: _textColor)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || result == null) return;

    switch (result) {
      case 'edit_channel':
        if (channel != null) _showEditChannelDialog(context, ref, channel);
        break;
      case 'pin_channel':
        if (channel != null) _togglePin(ref, channel.id!, true);
        break;
      case 'unpin_channel':
        if (channel != null) _togglePin(ref, channel.id!, false);
        break;
      case 'archive_channel':
        if (channel != null && context.mounted) _archiveChannel(context, ref, channel.id!);
        break;
      case 'new_channel':
        NewChannelModal.show(
          context,
          onConfirm: (name, emoji) async {
            final ch = await ref.read(channelsProvider.notifier).createChannel(
                  name,
                  emoji: emoji,
                );
            ref.read(currentChannelProvider.notifier).switchChannel(ch.id!);
          },
        );
        break;
      case 'archive_crate':
        ref.read(editingNoteProvider.notifier).cancelEditing();
        ref.read(settingsVisibilityProvider.notifier).hide();
        ref.read(currentChannelProvider.notifier).switchChannel(-1);
        break;
      case 'media':
        _showMediaBottomSheet(context);
        break;
      case 'settings':
        ref.read(currentSettingsPageProvider.notifier).showMain();
        ref.read(settingsVisibilityProvider.notifier).show();
        break;
    }
  }

  void _showEditChannelDialog(BuildContext context, WidgetRef ref, Channel channel) {
    NewChannelModal.show(
      context,
      channel: channel,
      onConfirm: (name, emoji) async {
        await ref.read(channelsProvider.notifier).updateChannel(
              channel.id!,
              name: name,
              emoji: emoji,
            );
      },
    );
  }

  void _togglePin(WidgetRef ref, int channelId, bool pinned) {
    ref.read(channelsProvider.notifier).updateChannel(channelId, pinned: pinned);
  }

  void _archiveChannel(BuildContext context, WidgetRef ref, int channelId) async {
    try {
      final currentId = ref.read(currentChannelProvider).value;
      await ref.read(channelsProvider.notifier).archiveChannel(channelId);
      if (currentId == channelId) {
        final chs = await ref.read(channelsProvider.future);
        if (chs.isNotEmpty) {
          ref.read(currentChannelProvider.notifier).switchChannel(chs.first.id!);
        }
      }
      if (context.mounted) {
        ToastUtils.show(context, 'Channel archived', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, e.toString().replaceFirst('Exception: ', ''), type: ToastType.error);
      }
    }
  }

  void _showMediaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: GestureDetector(
          onTap: () {},
          child: DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _textColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
}
