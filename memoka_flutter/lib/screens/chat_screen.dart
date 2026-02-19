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
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _swipeVelocityThreshold = 300.0;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    }
    super.dispose();
  }

  /// Returns true if a text field currently holds keyboard focus.
  bool _isTextFieldFocused() {
    final focus = FocusManager.instance.primaryFocus;
    return focus?.context?.widget is EditableText;
  }

  /// Global hardware key handler for web arrow-key channel cycling.
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (_isTextFieldFocused()) return false;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _cycleChannel(-1);
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _cycleChannel(1);
      return true;
    }
    return false;
  }

  /// Cycles to the next (+1) or previous (-1) channel in the list.
  void _cycleChannel(int delta) {
    final channelsAsync = ref.read(channelsProvider);
    final currentAsync = ref.read(currentChannelProvider);

    channelsAsync.whenData((channels) {
      currentAsync.whenData((currentId) {
        // Don't cycle when in Archive
        if (currentId == -1) return;
        if (channels.length <= 1) return;

        final currentIndex = channels.indexWhere((c) => c.id == currentId);
        if (currentIndex == -1) return;

        ref.read(channelSwitchDirectionProvider.notifier).state = delta;
        final nextIndex = (currentIndex + delta + channels.length) % channels.length;
        ref.read(currentChannelProvider.notifier).switchChannel(channels[nextIndex].id!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
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

    final isMobile = ResponsiveUtils.isMobile(context);

    Widget getMainContent() {
      if (isShowingSettings) {
        return const Expanded(child: SettingsView());
      }
      return const Expanded(child: ChatView());
    }

    // Returns the inner column content (without Expanded).
    Widget buildContentInner() {
      final mainContent = getMainContent();
      if (!isMobile && !isArchive && !isShowingSettings) {
        return Column(children: [mainContent, const InputBar()]);
      }
      return Column(children: [mainContent]);
    }

    // On mobile: wrap only the content area (not sidebar) in a GestureDetector
    // so swipes on notes cycle channels.
    Widget buildContentColumn() {
      final inner = buildContentInner();
      if (isMobile) {
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -_swipeVelocityThreshold) {
                _cycleChannel(1);  // swipe left → next
              } else if (v > _swipeVelocityThreshold) {
                _cycleChannel(-1); // swipe right → previous
              }
            },
            child: inner,
          ),
        );
      }
      return Expanded(child: inner);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF00171F),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F0ED),
        body: SafeArea(
          child: Column(
            children: [
              const OfflineBanner(),
              if (!isShowingSettings) const ChannelTopBar(),
              Expanded(
                child: Row(
                  children: [
                    const Sidebar(),
                    buildContentColumn(),
                    if (showMediaSidebar && !isShowingSettings) const MediaSidebar(),
                  ],
                ),
              ),
              if (isMobile && !isArchive && !isShowingSettings) const InputBar(),
            ],
          ),
        ),
      ),
    );
  }
}
