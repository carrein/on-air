import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:universal_html/html.dart' as html;
import '../widgets/channel_list.dart';
import '../widgets/chat_view.dart';
import '../widgets/note_input.dart';
import '../widgets/offline_banner.dart';
import '../widgets/media_panel.dart';
import '../widgets/settings_view.dart';
import '../widgets/navbar.dart';
import '../widgets/share_intent_dialog.dart';
import '../providers/settings_view_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/channels_provider.dart';
import '../providers/share_intent_provider.dart';
import '../providers/media_panel_visible_provider.dart';
import '../providers/note_selection_provider.dart';
import '../providers/editing_note_provider.dart';
import '../providers/chat_stream_provider.dart';
import '../providers/connection_provider.dart' as conn;
import '../providers/sync_engine_provider.dart';
import '../utils/responsive_utils.dart';

/// Main chat screen with sidebar, chat view, and NoteInput.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  static const _swipeVelocityThreshold = 300.0;

  StreamSubscription<html.Event>? _visibilitySubscription;
  StreamSubscription<html.Event>? _onlineSubscription;

  // Register on web and desktop (not mobile where physical keyboard is absent).
  static bool get _useKeyboardHandler =>
      kIsWeb || ResponsiveUtils.isDesktopPlatform;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // On web, kick reconnect when the tab becomes visible again or when the
    // browser goes online. Both events are more reliable than connectivity_plus
    // alone after a hard refresh in an offline state.
    //
    // visibilitychange always force-reconnects (no disconnected check) because
    // a laptop sleep/wake silently kills the WebSocket TCP connection without
    // sending a close frame — the Dart stream never sees an error so
    // connectionProvider stays "connected" even though the socket is dead.
    if (kIsWeb) {
      _visibilitySubscription = html.document.onVisibilityChange.listen((_) {
        if (html.document.visibilityState == 'visible') {
          ref.invalidate(chatStreamProvider);
        }
      });
      _onlineSubscription = html.window.onOnline.listen((_) {
        _kickReconnectIfNeeded();
      });
    }

    // Eagerly start the sync engine and chat stream so connectivity
    // detection and real-time events work from app launch.
    ref.read(syncEngineProvider);
    ref.read(chatStreamProvider);

    if (_useKeyboardHandler) {
      HardwareKeyboard.instance.addHandler(_handleHardwareKey);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _visibilitySubscription?.cancel();
    _onlineSubscription?.cancel();
    if (_useKeyboardHandler) {
      HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    }
    super.dispose();
  }

  /// Called when the app returns to the foreground (Android/iOS).
  /// Always force-reconnects on resume — the OS may have killed the WebSocket
  /// while the app was backgrounded without sending a close frame.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      ref.invalidate(chatStreamProvider);
    }
  }

  void _kickReconnectIfNeeded() {
    if (ref.read(conn.connectionProvider) ==
        conn.ConnectionState.disconnected) {
      ref.invalidate(chatStreamProvider);
    }
  }

  /// Returns true if a text field currently holds keyboard focus.
  ///
  /// Checks both the focused widget and its immediate child, because Flutter
  /// attaches the FocusNode to the wrapping Focus widget whose child is the
  /// EditableText — so the focused context's widget is Focus, not EditableText.
  bool _isTextFieldFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final ctx = focus.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    bool found = false;
    ctx.visitChildElements((element) {
      if (element.widget is EditableText) found = true;
    });
    return found;
  }

  /// Global hardware key handler for channel cycling and modal dismissal.
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Escape cancels selection mode or edit mode (regardless of text focus).
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final selection = ref.read(noteSelectionProvider);
      if (selection.isNotEmpty) {
        ref.read(noteSelectionProvider.notifier).clear();
        return true;
      }
      final editing = ref.read(editingNoteProvider);
      if (editing != null) {
        ref.read(editingNoteProvider.notifier).cancelEditing();
        return true;
      }
      return false;
    }

    // Don't cycle channels when a dialog/lightbox is open on top.
    if (ModalRoute.of(context)?.isCurrent == false) return false;

    // Arrow-key channel cycling only when no text field is focused.
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
        final nextIndex =
            (currentIndex + delta + channels.length) % channels.length;
        ref
            .read(currentChannelProvider.notifier)
            .switchChannel(channels[nextIndex].id!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final mediaPanelVisible = ref.watch(mediaPanelVisibleProvider);
    final showMediaPanel = isDesktop && mediaPanelVisible;
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
            final channel = channels
                .where((c) => c.id == channelId)
                .firstOrNull;
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
    final isInDetailMode = isShowingSettings || isArchive;

    Widget getMainContent() {
      final key = ValueKey(
        isShowingSettings ? 'settings' : (isArchive ? 'archive' : 'chat'),
      );
      return Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
          child: isShowingSettings
              ? SettingsView(key: key)
              : ChatView(key: key),
        ),
      );
    }

    // Returns the inner column content (without Expanded).
    Widget buildContentInner() {
      final mainContent = getMainContent();
      if (!isMobile && !isArchive && !isShowingSettings) {
        return Column(children: [mainContent, const NoteInput()]);
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
                _cycleChannel(1); // swipe left → next
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
              const Navbar(),
              Expanded(
                child: Row(
                  children: [
                    if (!isInDetailMode) const ChannelList(),
                    buildContentColumn(),
                    if (showMediaPanel && !isInDetailMode) const MediaPanel(),
                  ],
                ),
              ),
              if (isMobile && !isArchive && !isShowingSettings)
                const NoteInput(),
            ],
          ),
        ),
      ),
    );
  }
}
