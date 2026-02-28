import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/channel_media_provider.dart';
import '../providers/current_channel_provider.dart';
import 'media_grid.dart';
import 'link_list.dart';

/// Right panel displaying media and links from the current channel.
/// Shows tabs for IMAGES, VIDEOS, DOCUMENTS, and LINKS.
class MediaPanel extends ConsumerStatefulWidget {
  final bool fixedWidth;

  const MediaPanel({super.key, this.fixedWidth = true});

  @override
  ConsumerState<MediaPanel> createState() => _MediaPanelState();
}

class _MediaPanelState extends ConsumerState<MediaPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentChannelAsync = ref.watch(currentChannelProvider);

    return currentChannelAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (channelId) {
        // channelMediaDataProvider is now synchronous — no AsyncValue wrapper,
        // so it never flickers through a loading state on notes changes.
        final media = ref.watch(channelMediaDataProvider(channelId));

        return Container(
          width: widget.fixedWidth ? 340 : null,
          decoration: const BoxDecoration(
            color: Color(0xFFF6F0ED),
            border: Border(
              left: BorderSide(color: Color(0xFFCE2161), width: 1),
            ),
          ),
          child: Column(
            children: [
              // Tab bar — flush against content (no separator)
              Container(
                color: const Color(0xFFF6F0ED),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFCE2161),
                  unselectedLabelColor: const Color(
                    0xFF00171F,
                  ).withValues(alpha: 0.6),
                  indicatorColor: const Color(0xFFCE2161),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const UnderlineTabIndicator(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Color(0xFFCE2161), width: 3),
                  ),
                  dividerColor: const Color(0xFFCE2161).withValues(alpha: 0.2),
                  dividerHeight: 1,
                  labelStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                  tabs: const [
                    Tab(text: 'Images'),
                    Tab(text: 'Videos'),
                    Tab(text: 'Docs'),
                    Tab(text: 'Links'),
                  ],
                ),
              ),

              // Tab content — always has data (empty ChannelMedia on loading/error)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    MediaGrid(items: media.images, type: MediaType.image),
                    MediaGrid(items: media.videos, type: MediaType.video),
                    MediaGrid(
                      items: media.documents,
                      type: MediaType.document,
                    ),
                    LinkList(links: media.links),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildEmptyShell(),
      error: (e, s) => _buildEmptyShell(),
    );
  }

  /// Empty media panel with tabs but no content — used for loading/error states
  /// so the user sees the familiar "No images" etc. instead of raw errors.
  Widget _buildEmptyShell() {
    return Container(
      width: widget.fixedWidth ? 340 : null,
      decoration: const BoxDecoration(
        color: Color(0xFFF6F0ED),
        border: Border(
          left: BorderSide(color: Color(0xFFCE2161), width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF6F0ED),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFCE2161),
              unselectedLabelColor: const Color(
                0xFF00171F,
              ).withValues(alpha: 0.6),
              indicatorColor: const Color(0xFFCE2161),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: const UnderlineTabIndicator(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Color(0xFFCE2161), width: 3),
              ),
              dividerColor: const Color(0xFFCE2161).withValues(alpha: 0.2),
              dividerHeight: 1,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 14),
              tabs: const [
                Tab(text: 'Images'),
                Tab(text: 'Videos'),
                Tab(text: 'Docs'),
                Tab(text: 'Links'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                MediaGrid(items: [], type: MediaType.image),
                MediaGrid(items: [], type: MediaType.video),
                MediaGrid(items: [], type: MediaType.document),
                LinkList(links: []),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
