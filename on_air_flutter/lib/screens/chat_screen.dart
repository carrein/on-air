import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/sidebar.dart';
import '../widgets/chat_view.dart';
import '../widgets/input_bar.dart';
import '../widgets/offline_banner.dart';
import '../widgets/media_sidebar.dart';
import '../utils/responsive_utils.dart';

/// Main chat screen with sidebar, chat view, and input bar.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMediaSidebar = ResponsiveUtils.shouldShowMediaSidebar(context);

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Row(
              children: [
                // Left sidebar with channels
                const Sidebar(),
                // Chat area
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: ChatView()),
                      const InputBar(),
                    ],
                  ),
                ),
                // Right sidebar with media (desktop only)
                if (showMediaSidebar) const MediaSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
