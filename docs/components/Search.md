# Search

## Overview

Global search across all notes with hybrid FTS + trigram matching. Two UI modes: an inline search bar with dropdown overlay on desktop (>1200px), and a full-screen search view on mobile. Results show channel context, relative timestamps, and content snippets with bold-highlighted match terms. Tapping a result navigates to the note's channel and scrolls to it in context.

**Files**:
- `memoka_flutter/lib/widgets/search_bar_widget.dart` (desktop inline search bar + dropdown)
- `memoka_flutter/lib/widgets/search_results.dart` (full results list for mobile + "View all")
- `memoka_flutter/lib/providers/global_search_provider.dart` (search state: active, query, loading)
- `memoka_flutter/lib/providers/search_results_provider.dart` (server call, debounced)
- `memoka_flutter/lib/providers/recent_searches_provider.dart` (persisted history)
- `memoka_flutter/lib/providers/scroll_to_note_provider.dart` (jump-to-note trigger)
- `memoka_flutter/lib/widgets/navbar.dart` (search bar placement + mobile search icon)
- `memoka_flutter/lib/screens/chat_screen.dart` (mobile search mode, keyboard shortcuts)

---

## Activation

| Platform | Trigger | Behavior |
|----------|---------|----------|
| Desktop  | Click the search bar in the navbar | Focus shows dropdown overlay |
| Desktop  | `Cmd+F` / `Ctrl+F` | Activates `globalSearchProvider`, focuses search bar |
| Mobile   | Tap magnifying glass icon in navbar | Navbar transforms to search mode; chat view replaced by `SearchResults` |

**Deactivation**: Escape key, back button (Android), or tapping away from the search bar (desktop).

---

## Desktop: SearchBarWidget

**Widget**: `SearchBarWidget` (ConsumerStatefulWidget)
**Location**: Navbar center area, visible when `isDesktop && !isInDetailMode`

### Search Input

- `SizedBox(width: 320, height: 36)`
- `TextField` with `OutlineInputBorder`, `borderRadius: 8`
- Font: Space Grotesk 14px, `_textColor` (`#00171F`)
- Fill: `Colors.white` at 50% alpha
- Hint: "Search..." at 40% alpha
- Prefix: `PhosphorIcons.magnifyingGlass()`, 18px, 40% alpha
- Suffix: `PhosphorIcons.x()`, 16px — shown only when text is non-empty, clears on tap
- Focused border: `_borderColor` (`#CE2161`), 1px
- Unfocused border: none

### Dropdown Overlay

Shown on focus via `OverlayEntry` + `CompositedTransformFollower`.

- Width: 400px, offset: `(-40, 42)` from the search bar
- Max height: 400px
- Background: `_backgroundColor` (`#F6F0ED`)
- Border: `_borderColor` at 20% alpha, 1px
- Border radius: 12
- Elevation: 8
- Dismissed 200ms after focus loss (delay lets tap events on overlay items register first)

### Dropdown States

**Empty query** — shows recent searches:
- Header: "Recent searches" (Space Grotesk 13px, w500, 50% alpha)
- Each item: `PhosphorIcons.clockCounterClockwise()` 16px + query text (14px)
- Padding: horizontal 16, vertical 10
- Tap fills the search bar with that query

**With query** — shows live results (debounced 300ms):
- Top 5 results displayed as `_SearchResultTile`
- If more than 5: "View all N results" link at bottom (Space Grotesk 13px, w600, `_borderColor` + arrow icon)
- Loading: `CircularProgressIndicator(strokeWidth: 2)`, 20x20, centered
- No results: "No results for 'query'" (14px, 50% alpha)
- Error: "Search error" (14px, 50% alpha)

---

## Mobile: Full-Screen Search

When `isMobile && searchState.isActive`:

### Navbar Transformation

- Back button (`PhosphorIcons.arrowCircleLeft()`) replaces sidebar toggle
- Title shows "Search" (Space Grotesk 20px, w600)
- Below the navbar: `_MobileSearchInput` text field with auto-focus, 300ms debounce
- Channel list sidebar hidden

### _MobileSearchInput

- `ConsumerStatefulWidget` in `chat_screen.dart`
- Auto-focuses on mount, restores existing query if re-mounted
- Same color scheme as desktop (`_backgroundColor`, `_textColor`, `_borderColor`)
- Font: Space Grotesk 14px
- Clear button: `Icons.clear` 18px
- Focused border: `_borderColor` 1px
- Border radius: 8

### SearchResults Widget

- Replaces `ChatView` via `Expanded(child: SearchResults())`
- `ConsumerWidget` rendering a `ListView.separated`
- Separator: `Divider(height: 1)` at 8% alpha
- Padding: horizontal 16, vertical 12

