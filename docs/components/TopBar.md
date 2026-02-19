# TopBar

## Overview

The TopBar is the channel title bar displayed at the top of the screen. It shows the current channel icon and name, and a three-dot menu button giving access to channel actions and global app actions.

**File**: `memoka_flutter/lib/widgets/channel_top_bar.dart`
**Widget**: `ChannelTopBar` (ConsumerWidget)

## Subcomponents

### Bar Container

The outer container spanning full width.

- Background: `core.surface` (`#F6F0ED`)
- Bottom border: 1px `brand.primary` (`#CE2161`)
- Padding: left 16px, top 8px, bottom 8px, right 8px
- Height driven by children (icon button = 40px tall, so bar ≈ 56px with padding)

### Channel Title

Left-aligned icon + text showing the current channel.

- Phosphor icon (20px) + channel name at 20px bold, `core.text` (`#00171F`)
- Shows archive icon + "Archive" when viewing the Archive Crate
- Ellipsis overflow for long names

### Menu Button

Right-aligned three-dot button using `IconButtonStyled`.

- Icon: `PhosphorIcons.dotsThreeCircle()`
- Always visible
- Opens a popup menu on tap

### Popup Menu

Light popup menu anchored to the top-right corner.

- Background: `core.surface` (`#F6F0ED`)
- Text/icons: `core.text` (`#00171F`)

**Channel actions** (shown only when a real channel is active, not Archive):

| Item | Icon | Action |
|------|------|--------|
| Edit Channel | `pencilSimple` | Opens `NewChannelModal` in edit mode |
| Pin / Unpin | `pushPin` / `pushPinSlash` | Toggles pinned state |
| Archive Channel | `archive` | Soft-deletes channel, switches away with toast |
| — divider — | | |

**Global actions** (always shown):

| Item | Icon | Action |
|------|------|--------|
| New Channel | `plusCircle` | Opens `NewChannelModal` in create mode |
| Archive Crate | `archive` | Navigates to the Archive channel (`-1`) |
| Media | `images` | Opens media bottom sheet (mobile/tablet only) |
| Settings | `gear` | Opens settings view |

### Media Bottom Sheet

Draggable modal bottom sheet showing `MediaSidebar`. Mobile/tablet only.

- Initial size: 90% of screen height; min 50%, max 95%
- Background: `core.surface` (`#F6F0ED`), 20px top border radius
- Handle bar: 40×4px rounded bar, `core.text` at 15% opacity
- Contains `MediaSidebar(fixedWidth: false)` for full-width tab content

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
| Menu items    | 14px  | Normal | `#00171F`  |

### Dimensions

| Token      | Value                     | Usage                   |
|------------|---------------------------|-------------------------|
| `_padding` | L: 16, T: 8, B: 8, R: 8 | Bar container padding   |

## Interactions

### Menu Button

- Tap opens a popup menu anchored to the top-right
- Channel actions (Edit/Pin/Archive) only appear when the active channel is a real channel (not Archive Crate)
- Dismissing without selecting does nothing

### Archive Channel

- If archiving the currently viewed channel, automatically switches to the next available channel
- Shows a success toast on completion, error toast on failure

### Media Bottom Sheet

- Draggable to resize between 50–95% of screen height
- Tap outside the sheet to dismiss
- Contains the same `MediaSidebar` widget used on desktop, with `fixedWidth: false`
- Only accessible from the menu on mobile/tablet (when `shouldShowMediaSidebar` returns false)

## State Management

### Providers Watched (reactive)

| Provider                | Type                        | Purpose                      |
|-------------------------|-----------------------------|------------------------------|
| `currentChannelProvider`| `AsyncValue<int>`           | Current channel ID           |
| `channelsProvider`      | `AsyncValue<List<Channel>>` | Channel list for name lookup |

### Providers Read (on interaction)

| Provider                               | Usage                                      |
|----------------------------------------|--------------------------------------------|
| `currentChannelProvider` (read)        | Get active channel ID for menu setup       |
| `channelsProvider` (read/future)       | Channel lookup, post-archive refetch       |
| `channelsProvider.notifier`            | Update (pin) or archive channel            |
| `currentChannelProvider.notifier`      | Switch channel after archive / new channel |
| `editingNoteProvider.notifier`         | Cancel editing on archive crate switch     |
| `settingsVisibilityProvider.notifier`  | Show/hide settings                         |
| `currentSettingsPageProvider.notifier` | Navigate to main settings page             |

## Integration

The `ChannelTopBar` is placed in the `ChatScreen` column above the main `Row` layout. It spans full width across both the sidebar and content area. It is hidden when the settings view is open.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/channel_top_bar.dart` | This component |
| `lib/widgets/icon_button_styled.dart` | Menu button widget |
| `lib/widgets/media_sidebar.dart` | Media content in bottom sheet |
| `lib/widgets/new_channel_modal.dart` | Channel create/edit dialog |
| `lib/screens/chat_screen.dart` | Parent layout |
| `lib/providers/current_channel_provider.dart` | Active channel ID |
| `lib/providers/channels_provider.dart` | Channel list data and mutations |
| `lib/utils/responsive_utils.dart` | Breakpoint detection for Media item |
| `lib/utils/toast_utils.dart` | Archive success/error toasts |
