import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/channels_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_view_provider.dart';
import '../utils/icon_utils.dart';
import '../utils/responsive_utils.dart';

/// Channel list sidebar displaying channels and add channel button.
/// Fixed width (240px), always visible.
class ChannelList extends ConsumerStatefulWidget {
  const ChannelList({super.key});

  @override
  ConsumerState<ChannelList> createState() => _ChannelListState();
}

class _ChannelListState extends ConsumerState<ChannelList> {
  // -- Colors --
  static const _backgroundColor = Color(0xFFF6F0ED);
  static const _selectedColor = Color(0xFFCE2161);
  static const _borderColor = Color(0xFFCE2161);
  static const _textColor = Color(0xFF00171F);
  static const _previewTextAlpha = 0.7;

  // -- Layout --
  static const double _sidebarWidth = 240.0;
  static const double _sidebarCompactWidth = 64.0;
  static const _emojiContainerSize = 40.0;
  static const _emojiFontSize = 18.0;
  static const _channelItemPadding = EdgeInsets.only(left: 8, right: 18, top: 10, bottom: 10);
  static const _emojiToTextGap = 8.0;
  static const _channelNameFontSize = 14.0;
  static const _previewFontSize = 10.0;
  static const _fadeGradientHeight = 60.0;

  // -- Scroll --
  static const _scrollThreshold = 10.0;
  static const _itemHeight = _emojiContainerSize + 20.0; // top(10) + bottom(10) padding

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

  void _scrollToChannel(int channelId, List<Channel> pinned, List<Channel> unpinned) {
    if (!_scrollController.hasClients) return;

    int index = pinned.indexWhere((c) => c.id == channelId);
    if (index == -1) {
      final u = unpinned.indexWhere((c) => c.id == channelId);
      if (u == -1) return;
      index = pinned.length + u;
    }

    final itemTop = index * _itemHeight;
    final pos = _scrollController.position;

    // Center the item in the viewport, clamped to valid scroll range
    final target = (itemTop - (pos.viewportDimension - _itemHeight) / 2)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);

    if ((target - pos.pixels).abs() < 1.0) return;

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
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
    final compact = ResponsiveUtils.isMobile(context);

