import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/archive_retention_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_view_provider.dart';
import '../providers/media_panel_visible_provider.dart';
import '../providers/global_search_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/channel_reminders_provider.dart';
import '../utils/icon_utils.dart';
import '../utils/reminder_picker.dart';
import '../utils/responsive_utils.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';
import 'icon_picker.dart';
import 'media_panel.dart';
import 'new_channel_modal.dart';
import 'search_bar_widget.dart';
import 'sync_indicator.dart';

/// Navbar displaying the current channel name and a menu button.
class Navbar extends ConsumerStatefulWidget {
  const Navbar({super.key});

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  static const _backgroundColor = Color(0xFFFFFDF6);
  static const _borderColor = Color(0xFF3450A3);
  static const _textColor = Color(0xFF00171F);

  static const _primaryColor = _borderColor;

  static const _titleStyle = TextStyle(
    color: _primaryColor,
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

  // -- Inline rename (web only) --
  bool _isRenaming = false;
  final _renameController = TextEditingController();
  final _renameFocusNode = FocusNode();

  // Cache the last known channel to prevent title flicker during provider updates.
  Channel? _lastChannel;

  @override
  void initState() {
    super.initState();
    _renameFocusNode.addListener(_onRenameFocusChange);
  }

  @override
  void dispose() {
    _renameFocusNode.removeListener(_onRenameFocusChange);
    _renameFocusNode.dispose();
    _renameController.dispose();
    super.dispose();
  }

  void _startRename(Channel channel) {
    setState(() {
      _isRenaming = true;
      _renameController.text = channel.name;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renameFocusNode.requestFocus();
      _renameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _renameController.text.length,
      );
    });
  }

  Future<void> _commitRename() async {
    if (!_isRenaming) return;
    _isRenaming = false; // Prevent re-entry from concurrent handlers
    final name = _renameController.text.trim();
    final channelId = ref.read(currentChannelProvider).value;
    if (name.isNotEmpty && channelId != null) {
      // Await so the provider state is updated before we rebuild.
      // This avoids a flicker where the old name briefly appears.
      await ref
          .read(channelsProvider.notifier)
          .updateChannel(channelId, name: name);
    }
    if (mounted) setState(() {});
  }

  void _cancelRename() {
    setState(() => _isRenaming = false);
  }

  void _onRenameFocusChange() {
    if (!_renameFocusNode.hasFocus && _isRenaming) {
      _commitRename();
    }
  }

  void _createChannel() {
    NewChannelModal.show(
      context,
      onConfirm: (name, emoji) async {
        final ch = await ref
            .read(channelsProvider.notifier)
            .createChannel(name, emoji: emoji);
        ref.read(currentChannelProvider.notifier).switchChannel(ch.id!);
      },
    );
  }

