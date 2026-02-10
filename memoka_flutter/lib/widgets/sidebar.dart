import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoka_client/memoka_client.dart';
import '../providers/channels_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_view_provider.dart';
import '../providers/settings_page_provider.dart';
import '../utils/toast_utils.dart';
import 'new_channel_modal.dart';

/// Sidebar displaying channels list and add channel button.
/// Fixed width (240px), always visible.
class Sidebar extends ConsumerStatefulWidget {
  const Sidebar({super.key});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar> {
  // -- Colors --
  static const _backgroundColor = Color(0xFF00171F);
  static const _selectedColor = Color(0xFFCE2161);
  static const _dividerColor = Color(0xFFFF52A1);
  static const _textColor = Colors.white;
  static const _previewTextAlpha = 0.7;

  // -- Layout --
  static const double _sidebarWidth = 240.0;
  static const _logoIconSize = 44.0;
  static const _logoPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  static const _logoTextGap = 16.0;
  static const _logoFontSize = 32.0;
  static const _emojiContainerSize = 40.0;
  static const _emojiFontSize = 18.0;
  static const _channelItemPadding = EdgeInsets.only(left: 8, right: 18, top: 10, bottom: 10);
  static const _emojiToTextGap = 8.0;
  static const _channelNameFontSize = 14.0;
  static const _previewFontSize = 10.0;
  static const _pinIconSize = 20.0;
  static const _pinIconRotation = 15 * 3.14159 / 180;
  static const _pinIconGap = 12.0;
  static const _fadeGradientHeight = 60.0;
  static const _dividerHeight = 1.0;
  static const _buttonPadding = EdgeInsets.only(left: 16, right: 20, top: 16, bottom: 16);
  static const _buttonIconSize = 28.0;
  static const _buttonTextGap = 16.0;
  static const _buttonFontSize = 16.0;

  // -- Scroll --
  static const _scrollThreshold = 10.0;

  final ScrollController _scrollController = ScrollController();
  bool _showFadeOut = true;
  bool _showFadeIn = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - _scrollThreshold;
      final isAtTop = _scrollController.position.pixels <= _scrollThreshold;

      if (_showFadeOut == isAtBottom || _showFadeIn == isAtTop) {
        setState(() {
          _showFadeOut = !isAtBottom;
          _showFadeIn = !isAtTop;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);
    final currentChannelAsync = ref.watch(currentChannelProvider);

    return Container(
          width: _sidebarWidth,
          decoration: const BoxDecoration(
            color: _backgroundColor,
          ),
          child: Column(
            children: [
              // Logo and app name
              Container(
                padding: _logoPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/images/icon.svg',
                      width: _logoIconSize,
                      height: _logoIconSize,
                    ),
                    const SizedBox(width: _logoTextGap),
                    Text(
                      'memoka',
                      style: GoogleFonts.combo(
                        fontSize: _logoFontSize,
                        fontWeight: FontWeight.normal,
                        color: _textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: _dividerHeight, color: _dividerColor),
              // Channels list
              Expanded(
                child: Stack(
                  children: [
                    channelsAsync.when(
                      data: (channels) {
                        // Filter out system channels (e.g., Archive)
                        final regularChannels = channels.where((c) => !c.isSystemChannel).toList();

                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            scrollbars: false,
                          ),
                          child: ListView.separated(
                            controller: _scrollController,
                            itemCount: regularChannels.length,
                            separatorBuilder: (context, index) {
                              // Add divider between pinned and unpinned channels
                              final currentChannel = regularChannels[index];
                              final nextChannel = index + 1 < regularChannels.length ? regularChannels[index + 1] : null;

                              if (currentChannel.pinned && nextChannel != null && !nextChannel.pinned) {
                                return Container(height: _dividerHeight, color: _dividerColor);
                              }
                              return const SizedBox.shrink();
                            },
                            itemBuilder: (context, index) {
                              final channel = regularChannels[index];
                              final isSelected = currentChannelAsync.value == channel.id;

                              return _buildChannelItem(
                                channel,
                                isSelected,
                                context,
                              );
                            },
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                    ),
                    // Fade-in gradient at top (only when scrolled down)
                    if (_showFadeIn)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: _fadeGradientHeight,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _backgroundColor.withValues(alpha: 0.95),
                                  _backgroundColor.withValues(alpha: 0.5),
                                  _backgroundColor.withValues(alpha: 0),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Fade-out gradient at bottom (only when not at bottom)
                    if (_showFadeOut)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: _fadeGradientHeight,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _backgroundColor.withValues(alpha: 0),
                                  _backgroundColor.withValues(alpha: 0.5),
                                  _backgroundColor.withValues(alpha: 0.95),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Separator before buttons
              Container(height: _dividerHeight, color: _dividerColor),
              _buildAddButton(context),
              // Archive Crate button
              _buildArchiveButton(),
              // Settings button
              _buildAccountButton(context),
            ],
          ),
        );
  }

  Widget _buildChannelItem(
    Channel channel,
    bool isSelected,
    BuildContext context,
  ) {
    // Get latest note for preview
    final notesAsync = ref.watch(notesProvider(channel.id!));
    final latestNote = notesAsync.value?.isNotEmpty == true ? notesAsync.value!.first : null;

    return Material(
      color: isSelected ? _selectedColor : Colors.transparent,
      child: InkWell(
        onTap: () => _switchChannel(ref, channel.id!),
        onSecondaryTapDown: (details) => _showContextMenu(context, channel, details.globalPosition),
        onLongPress: () => _showContextMenu(context, channel, null),
        child: Padding(
          padding: _channelItemPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Emoji avatar (no background)
              SizedBox(
                width: _emojiContainerSize,
                height: _emojiContainerSize,
                child: Center(
                  child: Text(
                    channel.emoji,
                    style: const TextStyle(fontSize: _emojiFontSize),
                  ),
                ),
              ),
              // Channel name and message preview
              const SizedBox(width: _emojiToTextGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: _channelNameFontSize,
                        fontWeight: FontWeight.normal,
                        color: _textColor,
                      ),
                    ),
                    if (latestNote != null && _shouldShowPreview(latestNote))
                      Text(
                        _getPreviewText(latestNote),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: _previewFontSize,
                          color: _textColor.withValues(alpha: _previewTextAlpha),
                        ),
                      ),
                  ],
                ),
              ),
              // Pin icon at the end
              if (channel.pinned) ...[
                const SizedBox(width: _pinIconGap),
                Transform.rotate(
                  angle: _pinIconRotation,
                  child: SvgPicture.asset(
                    'assets/images/star.svg',
                    width: _pinIconSize,
                    height: _pinIconSize,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCreateChannelDialog(context, ref),
        child: Padding(
          padding: _buttonPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/new-note.svg',
                width: _buttonIconSize,
                height: _buttonIconSize,
              ),
              const SizedBox(width: _buttonTextGap),
              Expanded(
                child: Text(
                  'New Channel',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.combo(
                    fontSize: _buttonFontSize,
                    fontWeight: FontWeight.normal,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArchiveButton() {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final isSelected = currentChannelAsync.maybeWhen(
      data: (id) => id == -1,
      orElse: () => false,
    );

    return Material(
      color: isSelected ? _selectedColor : Colors.transparent,
      child: InkWell(
        onTap: () => _switchChannel(ref, -1),
        child: Padding(
          padding: _buttonPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/recycle.svg',
                width: _buttonIconSize,
                height: _buttonIconSize,
              ),
              const SizedBox(width: _buttonTextGap),
              Expanded(
                child: Text(
                  'Archive Crate',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.combo(
                    fontSize: _buttonFontSize,
                    fontWeight: FontWeight.normal,
                    color: _textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(currentSettingsPageProvider.notifier).showMain();
          ref.read(settingsVisibilityProvider.notifier).show();
        },
        child: Padding(
          padding: _buttonPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/images/settings.svg',
                width: _buttonIconSize,
                height: _buttonIconSize,
              ),
              const SizedBox(width: _buttonTextGap),
              Expanded(
                child: Text(
                  'Settings',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.combo(
                    fontSize: _buttonFontSize,
                    fontWeight: FontWeight.normal,
                    color: _textColor,
                  ),
                ),
              ),
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
        const PopupMenuItem(value: 'archive', child: Text('Archive')),
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
        case 'archive':
          _archiveChannel(context, ref, channel.id!);
          break;
      }
    });
  }

  void _switchChannel(WidgetRef ref, int channelId) {
    // Discard any editing state when switching channels
    ref.read(editingNoteProvider.notifier).cancelEditing();
    // Hide settings if showing
    ref.read(settingsVisibilityProvider.notifier).hide();
    ref.read(currentChannelProvider.notifier).switchChannel(channelId);
  }

  void _archiveChannel(
    BuildContext context,
    WidgetRef ref,
    int channelId,
  ) async {
    try {
      // If archiving the currently viewed channel, switch first
      final currentId = ref.read(currentChannelProvider).value;
      await ref.read(channelsProvider.notifier).archiveChannel(channelId);
      if (currentId == channelId) {
        // Channels will refetch; switch to first available
        final channels = await ref.read(channelsProvider.future);
        if (channels.isNotEmpty) {
          ref.read(currentChannelProvider.notifier).switchChannel(channels.first.id!);
        }
      }
      if (context.mounted) {
        ToastUtils.show(context, 'Channel archived', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ToastUtils.show(context, msg, type: ToastType.error);
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
    NewChannelModal.show(
      context,
      onConfirm: (name, emoji) async {
        final channel = await ref.read(channelsProvider.notifier).createChannel(
              name,
              emoji: emoji,
            );
        ref.read(currentChannelProvider.notifier).switchChannel(channel.id!);
      },
    );
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
        await ref.read(channelsProvider.notifier).updateChannel(
              channel.id!,
              name: name,
              emoji: emoji,
            );
      },
    );
  }
}
