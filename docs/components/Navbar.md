# Navbar

## Overview

The Navbar is the channel title bar displayed at the top of the screen. It renders in one of three modes depending on app state: **standard** (channel name + menu), **detail** (back button + plain title for settings/archive), or **selection** (bulk-action bar when notes are selected).

**File**: `memoka_flutter/lib/widgets/navbar.dart`
**Widget**: `Navbar` (ConsumerWidget)

## Modes

### Standard Mode

Shown when viewing a real channel (not archive, not settings).

- **Background**: `core.surface` (`#F6F0ED`)
- **Bottom border**: 1px `brand.primary` (`#CE2161`)
- **Padding**: `_paddingStandard` — left 16px, right 8px, top 8px, bottom 8px
- **Layout**: `[channel icon + name (Expanded)]` + `[pin button?]` + `[media panel toggle? desktop only]` + `[menu button]`

#### Channel Title

Left-aligned icon + text showing the current channel.

- Phosphor Fill icon (20px) + channel name at 20px bold, `core.text` (`#00171F`)
- Ellipsis overflow for long names

#### Pin Button

Inline icon button, using `IconButtonStyled`.

- Icon: `PhosphorIcons.pushPin()` when unpinned; `PhosphorIcons.pushPinSlash()` when pinned
- Visible only when a real channel is active (hidden on Archive)
- Tap immediately toggles the pinned state via `channelsProvider.notifier.updateChannel`

#### Media Panel Toggle (desktop only)

Icon button between the pin button and three-dot menu, visible only on desktop.

- Icon: `PhosphorIcons.sidebar()` (rotated 180°) when panel is hidden; `PhosphorIconsFill.sidebar` (rotated 180°) when visible
- Tap toggles `mediaPanelVisibleProvider`; panel defaults to hidden on startup
- Hidden on mobile (media accessible via bottom sheet in the menu instead)

#### Menu Button

Right-aligned button using `IconButtonStyled`.

- Icon: `PhosphorIcons.dotsThreeCircle()`
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
| New Channel | `plusCircle` | Opens `NewChannelModal` in create mode |
| Archive | `archive` | Navigates to the Archive channel (`-1`) |
| Media | `images` | Opens media bottom sheet (mobile/tablet only) |
| Settings | `gear` | Opens settings view |

### Detail Mode

Shown when `isShowingSettings == true` or `currentChannelId == -1` (Archive).

- **Padding**: `_padding` — horizontal 8px, vertical 8px (same as selection mode)
- **Layout**: `[back button]` + `[plain title (Expanded)]`
- **Back button**: `PhosphorIcons.arrowCircleLeft()` via `IconButtonStyled` on the left
- **Title**: plain `Text('Settings')` or `Text('Archive')` — no channel icon
- Pin button and three-dot menu are **hidden** in detail mode
- `_goBack()` logic: hides settings if open, otherwise restores the channel from `previousChannelProvider`, falling back to the first non-system channel

### Selection Mode

Shown when `noteSelectionProvider` is non-empty (user has selected notes). Replaces the other modes entirely.

- **Padding**: `_padding` — horizontal 8px, vertical 8px
- **Layout**: `[xCircle cancel]` + `[N selected text]` (Spacer) + `[archive button]`
- **Cancel**: `IconButtonStyled(icon: PhosphorIcons.xCircle())` — clears selection
- **Count text**: "N selected", 16px, w500, `#00171F`
- **Archive**: `IconButtonStyled(icon: PhosphorIcons.archive())` — archives all selected notes
  - Calls `notesProvider(channelId).notifier.deleteNote(noteId)` for each selected ID
  - Clears selection after completion
  - Shows toast: "N note(s) archived"

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
| Selection count | 16px | w500  | `#00171F`  |
| Menu items    | 14px  | Normal | `#00171F`  |

### Dimensions

| Token              | Value                          | Usage                        |
|--------------------|--------------------------------|------------------------------|
| `_padding`         | H: 8, V: 8                    | Detail mode and selection mode |
| `_paddingStandard` | L: 16, T: 8, B: 8, R: 8      | Standard channel view        |

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
- Only accessible from the menu on mobile/tablet (when `shouldShowMediaPanel` returns false)

## State Management

### Providers Watched (reactive)

| Provider                    | Type                        | Purpose                            |
|-----------------------------|-----------------------------|------------------------------------|
| `currentChannelProvider`    | `AsyncValue<int>`           | Current channel ID                 |
| `channelsProvider`          | `AsyncValue<List<Channel>>` | Channel list for name/icon lookup  |
| `settingsVisibilityProvider`| `bool`                      | Whether settings view is open      |
| `noteSelectionProvider`     | `Set<int>`                  | Selected note IDs (selection mode) |
| `mediaPanelVisibleProvider` | `bool`                      | Media panel toggle state (desktop) |

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
| `lib/widgets/media_panel.dart` | Media content in bottom sheet |
| `lib/widgets/new_channel_modal.dart` | Channel create/edit dialog |
| `lib/screens/chat_screen.dart` | Parent layout |
| `lib/providers/current_channel_provider.dart` | Active channel ID and previous channel |
| `lib/providers/channels_provider.dart` | Channel list data and mutations |
| `lib/providers/note_selection_provider.dart` | Multi-select state |
| `lib/providers/notes_provider.dart` | Note deletion for bulk archive |
| `lib/providers/settings_view_provider.dart` | Settings overlay visibility |
| `lib/utils/responsive_utils.dart` | Breakpoint detection for Media item |
| `lib/utils/toast_utils.dart` | Archive success/error toasts |
