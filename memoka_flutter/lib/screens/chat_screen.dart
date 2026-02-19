import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_html/html.dart' as html;
import '../widgets/sidebar.dart';
import '../widgets/chat_view.dart';
import '../widgets/input_bar.dart';
import '../widgets/offline_banner.dart';
import '../widgets/media_sidebar.dart';
import '../widgets/settings_view.dart';
import '../widgets/channel_top_bar.dart';
import '../widgets/share_intent_dialog.dart';
import '../providers/settings_view_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../providers/share_intent_provider.dart';
import '../utils/responsive_utils.dart';

/// Main chat screen with sidebar, chat view, and input bar.
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMediaSidebar = ResponsiveUtils.shouldShowMediaSidebar(context);
    final isShowingSettings = ref.watch(settingsVisibilityProvider);
    final currentChannelAsync = ref.watch(currentChannelProvider);

    // Listen for share intents (Android only)
    if (!kIsWeb) {
      ref.listen(shareIntentProvider, (prev, next) {
        next.whenData((files) {
          if (files.isNotEmpty) {
            showDialog(
              context: context,
              builder: (_) => ShareIntentDialog(sharedFiles: files),
            );
          }
        });
      });
    }

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

    // Check if viewing Archive channel
    final isArchive = currentChannelAsync.maybeWhen(
      data: (channelId) => channelId == -1,
      orElse: () => false,
    );

    Widget getMainContent() {
      if (isShowingSettings) {
        return const Expanded(child: SettingsView());
      } else {
        return const Expanded(child: ChatView());
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF00171F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
      body: SafeArea(
        child: Column(
        children: [
          const OfflineBanner(),
          if (!isShowingSettings) const ChannelTopBar(),
          Expanded(
            child: Row(
              children: [
                const Sidebar(),
                Expanded(child: Column(children: [getMainContent()])),
                if (showMediaSidebar && !isShowingSettings) const MediaSidebar(),
              ],
            ),
          ),
          if (!isArchive && !isShowingSettings) const InputBar(),
        ],
      ),
      ),
      ),
    );
  }
}
