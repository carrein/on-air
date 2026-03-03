import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/current_channel_provider.dart';
import '../providers/global_search_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/recent_searches_provider.dart';
import '../providers/scroll_to_note_provider.dart';
import '../providers/search_results_provider.dart';
import '../utils/icon_utils.dart';
import 'search_bar_widget.dart' show parseSnippet, formatRelativeTime;

/// Full search results list widget used in mobile search mode and the
/// "View all" expanded results on web.
///
/// Displays recent searches when the query is empty, or a scrollable list
/// of matching notes grouped by relevance. Each result shows the channel
/// emoji and name, relative timestamp, and a content snippet with bold
/// highlighted match terms.
class SearchResults extends ConsumerWidget {
  const SearchResults({super.key});

  static const _textColor = Color(0xFF00171F);
  static const _borderColor = Color(0xFFCE2161);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(globalSearchProvider);
    final query = searchState.query.trim();

    if (query.isEmpty) {
      return _buildRecentSearches(context, ref);
    }

    final resultsAsync = ref.watch(searchResultsProvider(query));

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIcons.magnifyingGlass(),
                  size: 48,
                  color: _textColor.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 12),
                Text(
                  "No results for '$query'",
                  style: GoogleFonts.spaceGrotesk(
                    color: _textColor.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: results.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: _textColor.withValues(alpha: 0.08),
          ),
          itemBuilder: (context, index) {
            return _SearchResultTile(
              result: results[index],
              query: query,
            );
          },
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.warning(),
              size: 48,
              color: _textColor.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Search error',
              style: GoogleFonts.spaceGrotesk(
                color: _textColor.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    if (recent.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.magnifyingGlass(),
              size: 48,
              color: _textColor.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              'Start typing to search notes',
              style: GoogleFonts.spaceGrotesk(
                color: _textColor.withValues(alpha: 0.5),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent searches',
              style: GoogleFonts.spaceGrotesk(
                color: _textColor.withValues(alpha: 0.5),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () => ref.read(recentSearchesProvider.notifier).clear(),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'Clear all',
                  style: GoogleFonts.spaceGrotesk(
                    color: _borderColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recent.map(
          (q) => InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(globalSearchProvider.notifier).setQuery(q);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.clockCounterClockwise(),
                    size: 18,
                    color: _textColor.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      q,
                      style: GoogleFonts.spaceGrotesk(
                        color: _textColor,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    PhosphorIcons.arrowUpLeft(),
                    size: 16,
                    color: _textColor.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single search result tile for the full results list.
class _SearchResultTile extends ConsumerWidget {
  final SearchResult result;
  final String query;

  const _SearchResultTile({
    required this.result,
    required this.query,
  });

  static const _textColor = Color(0xFF00171F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _onTap(ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PhosphorIcon(
                  getChannelIcon(result.channelEmoji),
                  color: _textColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.channelName,
                    style: GoogleFonts.spaceGrotesk(
                      color: _textColor.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatRelativeTime(result.createdAt),
                  style: GoogleFonts.spaceGrotesk(
                    color: _textColor.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.spaceGrotesk(
                  color: _textColor,
                  fontSize: 14,
                  height: 1.4,
                ),
                children: parseSnippet(result.snippet),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(WidgetRef ref) {
    final q = query.trim();
    if (q.isNotEmpty) {
      ref.read(recentSearchesProvider.notifier).add(q);
    }
    ref.read(globalSearchProvider.notifier).deactivate();
    ref.read(currentChannelProvider.notifier).switchChannel(result.channelId);
    // Load notes centered around the target so the chat view can scroll to it.
    ref
        .read(notesProvider(result.channelId).notifier)
        .loadAroundNote(result.noteId);
    ref.read(scrollToNoteProvider.notifier).state = result.noteId;
  }
}
