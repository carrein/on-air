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
      data: (channelId) {
        final mediaAsync = ref.watch(channelMediaDataProvider(channelId));

        return Container(
          width: widget.fixedWidth ? 300 : null,
          decoration: const BoxDecoration(
            color: Color(0xFF00171F),
          ),
          child: Column(
            children: [
              // Tab bar — flush against content (no separator)
              Container(
                color: const Color(0xFF00171F),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFCE2161),
                  unselectedLabelColor: Colors.grey[500],
                  indicatorColor: const Color(0xFFCE2161),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const UnderlineTabIndicator(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: Color(0xFFCE2161), width: 3),
                  ),
                  dividerHeight: 0,
                  labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: const [
                    Tab(text: 'IMAGES'),
                    Tab(text: 'VIDEOS'),
                    Tab(text: 'DOCS'),
                    Tab(text: 'LINKS'),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: mediaAsync.when(
                  data: (media) => TabBarView(
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading media: $err',
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: 300,
        color: const Color(0xFF00171F),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        width: 300,
        color: const Color(0xFF00171F),
        child: Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
    );
  }
}