    ref.listen(currentChannelProvider, (prev, next) {
      final channelId = next.value;
      if (channelId == null || channelId == prev?.value) return;
      final channels = ref.read(channelsProvider).value;
      if (channels == null) return;
      final regular = channels.where((c) => !c.isSystemChannel).toList();
      final pinned = regular.where((c) => c.pinned).toList();
      final unpinned = regular.where((c) => !c.pinned).toList();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToChannel(channelId, pinned, unpinned);
      });
    });

    return Container(
          width: compact ? _sidebarCompactWidth : _sidebarWidth,
          decoration: const BoxDecoration(
            color: _backgroundColor,
            border: Border(right: BorderSide(color: _borderColor, width: 1)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    channelsAsync.when(
                      data: (channels) {
                        // Filter out system channels (e.g., Archive)
                        final regularChannels = channels.where((c) => !c.isSystemChannel).toList();

                        // Split into pinned and unpinned groups
                        final pinned = regularChannels.where((c) => c.pinned).toList();
                        final unpinned = regularChannels.where((c) => !c.pinned).toList();

                        final totalCount = pinned.length + unpinned.length;

                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            scrollbars: false,
                          ),
                          child: ReorderableListView.builder(
                            scrollController: _scrollController,
                            buildDefaultDragHandles: false,
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  final scale = 1.0 + 0.04 * animation.value;
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: _borderColor.withValues(alpha: animation.value),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Material(
                                        elevation: 10 * animation.value,
                                        shadowColor: _borderColor.withValues(alpha: 0.4),
                                        color: _backgroundColor,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: child,
                              );
                            },
                            itemCount: totalCount,
                            onReorder: (oldIndex, newIndex) => _onReorder(
                              oldIndex,
                              newIndex,
                              pinned,
                              unpinned,
                            ),
                            itemBuilder: (context, index) {
                              // Determine which channel this index maps to
                              final Channel channel;
                              if (index < pinned.length) {
                                channel = pinned[index];
                              } else {
                                channel = unpinned[index - pinned.length];
                              }

                              final isSelected = currentChannelAsync.value == channel.id;

                              // Desktop: immediate drag on pointer down.
                              // Mobile: delayed (long-press) to avoid scroll conflicts.
                              final child = _buildChannelItem(channel, isSelected, context, compact: compact);
                              if (ResponsiveUtils.isDesktopPlatform) {
                                return ReorderableDragStartListener(
                                  key: ValueKey(channel.id),
                                  index: index,
                                  child: child,
                                );
                              }
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey(channel.id),
                                index: index,
                                child: child,
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
            ],
          ),
        );
  }

  void _onReorder(
    int oldIndex,
    int newIndex,
    List<Channel> pinned,
    List<Channel> unpinned,
  ) {
    // Determine which group the old index belongs to
    final oldInPinned = oldIndex < pinned.length;
    final pinnedEnd = pinned.length;
    final unpinnedStart = pinnedEnd;

    // Clamp destination to stay within the same group
    if (oldInPinned) {
      // Keep within pinned group [0, pinnedEnd)
      if (newIndex > pinnedEnd) newIndex = pinnedEnd;
      if (newIndex < 0) newIndex = 0;

      // Standard ReorderableListView adjustment
      if (newIndex > oldIndex) newIndex--;

      final reordered = List<Channel>.from(pinned);
      final item = reordered.removeAt(oldIndex);
      reordered.insert(newIndex, item);

      ref.read(channelsProvider.notifier).reorderChannels(
            reordered.map((c) => c.id!).toList(),
          );
    } else {
      // Keep within unpinned group [unpinnedStart, totalCount)
      if (newIndex < unpinnedStart) newIndex = unpinnedStart;

      // Convert to unpinned-local indices
      var localOld = oldIndex - unpinnedStart;
      var localNew = newIndex - unpinnedStart;
      if (localNew > localOld) localNew--;

      final reordered = List<Channel>.from(unpinned);
      final item = reordered.removeAt(localOld);
      reordered.insert(localNew, item);

      ref.read(channelsProvider.notifier).reorderChannels(
            reordered.map((c) => c.id!).toList(),
          );
    }
  }

  Widget _buildChannelItem(
    Channel channel,
    bool isSelected,
    BuildContext context, {
    bool compact = false,
  }) {
    // Get latest note for preview (skip in compact mode)
    final notesAsync = compact ? null : ref.watch(notesProvider(channel.id!));
    final latestNote = notesAsync?.value?.isNotEmpty == true ? notesAsync!.value!.first : null;

    return Material(
      color: isSelected ? _selectedColor : Colors.transparent,
      child: InkWell(
        onTap: () => _switchChannel(ref, channel.id!),
        child: compact
            ? Padding(
                padding: _channelItemPadding.copyWith(left: 0, right: 0),
                child: SizedBox(
                  width: _emojiContainerSize,
                  height: _emojiContainerSize,
                  child: Center(
                    child: channel.pinned
                        ? Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : _textColor,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: PhosphorIcon(
                                getChannelIcon(channel.emoji),
                                size: 20,
                                color: isSelected ? Colors.white : _textColor,
                              ),
                            ),
                          )
                        : PhosphorIcon(
                            getChannelIcon(channel.emoji),
                            size: 22,
                            color: isSelected ? Colors.white : _textColor,
                          ),
                  ),
                ),
              )
            : Padding(
                padding: _channelItemPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Icon avatar — circle border when pinned
                    SizedBox(
                      width: _emojiContainerSize,
                      height: _emojiContainerSize,
                      child: Center(
                        child: channel.pinned
                            ? Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.white : _textColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: PhosphorIcon(
                                    getChannelIcon(channel.emoji),
                                    size: _emojiFontSize,
                                    color: isSelected ? Colors.white : _textColor,
                                  ),
                                ),
                              )
                            : PhosphorIcon(
                                getChannelIcon(channel.emoji),
                                size: _emojiFontSize,
                                color: isSelected ? Colors.white : _textColor,
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
                            style: TextStyle(
                              fontSize: _channelNameFontSize,
                              fontWeight: FontWeight.normal,
                              color: isSelected ? Colors.white : _textColor,
                            ),
                          ),
                          if (latestNote != null && _shouldShowPreview(latestNote))
                            Text(
                              _getPreviewText(latestNote),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: _previewFontSize,
                                color: isSelected
                                    ? Colors.white.withValues(alpha: _previewTextAlpha)
                                    : _textColor.withValues(alpha: _previewTextAlpha),
                              ),
                            ),
                        ],
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

  void _switchChannel(WidgetRef ref, int channelId) {
    // Discard any editing state when switching channels
    ref.read(editingNoteProvider.notifier).cancelEditing();
    // Hide settings if showing
    ref.read(settingsVisibilityProvider.notifier).hide();
    // Direct tap — no slide animation
    ref.read(channelSwitchDirectionProvider.notifier).state = 0;
    ref.read(currentChannelProvider.notifier).switchChannel(channelId);
  }

}
