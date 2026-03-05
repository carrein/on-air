# Navbar

## Overview

The Navbar is the channel title bar displayed at the top of the screen. It renders in one of three modes depending on app state: **standard** (channel name + menu), **detail** (back button + plain title for settings/archive), or **selection** (bulk-action bar when notes are selected).

**File**: `memoka_flutter/lib/widgets/navbar.dart`
**Widget**: `Navbar` (ConsumerStatefulWidget)

## Modes

### Standard Mode

Shown when viewing a real channel (not archive, not settings).

- **Background**: `core.surface` (`#F6F0ED`)
- **Bottom border**: 1px `brand.primary` (`#CE2161`)
- **Padding**: `_paddingStandard` — left 16px, right 8px, vertical 8px

#### Non-Mobile Layout (>= 600px): Three-Column Search Bar

```
[ConstrainedBox 224px: title] [Expanded: SearchBarWidget] [16px gap] [SizedBox: actions]
```

| Column | Width | Contents |
|--------|-------|----------|
| Title | `maxWidth: 224px` | Channel icon + name |
| Search | `Expanded` | `SearchBarWidget` (inline search bar with dropdown overlay) |
| Gap | `16px` | Fixed spacer |
| Actions | `316px` or shrink-to-fit | Pin, media panel toggle, new channel, sync indicator, menu |

**Width alignment**: The 224px title width equals the sidebar (240px) minus navbar left padding (16px), aligning the search bar's left edge with the sidebar/content boundary. The 316px actions width (applied when `isDesktop` >= 1200px AND `mediaPanelVisible`) aligns the actions block with the 340px media panel below. When the media panel is hidden or on tablet widths (600-1199px), the actions SizedBox shrinks to fit (`width: null`, `MainAxisSize.min`).

#### Mobile Layout (< 600px)

- **Layout**: `[channel icon + name (Expanded)]` + `[search icon]` + `[pin button?]` + `[media panel toggle]` + `[new channel button]` + `[sync indicator]` + `[menu button]`
- Search icon (`PhosphorIcons.magnifyingGlass()`) activates `globalSearchProvider`, triggering full-screen search mode in `chat_screen.dart`

#### Channel Title

Left-aligned icon + text showing the current channel.

- Phosphor Fill icon (22px) + channel name at 20px bold, `core.text` (`#00171F`)
- Ellipsis overflow for long names
- **Tap icon**: opens `IconPicker` to change channel icon (all platforms)
- **Tap name**: enters inline rename mode — replaces text with a borderless `TextField` pre-filled and fully selected (all platforms)
  - Submit on Enter or tap outside to commit
  - Escape to cancel (desktop/web)
  - `MouseRegion` with click cursor on desktop/web platforms
- Caches last known channel (`_lastChannel`) to prevent flicker during provider transitions

#### Sync Indicator

Leftmost item in the action row. Renders `SyncIndicator` widget.

- **Hidden** when connected with zero dirty entities, or during initial `connecting` phase
- **Offline**: rounded-square badge with dirty count (white text on `brand.primary` `#CE2161`, 2px border radius)
- **Syncing** (online with pending): spinning `PhosphorIcons.spinnerGap()` icon in `brand.primary`

#### Pin Button

Inline icon button, using `IconButtonStyled`.

- Icon: `PhosphorIcons.pushPin()` when unpinned; `PhosphorIcons.pushPinSlash()` when pinned
- Visible only when a real channel is active (hidden on Archive)
- Tap immediately toggles the pinned state via `channelsProvider.notifier.updateChannel`

#### Media Panel Toggle

Icon button between the pin button and new channel button, always visible.

- Icon: `PhosphorIcons.sidebar()` (rotated 180°) when panel is hidden; `PhosphorIconsFill.sidebar` (rotated 180°) when visible
- **Desktop**: tap toggles `mediaPanelVisibleProvider` sidebar panel; defaults to hidden on startup
- **Mobile/tablet**: tap opens media bottom sheet (see below)

#### New Channel Button

Icon button to the left of the menu button.

- Icon: `PhosphorIcons.plusSquare()`
- Opens `NewChannelModal` in create mode; on confirm, switches to the new channel

#### Menu Button

Right-aligned button using `IconButtonStyled`.

- Icon: `PhosphorIcons.dotsThreeOutline()`
- Opens a popup menu on tap

#### Popup Menu

Light popup menu anchored to the top-right corner.

