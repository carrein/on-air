import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../utils/responsive_utils.dart';
import 'icon_button_styled.dart';
import 'media_sidebar.dart';

/// Top bar displaying the current channel name and a menu button (mobile/tablet).
class ChannelTopBar extends ConsumerWidget {
  const ChannelTopBar({super.key});

  static const _backgroundColor = Color(0xFF00171F);
  static const _padding = EdgeInsets.only(left: 16, top: 8, bottom: 8, right: 8);
  static const _titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.normal,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentChannelAsync = ref.watch(currentChannelProvider);
    final channelsAsync = ref.watch(channelsProvider);
    final showMenuButton = !ResponsiveUtils.shouldShowMediaSidebar(context);

    return Container(
      padding: _padding,
      color: _backgroundColor,
      child: Row(
        children: [
          Expanded(child: _buildTitle(currentChannelAsync, channelsAsync)),
          if (showMenuButton)
            IconButtonStyled(
              icon: PhosphorIconsDuotone.dotsThreeCircle,
              onPressed: () => _showTopBarMenu(context),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildTitle(AsyncValue<int> currentChannelAsync, AsyncValue<List<Channel>> channelsAsync) {
    return currentChannelAsync.when(
      data: (channelId) {
        if (channelId == -1) {
          return const Text('Archive', style: _titleStyle);
        }
        return channelsAsync.when(
          data: (channels) {
            final channel = channels.where((c) => c.id == channelId).firstOrNull;
            if (channel == null) return const SizedBox.shrink();
            return Text(
              channel.name,
              style: _titleStyle,
              overflow: TextOverflow.ellipsis,
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

  void _showTopBarMenu(BuildContext context) async {
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
        PopupMenuItem(
          value: 'media',
          child: Row(
            children: [
              PhosphorIcon(PhosphorIconsDuotone.images, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Media', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
    if (result == 'media' && context.mounted) {
      _showMediaBottomSheet(context);
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
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
