import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/current_channel_provider.dart';
import 'icon_button_styled.dart';
import 'styled_search_field.dart';
import '../providers/global_search_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/scroll_to_note_provider.dart';
import '../providers/search_results_provider.dart';
import '../utils/icon_utils.dart';

/// Inline search bar shown in the center of the navbar on desktop (>1200px).
///
/// Displays a text field with magnifying glass prefix icon. On focus, shows
/// a dropdown overlay with recent searches (when empty) or live search results
/// (debounced 300ms). Results show channel emoji, name, relative time, and a
/// snippet with bold-highlighted match terms.
class SearchBarWidget extends ConsumerStatefulWidget {
  const SearchBarWidget({super.key});

  @override
  ConsumerState<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<SearchBarWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  Timer? _debounce;

  static const _backgroundColor = Color(0xFFFFFDF6);
  static const _borderColor = Color(0xFF3450A3);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (!_overlayController.isShowing) _overlayController.show();
  }

  void _hideOverlay() {
    if (_overlayController.isShowing) _overlayController.hide();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      ref.read(globalSearchProvider.notifier).activate();
      _showOverlay();
    } else {
      // Delay removal so tap on overlay item registers first.
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted) {
          _hideOverlay();
          ref.read(globalSearchProvider.notifier).deactivate();
        }
      });
    }
  }

  void _onTextChanged(String value) {
    ref.read(globalSearchProvider.notifier).setQuery(value);
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      // Keep overlay showing (backdrop visible) while focused
    } else {
      _showOverlay();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        setState(() {});
      });
    }
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(globalSearchProvider.notifier).setQuery('');
    _hideOverlay();
    setState(() {});
  }

  void _selectResult(SearchResult result) async {
    ref.read(globalSearchProvider.notifier).deactivate();
    await ref
        .read(notesProvider(result.channelId).notifier)
        .loadAroundNote(result.noteId);
    ref.read(scrollToNoteProvider.notifier).state = result.noteId;
    ref.read(currentChannelProvider.notifier).switchChannel(result.channelId);
    _controller.clear();
    _focusNode.unfocus();
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    // Clamp dropdown height to available space below the search bar.
    final box = context.findRenderObject() as RenderBox?;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final barBottom = box != null
        ? box.localToGlobal(Offset.zero).dy + box.size.height
        : 0.0;
    final available = screenHeight - barBottom - 16; // 16px margin
    final maxHeight = available.clamp(100.0, 400.0);

    final overlayWidth = box?.size.width ?? 400.0;

    final query = _controller.text.trim();
    // Search bar bottom + navbar vertical padding (8px) + border (1px).
    final backdropTop = barBottom + 9;

    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: backdropTop,
          bottom: 0,
          child: GestureDetector(
            onTap: () {
              _hideOverlay();
              _focusNode.unfocus();
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.6),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              builder: (context, value, _) =>
                  // Exception: uses black instead of core.text for stronger backdrop contrast.
                  ColoredBox(color: Colors.black.withValues(alpha: value)),
            ),
          ),
        ),
        if (query.isNotEmpty)
          Positioned(
            width: overlayWidth,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 44),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.zero,
                color: _backgroundColor,
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: _borderColor,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: _SearchDropdownContent(
                      query: query,
                      onSelectResult: _selectResult,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for external activation (e.g. Cmd+F) and focus the text field.
    ref.listen(globalSearchProvider, (prev, next) {
      if (next.isActive && !(prev?.isActive ?? false) && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _clearSearch();
          _focusNode.unfocus();
        }
      },
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: _buildOverlay,
        child: CompositedTransformTarget(
          link: _layerLink,
          child: SizedBox(
            height: 40,
            child: StyledSearchField(
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'Search...',
              hideBorderUntilActive: true,
              onChanged: _onTextChanged,
              suffixIcon: _controller.text.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButtonStyled(
                        icon: PhosphorIcons.x(),
                        onPressed: _clearSearch,
                        size: IconButtonStyled.xs,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal dropdown content shown in the overlay.
///
/// Uses a [ConsumerStatefulWidget] so that the last successful results are
/// cached in local state. When the query changes (e.g. "test" -> "tests"),
/// the new family-provider instance starts in AsyncLoading, but we keep
/// showing the previous results until the new ones arrive, preventing the
/// dropdown from collapsing and flickering on every keystroke.
class _SearchDropdownContent extends ConsumerStatefulWidget {
  final String query;
  final ValueChanged<SearchResult> onSelectResult;

  const _SearchDropdownContent({
    required this.query,
    required this.onSelectResult,
  });

  @override
  ConsumerState<_SearchDropdownContent> createState() =>
      _SearchDropdownContentState();
}

class _SearchDropdownContentState
    extends ConsumerState<_SearchDropdownContent> {
  static const _textColor = Color(0xFF00171F);
  static const _borderColor = Color(0xFF3450A3);

  /// Cached results from the last successful fetch.
  List<SearchResult>? _lastResults;
  String? _lastQuery;

  @override
  Widget build(BuildContext context) {
    if (widget.query.isEmpty) {
      return const SizedBox.shrink();
    }

    final resultsAsync = ref.watch(searchResultsProvider(widget.query));

    // Clear cache when query changes and isn't a prefix/extension of the last.
    if (_lastQuery != null &&
        !widget.query.startsWith(_lastQuery!) &&
        !_lastQuery!.startsWith(widget.query)) {
      _lastResults = null;
    }

    // Update cache whenever we get new data.
    final freshResults = resultsAsync.value;
    if (freshResults != null) {
      _lastResults = freshResults;
      _lastQuery = widget.query;
    }

    final results = _lastResults;
    final hasError = resultsAsync.hasError;

    if (hasError && results == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Search error',
            style: GoogleFonts.spaceGrotesk(
              color: _textColor.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    if (results == null) {
      // First load ever — show a compact loading indicator instead of collapsing.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          "No results for '${widget.query}'",
          style: GoogleFonts.spaceGrotesk(
            color: _textColor.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final displayResults = results.take(5).toList();
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: [
        ...displayResults.map(
          (r) => _SearchResultTile(
            result: r,
            onTap: () => widget.onSelectResult(r),
          ),
        ),
        if (results.length > 5)
          InkWell(
            onTap: () {
              // Activate full search view
              ref.read(globalSearchProvider.notifier).activate();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View all ${results.length} results',
                    style: GoogleFonts.spaceGrotesk(
                      color: _borderColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIcons.arrowRight(),
                    size: 14,
                    color: _borderColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A single search result row in the dropdown.
class _SearchResultTile extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultTile({required this.result, required this.onTap});

  static const _textColor = Color(0xFF00171F);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(
                  getChannelIcon(result.channelEmoji),
                  color: _textColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.channelName,
                    style: GoogleFonts.spaceGrotesk(
                      color: _textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatRelativeTime(result.createdAt),
                  style: GoogleFonts.spaceGrotesk(
                    color: _textColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.spaceGrotesk(
                  color: _textColor,
                  fontSize: 13,
                ),
                children: parseSnippet(result.snippet),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses a snippet string with `<b>...</b>` tags into a list of [TextSpan].
/// Bold segments use [FontWeight.bold].
List<TextSpan> parseSnippet(String snippet) {
  final spans = <TextSpan>[];
  final regex = RegExp(r'<b>(.*?)</b>');
  int lastEnd = 0;
  for (final match in regex.allMatches(snippet)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(text: snippet.substring(lastEnd, match.start)));
    }
    spans.add(
      TextSpan(
        text: match.group(1),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF3450A3),
        ),
      ),
    );
    lastEnd = match.end;
  }
  if (lastEnd < snippet.length) {
    spans.add(TextSpan(text: snippet.substring(lastEnd)));
  }
  if (spans.isEmpty) {
    spans.add(TextSpan(text: snippet));
  }
  return spans;
}

/// Formats a [DateTime] into a human-readable relative string such as
/// "2h ago", "3d ago", or "Jan 15".
String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 365) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
  return '${date.year}';
}