  void _onIconTap(Channel channel) async {
    final key = await IconPicker.show(context, selectedKey: channel.emoji);
    if (key != null && mounted) {
      ref
          .read(channelsProvider.notifier)
          .updateChannel(channel.id!, emoji: key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final channelsAsync = ref.watch(channelsProvider);
    final isShowingSettings = ref.watch(settingsVisibilityProvider);
    final selection = ref.watch(noteSelectionProvider);
    final isSelectionMode = selection.isNotEmpty;
    final mediaPanelVisible = ref.watch(mediaPanelVisibleProvider);
    final isMobile = ResponsiveUtils.isMobile(context);

    if (isSelectionMode) {
      return _buildSelectionBar(selection);
    }

    final currentChannelId = currentChannelAsync.value;
    final channels = channelsAsync.value ?? [];
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
              onPressed: _goBack,
            ),
            const SizedBox(width: 4),
          ],
          if (!isMobile && !isInDetailMode) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 248),
              child: _buildTitle(
                currentChannelAsync,
                channelsAsync,
                isShowingSettings,
              ),
            ),
            const Expanded(child: SearchBarWidget()),
            const SizedBox(width: 16),
            SizedBox(
              width: ResponsiveUtils.isDesktop(context) && mediaPanelVisible
                  ? 340
                  : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentChannel != null) ...[
                    IconButtonStyled(
                      icon: currentChannel.pinned
                          ? PhosphorIcons.pushPinSlash()
                          : PhosphorIcons.pushPin(),
                      onPressed: () => _togglePin(
                        currentChannel.id!,
                        !currentChannel.pinned,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Transform.rotate(
                    angle: math.pi,
                    child: IconButtonStyled(
                      icon: mediaPanelVisible
                          ? PhosphorIconsFill.sidebar
                          : PhosphorIcons.sidebar(),
                      onPressed: ResponsiveUtils.isDesktop(context)
                          ? () => ref
                                .read(mediaPanelVisibleProvider.notifier)
                                .toggle()
                          : _showMediaBottomSheet,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButtonStyled(
                    icon: PhosphorIcons.plusSquare(),
                    onPressed: _createChannel,
                  ),
                  const SizedBox(width: 2),
                  const SyncIndicator(),
                  IconButtonStyled(
                    icon: PhosphorIcons.dotsThreeOutline(),
                    onPressed: _showNavbarMenu,
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: _buildTitle(
                currentChannelAsync,
                channelsAsync,
                isShowingSettings,
              ),
            ),
            if (isArchive) _buildRetentionDropdown(),
            if (!isInDetailMode)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButtonStyled(
                    icon: PhosphorIcons.magnifyingGlass(),
                    onPressed: () =>
                        ref.read(globalSearchProvider.notifier).activate(),
                  ),
                  const SizedBox(width: 2),
                  if (currentChannel != null) ...[
                    IconButtonStyled(
                      icon: currentChannel.pinned
                          ? PhosphorIcons.pushPinSlash()
                          : PhosphorIcons.pushPin(),
                      onPressed: () => _togglePin(
                        currentChannel.id!,
                        !currentChannel.pinned,
                      ),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Transform.rotate(
                    angle: math.pi,
                    child: IconButtonStyled(
                      icon: mediaPanelVisible
                          ? PhosphorIconsFill.sidebar
                          : PhosphorIcons.sidebar(),
                      onPressed: _showMediaBottomSheet,
                    ),
                  ),
                  const SizedBox(width: 2),
                  IconButtonStyled(
                    icon: PhosphorIcons.plusSquare(),
                    onPressed: _createChannel,
                  ),
                  const SizedBox(width: 2),
                  const SyncIndicator(),
                  IconButtonStyled(
                    icon: PhosphorIcons.dotsThreeOutline(),
                    onPressed: _showNavbarMenu,
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  static const _retentionOptions = <int, String>{
    0: 'Keep Forever',
    30: '30 Days',
    60: '60 Days',
    90: '90 Days',
  };

  Widget _buildRetentionDropdown() {
    final retentionAsync = ref.watch(archiveRetentionProvider);
    final currentValue = retentionAsync.value ?? 0;

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _retentionOptions.containsKey(currentValue) ? currentValue : 0,
        isDense: true,
        style: GoogleFonts.spaceGrotesk(
          color: _textColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: _textColor, size: 18),
        dropdownColor: _backgroundColor,
        items: _retentionOptions.entries
            .map(
              (e) => DropdownMenuItem<int>(
                value: e.key,
                child: Text(e.value),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) {
            ref.read(archiveRetentionProvider.notifier).updateRetention(value);
          }
        },
      ),
    );
  }

  Widget _buildSelectionBar(Set<int> selection) {
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
            icon: PhosphorIcons.siren(),
            onPressed: () => _setReminderForSelected(selection),
          ),
          const SizedBox(width: 4),
          IconButtonStyled(
            icon: PhosphorIcons.archive(),
            onPressed: () => _archiveSelected(selection),
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

  Future<void> _archiveSelected(Set<int> selection) async {
    final channelId = ref.read(currentChannelProvider).value;
    if (channelId == null) return;
    final notifier = ref.read(notesProvider(channelId).notifier);
    for (final noteId in selection) {
      await notifier.deleteNote(noteId);
    }
    ref.read(noteSelectionProvider.notifier).clear();
    if (mounted) {
      ToastUtils.show(
        context,
        '${selection.length} note${selection.length == 1 ? '' : 's'} archived',
        type: ToastType.success,
      );
    }
  }

  Future<void> _setReminderForSelected(Set<int> selection) async {
    final result = await showReminderPicker(context);
    if (result == null || !mounted) return;
    final channelId = ref.read(currentChannelProvider).value;
    var count = 0;
    for (final noteId in selection) {
      try {
        await ref
            .read(reminderProvider(noteId).notifier)
            .createReminder(
              result.scheduledAt,
              recurrenceRule: result.recurrenceRule,
              recurrenceEndAt: result.recurrenceEndAt,
            );
        count++;
      } catch (_) {}
    }
    if (channelId != null) {
      ref.invalidate(channelRemindersProvider(channelId));
    }
    ref.read(noteSelectionProvider.notifier).clear();
    if (mounted) {
      ToastUtils.show(
        context,
        'Reminder set for $count note${count == 1 ? '' : 's'}',
        type: ToastType.success,
      );
    }
  }

  void _goBack() {
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
        final chs = ref.read(channelsProvider).value ?? [];
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
          skipLoadingOnReload: true,
          data: (channels) {
            final channel =
                channels.where((c) => c.id == channelId).firstOrNull ??
                _lastChannel;
            if (channel == null) return const SizedBox.shrink();
            _lastChannel = channel;
            final isDesktopPlatform = ResponsiveUtils.isDesktopPlatform;
            return Row(
              children: [
                GestureDetector(
                  onTap: () => _onIconTap(channel),
                  child: isDesktopPlatform
                      ? MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: PhosphorIcon(
                            getChannelIcon(channel.emoji),
                            color: _primaryColor,
                            size: 22,
                          ),
                        )
                      : PhosphorIcon(
                          getChannelIcon(channel.emoji),
                          color: _primaryColor,
                          size: 22,
                        ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _isRenaming
                      ? KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.escape) {
                              _cancelRename();
                            }
                          },
                          child: TextField(
                            controller: _renameController,
                            focusNode: _renameFocusNode,
                            style: _titleStyle,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _commitRename(),
                            onTapOutside: (_) => _commitRename(),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => _startRename(channel),
                          child: isDesktopPlatform
                              ? MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Text(
                                    channel.name,
                                    style: _titleStyle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : Text(
                                  channel.name,
                                  style: _titleStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
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

  void _showNavbarMenu() async {
    final currentChannelId = ref.read(currentChannelProvider).value;
    final channels = ref.read(channelsProvider).value ?? [];
    final channel = (currentChannelId != null && currentChannelId != -1)
        ? channels.where((c) => c.id == currentChannelId).firstOrNull
        : null;

    // Hide "Archive Channel" when only one non-system channel remains —
    // matches the server-side guard that rejects the last-channel archive.
    final canArchive = channels.where((c) => !c.isSystemChannel).length > 1;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

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
          if (canArchive)
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
          value: 'archive',
          child: Row(
            children: [
              Icon(PhosphorIcons.archive(), color: _textColor, size: 20),
              const SizedBox(width: 12),
              const Text('Archive', style: TextStyle(color: _textColor)),
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

    if (!mounted || result == null) return;

    switch (result) {
      case 'edit_channel':
        if (channel != null) _showEditChannelDialog(channel);
        break;
      case 'archive_channel':
        if (channel != null && mounted) {
          _archiveChannel(channel.id!);
        }
        break;
      case 'archive':
        ref.read(previousChannelProvider.notifier).state = ref
            .read(currentChannelProvider)
            .value;
        ref.read(editingNoteProvider.notifier).cancelEditing();
        ref.read(settingsVisibilityProvider.notifier).hide();
        ref.read(currentChannelProvider.notifier).switchChannel(-1);
        break;
      case 'settings':
        ref.read(settingsVisibilityProvider.notifier).show();
        break;
    }
  }

  void _showEditChannelDialog(Channel channel) {
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

  void _togglePin(int channelId, bool pinned) {
    ref
        .read(channelsProvider.notifier)
        .updateChannel(channelId, pinned: pinned);
  }

  void _archiveChannel(int channelId) async {
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
      if (mounted) {
        ToastUtils.show(context, 'Channel archived', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  void _showMediaBottomSheet() {
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