**Empty query** — recent searches:
- Header row: "Recent searches" + "Clear all" link (`_borderColor`, w500)
- Each item: clock icon (18px) + query text (14px) + `PhosphorIcons.arrowUpLeft()` (16px, 30% alpha)
- Tap sets the query in `globalSearchProvider`

**Empty state** (no recent searches):
- `PhosphorIcons.magnifyingGlass()` 48px at 15% alpha + "Start typing to search notes" (15px, 50% alpha)

**No results**: magnifying glass icon + "No results for 'query'" (15px)

**Error**: `PhosphorIcons.warning()` 48px + "Search error" (15px)

---

## Search Result Tile

Shared layout between dropdown (`_SearchResultTile` in `search_bar_widget.dart`) and full list (`_SearchResultTile` in `search_results.dart`). Slight size differences between the two.

### Layout

```
[channel_icon 14-16px] [channel_name 12-13px w500 60%alpha]  [relative_time 12px 40%alpha]
[snippet 13-14px, max 2-3 lines, bold highlights]
```

- Padding: horizontal 4-16, vertical 10-12
- Snippet: `RichText` with `parseSnippet()` — parses `<b>...</b>` tags from server into bold `TextSpan`s
- Channel icon: `getChannelIcon(result.channelEmoji)` via `icon_utils.dart`
- Timestamp: `formatRelativeTime()` — "now", "2m ago", "3h ago", "5d ago", "Jan 15", "2025"
- InkWell with `borderRadius: 8` (full list) or no radius (dropdown)

### Tap Action

1. Save query to `recentSearchesProvider`
2. Deactivate search (`globalSearchProvider.deactivate()`)
3. Switch channel (`currentChannelProvider.switchChannel(result.channelId)`)
4. Load surrounding notes (`notesProvider(channelId).loadAroundNote(result.noteId)`)
5. Trigger scroll (`scrollToNoteProvider.state = result.noteId`)

---

## Jump-to-Context

### scrollToNoteProvider

`StateProvider<int?>` — set to a note ID to trigger `ChatView` to scroll to that note. Resets to `null` after scrolling via `Future.microtask`.

### loadAroundNote(noteId)

Method on `Notes` notifier. Calls `client.search.getNotesAroundId(channelId, noteId, limit: 25)`. Replaces the current notes state with ~25 notes surrounding the target, then `ChatView` finds the target index and scrolls to it.

---

## State Management

### Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `globalSearchProvider` | `GlobalSearchState` (Notifier) | Active flag, query string, loading flag |
| `searchResultsProvider(query)` | `AsyncValue<List<SearchResult>>` | Server results, auto-disposed per query |
| `recentSearchesProvider` | `List<String>` (Notifier) | Last 5 searches, persisted to SharedPreferences |
| `scrollToNoteProvider` | `StateProvider<int?>` | Triggers ChatView scroll-to-note |

### GlobalSearchState

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `isActive` | `bool` | `false` | Whether search UI is shown |
| `query` | `String` | `''` | Current search query |
| `isLoading` | `bool` | `false` | Loading indicator flag |

Methods: `activate()`, `deactivate()` (resets to defaults), `setQuery(query)`, `setLoading(bool)`.

### RecentSearches

- Persisted to `SharedPreferences` under key `recent_searches`
- Max 5 items, most recent first
- `add(query)`: prepend, deduplicate, trim to 5
- `clear()`: remove all

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+F` / `Ctrl+F` | Activate search |
| `Escape` | Deactivate search (checked before selection mode and edit mode) |

---

## Related Files

| File | Purpose |
|------|---------|
| `memoka_flutter/lib/widgets/search_bar_widget.dart` | Desktop search bar + dropdown overlay |
| `memoka_flutter/lib/widgets/search_results.dart` | Full results list (mobile + expanded) |
| `memoka_flutter/lib/providers/global_search_provider.dart` | Search activation/query state |
| `memoka_flutter/lib/providers/search_results_provider.dart` | Async server call |
| `memoka_flutter/lib/providers/recent_searches_provider.dart` | Persisted search history |
| `memoka_flutter/lib/providers/scroll_to_note_provider.dart` | Jump-to-note trigger |
| `memoka_flutter/lib/screens/chat_screen.dart` | Mobile search mode + keyboard shortcuts |
| `memoka_flutter/lib/widgets/navbar.dart` | Search bar placement + mobile icon |
| `memoka_flutter/lib/widgets/chat_view.dart` | Scroll-to-note listener |
| `memoka_flutter/lib/providers/notes_provider.dart` | `loadAroundNote()` for context loading |
| `docs/Search.md` | Backend architecture + Serverpod constraints |