- Background: `core.surface` (`#F6F0ED`)
- Text/icons: `core.text` (`#00171F`)

**Channel actions** (shown only when a real channel is active):

| Item | Icon | Action |
|------|------|--------|
| Edit Channel | `pencilSimple` | Opens `NewChannelModal` in edit mode |
| Archive Channel | `archive` | Soft-deletes channel, switches away with toast |
| — divider — | | |

**Global actions** (always shown):

| Item | Icon | Action |
|------|------|--------|
| Archive | `archive` | Navigates to the Archive channel (`-1`) |
| Settings | `gear` | Opens settings view |

### Detail Mode

Shown when `isShowingSettings == true` or `currentChannelId == -1` (Archive).

- **Padding**: `_paddingDetail` — left 8px, right 16px, vertical 8px
- **Layout**: `[back button]` + `[plain title (Expanded)]` + `[retention dropdown (archive only)]`
- **Back button**: `PhosphorIcons.arrowCircleLeft()` via `IconButtonStyled` on the left
- **Title**: plain `Text('Settings')` or `Text('Archive')` — no channel icon
- Pin button and three-dot menu are **hidden** in detail mode
- `_goBack()` logic: hides settings if open, otherwise restores the channel from `previousChannelProvider`, falling back to the first non-system channel

#### Archive Retention Dropdown

Visible only in Archive detail mode (`isArchive == true`). Positioned on the right side of the navbar.

- Widget: `DropdownButton<int>` wrapped in `DropdownButtonHideUnderline`
- Options: Keep Forever (0), 30 Days, 60 Days, 90 Days
- Font: Space Grotesk 13px, w500, `_textColor` (`#00171F`) — must use `GoogleFonts.spaceGrotesk()` explicitly since `DropdownButton.style` replaces (not merges) the theme's `DefaultTextStyle`
- Dropdown icon: `Icons.arrow_drop_down`, 18px
- Dropdown background: `_backgroundColor` (`#F6F0ED`)
- `isDense: true`
- Watches `archiveRetentionProvider`, calls `updateRetention(days)` on change
- See `docs/ArchiveRetention.md` for full retention/purge details

### Selection Mode

Shown when `noteSelectionProvider` is non-empty (user has selected notes). Replaces the other modes entirely.

- **Padding**: `_padding` — horizontal 16px, vertical 8px
- **Layout**: `[N selected text (Expanded)]` + `[archive button]` + `[4px]` + `[xCircle cancel]`
- **Count text**: "**N** selected" — the number is bold (`FontWeight.w700`), 16px, `#00171F`
- **Archive**: `IconButtonStyled(icon: PhosphorIcons.archive())` — archives all selected notes
  - Calls `notesProvider(channelId).notifier.deleteNote(noteId)` for each selected ID
  - Clears selection after completion
  - Shows toast: "N note(s) archived"
- **Cancel**: `IconButtonStyled(icon: PhosphorIcons.xCircle())` — clears selection; sits 4px to the right of the archive button

**Keyboard shortcut**: pressing `Escape` on desktop/web clears selection (same as tapping cancel).

### Media Bottom Sheet

Draggable modal bottom sheet showing `MediaPanel`. Mobile/tablet only.

- Initial size: 90% of screen height; min 50%, max 95%
- Background: `core.surface` (`#F6F0ED`), 20px top border radius
- Handle bar: 40×4px rounded bar, `core.text` at 15% opacity
- Contains `MediaPanel(fixedWidth: false)` for full-width tab content

## Styling

### Color Palette

| Token              | Value     | Usage                              |
|--------------------|-----------|------------------------------------|
| `_backgroundColor` | `#F6F0ED` | Bar background, popup, bottom sheet|
| `_borderColor`     | `#CE2161` | Bottom border                      |
| `_textColor`       | `#00171F` | Title text, menu items, icons      |

### Typography

| Element       | Size  | Weight | Color      |
|---------------|-------|--------|------------|
| Channel title | 20px  | Bold   | `#00171F`  |
| Selection count | 16px | w700 (number), w500 (label) | `#00171F`  |
| Menu items    | 14px  | Normal | `#00171F`  |

### Dimensions

| Token              | Value                          | Usage                        |
|--------------------|--------------------------------|------------------------------|
| `_padding` | H: 16, V: 8 | Selection mode |
| `_paddingDetail` | L: 8, R: 16, V: 8 | Detail mode (settings/archive) |
| `_paddingStandard` | L: 16, R: 8, V: 8 | Standard mode |

