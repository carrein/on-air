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
import '../providers/global_search_provider.dart';
import '../providers/chat_stream_provider.dart';
import '../providers/connection_provider.dart' as conn;
import '../providers/sync_engine_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/search_results.dart';
import '../widgets/styled_search_field.dart';

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
  StreamSubscription<html.KeyboardEvent>? _webKeydownSubscription;

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
      // Intercept Cmd+F / Ctrl+F at the DOM level to preventDefault() before
      // the browser opens its own find-in-page. The actual search activation
      // is handled by _handleHardwareKey inside Flutter's event loop.
      _webKeydownSubscription = html.document.onKeyDown.listen((event) {
        if (event.key == 'f' && (event.metaKey || event.ctrlKey)) {
          event.preventDefault();
        }
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
    _webKeydownSubscription?.cancel();
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
  /// When a text field has focus, the FocusNode's context is the Focus widget
  /// that lives *inside* EditableText — so EditableText is an ancestor of
  /// the focus context, not a child.
  bool _isTextFieldFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final ctx = focus.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Global hardware key handler for channel cycling and modal dismissal.
  bool _handleHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // Cmd+F / Ctrl+F activates global search.
    if (event.logicalKey == LogicalKeyboardKey.keyF &&
        (HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed)) {
      // Dismiss any open overlays (lightbox, GIF picker, etc.)
      if (ModalRoute.of(context)?.isCurrent == false) {
        Navigator.of(context).pop();
      }
      ref.read(globalSearchProvider.notifier).activate();
      return true;
    }

    // Escape cancels search, selection mode, or edit mode.
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final searchState = ref.read(globalSearchProvider);
      if (searchState.isActive) {
        ref.read(globalSearchProvider.notifier).deactivate();
        return true;
      }
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

  /// Cycles to the next (+1) or previous (-1) channel in the visual order.
  ///
  /// Builds the same pinned-then-unpinned ordering that [ChannelList] renders
  /// so arrow keys / swipe gestures match what the user sees.
  void _cycleChannel(int delta) {
    final channelsAsync = ref.read(channelsProvider);
    final currentAsync = ref.read(currentChannelProvider);

    channelsAsync.whenData((channels) {
      currentAsync.whenData((currentId) {
        // Don't cycle when in Archive
        if (currentId == -1) return;

        // Match ChannelList visual order: pinned first, then unpinned,
        // excluding system channels. Explicitly sort within each group.
        final regular = channels.where((c) => !c.isSystemChannel).toList();
        final pinned = regular.where((c) => c.pinned).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        final unpinned = regular.where((c) => !c.pinned).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        final ordered = [...pinned, ...unpinned];

        if (ordered.length <= 1) return;

        final currentIndex = ordered.indexWhere((c) => c.id == currentId);
        if (currentIndex == -1) return;

        ref.read(channelSwitchDirectionProvider.notifier).state = delta;
        final nextIndex =
            (currentIndex + delta + ordered.length) % ordered.length;
        ref
            .read(currentChannelProvider.notifier)
            .switchChannel(ordered[nextIndex].id!);
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
    final searchState = ref.watch(globalSearchProvider);
    final isMobileSearch = isMobile && searchState.isActive;

    Widget getMainContent() {
      // Mobile search mode: replace chat view with search results.
      if (isMobileSearch) {
        return const Expanded(child: SearchResults());
      }
      return Expanded(
        child: Stack(
          children: [
            // ChatView stays mounted so notesProvider stays alive
            Offstage(
              offstage: isShowingSettings,
              child: const ChatView(),
            ),
            if (isShowingSettings)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: const SettingsView(),
              ),
          ],
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

    final isInDetailOrSearch = isInDetailMode || isMobileSearch;

    return PopScope(
      canPop: !isInDetailOrSearch,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (isMobileSearch) {
          ref.read(globalSearchProvider.notifier).deactivate();
        } else if (isShowingSettings) {
          ref.read(settingsVisibilityProvider.notifier).hide();
        } else if (isArchive) {
          final previousId = ref.read(previousChannelProvider);
          if (previousId != null) {
            ref.read(currentChannelProvider.notifier).switchChannel(previousId);
            ref.read(previousChannelProvider.notifier).state = null;
          } else {
            final chs = ref.read(channelsProvider).value ?? [];
            final first = chs.where((c) => !c.isSystemChannel).firstOrNull;
            if (first != null) {
              ref
                  .read(currentChannelProvider.notifier)
                  .switchChannel(first.id!);
            }
          }
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF00171F),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
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
                  isMobileSearch
                      ? const _MobileSearchInput()
                      : const NoteInput(),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search text field shown at the bottom of mobile in search mode,
/// replacing the normal NoteInput. Debounces input by 300ms.
class _MobileSearchInput extends ConsumerStatefulWidget {
  const _MobileSearchInput();

  @override
  ConsumerState<_MobileSearchInput> createState() => _MobileSearchInputState();
}

class _MobileSearchInputState extends ConsumerState<_MobileSearchInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  static const _backgroundColor = Color(0xFFF6F0ED);
  static const _borderColor = Color(0xFFCE2161);
  static const _textColor = Color(0xFF00171F);

  @override
  void initState() {
    super.initState();
    // Restore existing query if re-mounted.
    final current = ref.read(globalSearchProvider).query;
    if (current.isNotEmpty) {
      _controller.text = current;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(globalSearchProvider.notifier).setQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: StyledSearchField(
        controller: _controller,
        focusNode: _focusNode,
        hintText: 'Search notes...',
        onChanged: (value) {
          setState(() {});
          _onChanged(value);
        },
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 18,
                  color: _textColor,
                ),
                onPressed: () {
                  _controller.clear();
                  ref.read(globalSearchProvider.notifier).setQuery('');
                  setState(() {});
                },
              )
            : null,
      ),
    );
  }
}
