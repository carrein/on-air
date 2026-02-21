import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_view_provider.dart';
import '../providers/settings_page_provider.dart';
import '../providers/media_panel_visible_provider.dart';
import '../utils/icon_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';
import 'media_panel.dart';
import 'new_channel_modal.dart';
import 'sync_indicator.dart';

/// Navbar displaying the current channel name and a menu button.
class Navbar extends ConsumerWidget {
  const Navbar({super.key});

  static const _backgroundColor = Color(0xFFF6F0ED);
  static const _borderColor = Color(0xFFCE2161);
  static const _textColor = Color(0xFF00171F);

  static const _titleStyle = TextStyle(
    color: _textColor,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const _paddingDetail = EdgeInsets.only(
    left: 8,
    right: 16,
    top: 8,
    bottom: 8,
  );
  static const _paddingStandard = EdgeInsets.only(
    left: 16,
    right: 8,
    top: 8,
    bottom: 8,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final channelsAsync = ref.watch(channelsProvider);
    final isShowingSettings = ref.watch(settingsVisibilityProvider);
    final selection = ref.watch(noteSelectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final mediaPanelVisible = ref.watch(mediaPanelVisibleProvider);
    final isDesktop = ResponsiveUtils.isDesktop(context);

    if (isSelectionMode) {
      return _buildSelectionBar(context, ref, selection);
    }

    final currentChannelId = currentChannelAsync.valueOrNull;
    final channels = channelsAsync.valueOrNull ?? [];
    final isArchive = currentChannelId == -1;
    final isInDetailMode = isShowingSettings || isArchive;

    final currentChannel = (!isInDetailMode && currentChannelId != null)
        ? channels.where((c) => c.id == currentChannelId).firstOrNull
        : null;

    return Container(
      padding: isInDetailMode ? _paddingDetail : _paddingStandard,
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Row(
        children: [
          if (isInDetailMode) ...[
            IconButtonStyled(
              icon: PhosphorIcons.arrowCircleLeft(),
              onPressed: () => _goBack(context, ref),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: _buildTitle(
              currentChannelAsync,
              channelsAsync,
              isShowingSettings,
            ),
          ),
          if (!isInDetailMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentChannel != null) ...[
                  IconButtonStyled(
                    icon: currentChannel.pinned
                        ? PhosphorIcons.pushPinSlash()
                        : PhosphorIcons.pushPin(),
                    onPressed: () => _togglePin(
                      ref,
                      currentChannel.id!,
                      !currentChannel.pinned,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (isDesktop) ...[
                  Transform.rotate(
                    angle: math.pi,
                    child: IconButtonStyled(
                      icon: mediaPanelVisible
                          ? PhosphorIconsFill.sidebar
                          : PhosphorIcons.sidebar(),
                      onPressed: () =>
                          ref.read(mediaPanelVisibleProvider.notifier).toggle(),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const SyncIndicator(),
                IconButtonStyled(
                  icon: PhosphorIcons.dotsThreeCircle(),
                  onPressed: () => _showNavbarMenu(context, ref),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    WidgetRef ref,
    Set<int> selection,
  ) {
    return Container(
      padding: _paddingStandard,
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${selection.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
                const TextSpan(
                  text: ' selected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButtonStyled(
            icon: PhosphorIcons.archive(),
            onPressed: () => _archiveSelected(context, ref, selection),
          ),
          const SizedBox(width: 4),
          IconButtonStyled(
            icon: PhosphorIcons.xCircle(),
            onPressed: () => ref.read(noteSelectionProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveSelected(
    BuildContext context,
    WidgetRef ref,
    Set<int> selection,
  ) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;
    final notifier = ref.read(notesProvider(channelId).notifier);
    for (final noteId in selection) {
      await notifier.deleteNote(noteId);
    }
    ref.read(noteSelectionProvider.notifier).clear();
    if (context.mounted) {
      ToastUtils.show(
        context,
        '${selection.length} note${selection.length == 1 ? '' : 's'} archived',
        type: ToastType.success,
      );
    }
  }

  void _goBack(BuildContext context, WidgetRef ref) {
    if (ref.read(settingsVisibilityProvider)) {
      ref.read(settingsVisibilityProvider.notifier).hide();
    } else {
      // Back from archive: restore previous channel
      final previousId = ref.read(previousChannelProvider);
      if (previousId != null) {
        ref.read(currentChannelProvider.notifier).switchChannel(previousId);
        ref.read(previousChannelProvider.notifier).state = null;
      } else {
        // Fallback to first available channel
        final chs = ref.read(channelsProvider).valueOrNull ?? [];
        final first = chs.where((c) => !c.isSystemChannel).firstOrNull;
        if (first != null) {
          ref.read(currentChannelProvider.notifier).switchChannel(first.id!);
        }
      }
    }
  }

  Widget _buildTitle(
    AsyncValue<int> currentChannelAsync,
    AsyncValue<List<Channel>> channelsAsync,
    bool isShowingSettings,
  ) {
    if (isShowingSettings) {
      return const Text('Settings', style: _titleStyle);
    }
    return currentChannelAsync.when(
      data: (channelId) {
        if (channelId == -1) {
          return const Text('Archive', style: _titleStyle);
        }
        return channelsAsync.when(
          data: (channels) {
            final channel = channels
                .where((c) => c.id == channelId)
                .firstOrNull;
            if (channel == null) return const SizedBox.shrink();
            return Row(
              children: [
                PhosphorIcon(
                  getChannelIcon(channel.emoji),
                  color: _textColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
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

  void _showNavbarMenu(BuildContext context, WidgetRef ref) async {
    final currentChannelId = ref.read(currentChannelProvider).value;
    final channels = ref.read(channelsProvider).value ?? [];
    final channel = (currentChannelId != null && currentChannelId != -1)
        ? channels.where((c) => c.id == currentChannelId).firstOrNull
        : null;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final showMedia = !ResponsiveUtils.shouldShowMediaPanel(context);

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
            value: 'archive_channel',
            child: Row(
              children: [
                Icon(PhosphorIcons.archive(), color: _textColor, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Archive Channel',
                  style: TextStyle(color: _textColor),
                ),
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
          value: 'archive',
          child: Row(
            children: [
              Icon(PhosphorIcons.archive(), color: _textColor, size: 20),
              const SizedBox(width: 12),
              const Text('Archive', style: TextStyle(color: _textColor)),
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
      case 'archive_channel':
        if (channel != null && context.mounted) {
          _archiveChannel(context, ref, channel.id!);
        }
        break;
      case 'new_channel':
        NewChannelModal.show(
          context,
          onConfirm: (name, emoji) async {
            final ch = await ref
                .read(channelsProvider.notifier)
                .createChannel(
                  name,
                  emoji: emoji,
                );
            ref.read(currentChannelProvider.notifier).switchChannel(ch.id!);
          },
        );
        break;
      case 'archive':
        ref.read(previousChannelProvider.notifier).state = ref
            .read(currentChannelProvider)
            .value;
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

  void _showEditChannelDialog(
    BuildContext context,
    WidgetRef ref,
    Channel channel,
  ) {
    NewChannelModal.show(
      context,
      channel: channel,
      onConfirm: (name, emoji) async {
        await ref
            .read(channelsProvider.notifier)
            .updateChannel(
              channel.id!,
              name: name,
              emoji: emoji,
            );
      },
    );
  }

  void _togglePin(WidgetRef ref, int channelId, bool pinned) {
    ref
        .read(channelsProvider.notifier)
        .updateChannel(channelId, pinned: pinned);
  }

  void _archiveChannel(
    BuildContext context,
    WidgetRef ref,
    int channelId,
  ) async {
    try {
      final currentId = ref.read(currentChannelProvider).value;
      await ref.read(channelsProvider.notifier).archiveChannel(channelId);
      if (currentId == channelId) {
        final chs = await ref.read(channelsProvider.future);
        if (chs.isNotEmpty) {
          ref
              .read(currentChannelProvider.notifier)
              .switchChannel(chs.first.id!);
        }
      }
      if (context.mounted) {
        ToastUtils.show(context, 'Channel archived', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  void _showMediaBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                    child: MediaPanel(fixedWidth: false),
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