## Interactions

### Menu Button

- Tap opens a popup menu anchored to the top-right
- Channel actions (Edit/Archive) only appear when the active channel is a real channel (not Archive)
- Dismissing without selecting does nothing

### Archive Channel

- If archiving the currently viewed channel, automatically switches to the next available channel
- Shows a success toast on completion, error toast on failure

### Back Navigation (Detail Mode)

- If settings is showing: hides settings overlay
- If archive is showing: restores the channel recorded in `previousChannelProvider`, or falls back to the first non-system channel

### Media Bottom Sheet

- Draggable to resize between 50–95% of screen height
- Tap outside the sheet to dismiss
- Contains the same `MediaPanel` widget used on desktop, with `fixedWidth: false`
- On mobile/tablet, opened via the media panel toggle button in the navbar

## State Management

### Providers Watched (reactive)

| Provider                    | Type                        | Purpose                            |
|-----------------------------|-----------------------------|------------------------------------|
| `currentChannelProvider`    | `AsyncValue<int>`           | Current channel ID                 |
| `channelsProvider`          | `AsyncValue<List<Channel>>` | Channel list for name/icon lookup  |
| `settingsVisibilityProvider`| `bool`                      | Whether settings view is open      |
| `noteSelectionProvider`     | `Set<int>`                  | Selected note IDs (selection mode) |
| `mediaPanelVisibleProvider` | `bool`                      | Media panel toggle state (desktop) |
| `archiveRetentionProvider` | `AsyncValue<int>`           | Retention setting for dropdown (archive only) |
| `globalSearchProvider`     | `GlobalSearchState`         | Search activation (mobile search icon) |

### Providers Read (on interaction)

| Provider                               | Usage                                          |
|----------------------------------------|------------------------------------------------|
| `currentChannelProvider` (read)        | Get active channel ID for menu setup           |
| `channelsProvider` (read/future)       | Channel lookup, post-archive refetch           |
| `channelsProvider.notifier`            | Update (pin) or archive channel                |
| `currentChannelProvider.notifier`      | Switch channel after archive / new channel     |
| `previousChannelProvider`             | Restore channel when leaving archive view       |
| `previousChannelProvider.notifier`    | Clear after back navigation                     |
| `editingNoteProvider.notifier`         | Cancel editing on archive switch               |
| `settingsVisibilityProvider.notifier`  | Show/hide settings                             |
| `currentSettingsPageProvider.notifier` | Navigate to main settings page                 |
| `noteSelectionProvider.notifier`       | Clear selection, or select all                 |
| `notesProvider(channelId).notifier`    | Delete (archive) notes in bulk                 |

## Integration

The `Navbar` is placed in the `ChatScreen` column above the main `Row` layout. It spans full width and is **always visible** — including when settings or archive is open. The sidebar and media panel are hidden in detail mode; the Navbar remains.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/navbar.dart` | This component |
| `lib/widgets/icon_button_styled.dart` | All icon buttons |
| `lib/widgets/icon_picker.dart` | Icon selection dialog for channel icon |
| `lib/widgets/sync_indicator.dart` | Offline/syncing indicator |
| `lib/widgets/media_panel.dart` | Media content in bottom sheet |
| `lib/widgets/new_channel_modal.dart` | Channel create/edit dialog |
| `lib/screens/chat_screen.dart` | Parent layout |
| `lib/providers/current_channel_provider.dart` | Active channel ID and previous channel |
| `lib/providers/channels_provider.dart` | Channel list data and mutations |
| `lib/providers/note_selection_provider.dart` | Multi-select state |
| `lib/providers/notes_provider.dart` | Note deletion for bulk archive |
| `lib/providers/settings_view_provider.dart` | Settings overlay visibility |
| `lib/utils/responsive_utils.dart` | Breakpoint detection (mobile/tablet/desktop) |
| `lib/providers/archive_retention_provider.dart` | Retention setting for archive dropdown |
| `lib/providers/global_search_provider.dart` | Search activation state (mobile search icon) |
| `lib/widgets/search_bar_widget.dart` | Inline search bar (non-mobile, standard mode) |
| `lib/utils/toast_utils.dart` | Archive success/error toasts |
| `docs/ArchiveRetention.md` | Archive retention/purge documentation |
| `docs/Search.md` | Search backend + navbar layout documentation |
| `docs/components/Search.md` | Search UI component documentation |
