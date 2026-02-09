import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/channel_media_provider.dart';
import '../providers/current_channel_provider.dart';
import 'media_grid.dart';
import 'link_list.dart';

/// Right sidebar displaying media and links from the current channel.
/// Shows tabs for IMAGES, VIDEOS, DOCUMENTS, and LINKS.
class MediaSidebar extends ConsumerStatefulWidget {
  final bool fixedWidth;

  const MediaSidebar({super.key, this.fixedWidth = true});

  @override
  ConsumerState<MediaSidebar> createState() => _MediaSidebarState();
}

class _MediaSidebarState extends ConsumerState<MediaSidebar> with SingleTickerProviderStateMixin {
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
          decoration: BoxDecoration(
            color: const Color(0xFF283044),
            border: Border(
              left: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Tab bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.blue[700],
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Colors.blue[700],
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontSize: 11),
                  tabs: [
                    _buildTab('IMAGES', mediaAsync.valueOrNull?.images.length ?? 0),
                    _buildTab('VIDEOS', mediaAsync.valueOrNull?.videos.length ?? 0),
                    _buildTab('DOCS', mediaAsync.valueOrNull?.documents.length ?? 0),
                    _buildTab('LINKS', mediaAsync.valueOrNull?.links.length ?? 0),
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
                      MediaGrid(items: media.documents, type: MediaType.document),
                      LinkList(links: media.links),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
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
        color: const Color(0xFF283044),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Container(
        width: 300,
        color: const Color(0xFF283044),
        child: Center(
          child: Text(
            'Error: $err',
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (count > 0)
            Text(
              '$count',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }
}
