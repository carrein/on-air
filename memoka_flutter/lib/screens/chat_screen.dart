import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_html/html.dart' as html;
import '../widgets/sidebar.dart';
import '../widgets/chat_view.dart';
import '../widgets/input_bar.dart';
import '../widgets/offline_banner.dart';
import '../widgets/media_sidebar.dart';
import '../widgets/settings_view.dart';
import '../providers/settings_view_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../utils/responsive_utils.dart';

/// Main chat screen with sidebar, chat view, and input bar.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMediaSidebar = ResponsiveUtils.shouldShowMediaSidebar(context);
    final isShowingSettings = ref.watch(settingsVisibilityProvider);
    final currentChannelAsync = ref.watch(currentChannelProvider);

    // Update browser/PWA title with current channel name
    if (kIsWeb) {
      final channelsAsync = ref.watch(channelsProvider);
      currentChannelAsync.whenData((channelId) {
        if (channelId == -1) {
          html.document.title = 'Memoka - Archive';
        } else {
          channelsAsync.whenData((channels) {
            final channel = channels.where((c) => c.id == channelId).firstOrNull;
            if (channel != null) {
              html.document.title = 'Memoka - ${channel.name}';
            }
          });
        }
      });
    }

    Widget getMainContent() {
      if (isShowingSettings) {
        return const SettingsView();
      } else {
        // Check if viewing Archive channel
        final isArchive = currentChannelAsync.maybeWhen(
          data: (channelId) => channelId == -1,
          orElse: () => false,
        );

        return Column(
          children: [
            const Expanded(child: ChatView()),
            // Hide InputBar in Archive
            if (!isArchive) const InputBar(),
          ],
        );
      }
    }

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Row(
              children: [
                // Left sidebar with channels
                const Sidebar(),
                // Main content area - settings pages or chat
                Expanded(child: getMainContent()),
                // Right sidebar with media (desktop only, hidden when showing settings)
                if (showMediaSidebar && !isShowingSettings) const MediaSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
