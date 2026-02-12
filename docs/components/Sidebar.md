# Sidebar

## Overview

The Sidebar is the primary navigation component of the Memoka app. It displays a fixed-width panel on the left side of the screen containing the app logo, a scrollable list of channels, and action buttons for creating channels and accessing settings.

**File**: `memoka_flutter/lib/widgets/sidebar.dart`
**Widget**: `Sidebar` (ConsumerStatefulWidget)
**State**: `_SidebarState`

## Subcomponents

### Logo Header

Top section displaying the app icon and name.

- App logo SVG icon (44x44px) paired with "memoka" text in Combo font
- Horizontal padding: 20px, vertical padding: 14px
- Text gap from icon: 16px
- Font size: 32px, normal weight, white text
- Separated from channel list by a 1px pink divider

### Channel List

Scrollable list of all channels, sorted with pinned channels first.

- Uses `ReorderableListView` inside a `Stack` (for fade gradients)
- **Drag-to-reorder**: Long-press and drag to reorder channels within their group
  - Pinned channels can only be reordered among pinned channels
  - Unpinned channels can only be reordered among unpinned channels
  - Order is persisted via `sortOrder` field and `reorderChannels` endpoint
- Scrollbar hidden via `ScrollConfiguration`
- A 1px pink divider appears between the last pinned channel and first unpinned channel
- Fade gradients (60px tall) appear at top/bottom edges when content is scrollable beyond view
- Fade gradients use the sidebar background color transitioning to transparent

### Channel Item

Individual channel row within the channel list.

- **Emoji container**: 40x40px centered box with emoji at 18px font size
- **Text column**: Channel name (14px, white, normal weight) with optional preview line below
- **Preview text**: 10px, white at 70% opacity, single line with ellipsis overflow
- **Pin icon**: Star SVG (20px) rotated 15 degrees, shown after a 12px gap for pinned channels
- **Padding**: left 8px, right 18px, top/bottom 10px
- **Gap** between emoji and text: 8px
- **Selected state**: Background changes to selected color (pink)
- **Interactions**: tap to select, right-click or long-press for context menu

### New Channel Button

Bottom action button for creating a new channel.

- SVG icon (28x28px) + "New Channel" text in Combo font (16px, white)
- Padding: left 16px, right 20px, top/bottom 16px
- Gap between icon and text: 16px
- Opens channel creation dialog on tap

### Settings Button

Bottom action button for opening the settings view.

- SVG icon (28x28px) + "Settings" text in Combo font (16px, white)
- Same padding and gap as New Channel button
- Opens settings overlay on tap

### Dialogs (Create/Edit Channel)

Channel creation and editing are handled by the extracted `NewChannelModal` widget. See `docs/components/NewChannelModal.md` for full specification.

- **Create**: Opens `NewChannelModal` in create mode. Creates channel and auto-switches to it.
- **Edit**: Opens `NewChannelModal` in edit mode, pre-populated with existing channel name and emoji.

### Context Menu

Right-click or long-press menu on channel items with three options:

- **Edit**: Opens `NewChannelModal` in edit mode
- **Pin/Unpin**: Toggles channel pin state
- **Archive**: Soft-deletes channel to Archive Crate with success/error toast

## Styling

### Color Palette

| Token               | Value       | Usage                              |
|---------------------|-------------|-------------------------------------|
| `_backgroundColor`  | `#00171F`   | Sidebar background, fade gradients |
| `_selectedColor`    | `#CE2161`   | Selected channel item background    |
| `_dividerColor`     | `#FF52A1`   | Horizontal dividers (logo, pin/unpin boundary, buttons) |
| `_textColor`        | `#FFFFFF`   | All text (channel names, buttons, logo) |
| `_previewTextAlpha` | `0.7`       | Preview text opacity                |

### Typography

| Element          | Font         | Size  | Weight  | Color               |
|------------------|-------------|-------|---------|----------------------|
| Logo text        | Combo        | 32px  | Normal  | White                |
| Channel name     | System       | 14px  | Normal  | White                |
| Preview text     | System       | 10px  | Normal  | White @ 70% opacity  |
| Button text      | Combo        | 16px  | Normal  | White                |

### Dimensions

| Token                  | Value                                | Usage                    |
|------------------------|--------------------------------------|--------------------------|
| `_sidebarWidth`        | 240px                                | Overall sidebar width    |
| `_logoIconSize`        | 44px                                 | Logo SVG width/height    |
| `_logoPadding`         | H: 20px, V: 14px                    | Logo container padding   |
| `_logoTextGap`         | 16px                                 | Gap between logo and text|
| `_emojiContainerSize`  | 40px                                 | Emoji box width/height   |
| `_channelItemPadding`  | L: 8, R: 18, T: 10, B: 10          | Channel item padding     |
| `_emojiToTextGap`      | 8px                                  | Gap emoji to text column |
| `_pinIconSize`         | 20px                                 | Pin star SVG size        |
| `_pinIconRotation`     | 15 degrees (0.2618 rad)              | Star icon tilt           |
| `_pinIconGap`          | 12px                                 | Gap before pin icon      |
| `_fadeGradientHeight`  | 60px                                 | Top/bottom scroll fades  |
| `_dividerHeight`       | 1px                                  | Horizontal divider lines |
| `_buttonPadding`       | L: 16, R: 20, T: 16, B: 16          | Action button padding    |
| `_buttonIconSize`      | 28px                                 | Button SVG icon size     |
| `_buttonTextGap`       | 16px                                 | Gap icon to button text  |
| `_scrollThreshold`     | 10px                                 | Scroll edge detection    |

## Interactions

### Channel Selection

- Tap a channel item to switch to it
- Switching discards any in-progress note editing state
- Switching hides the settings view if open
- Selected channel is highlighted with `_selectedColor` background

### Context Menu

- Triggered by right-click (secondary tap) or long-press on a channel item
- Right-click uses the cursor position; long-press uses the widget position
- Menu items: Edit, Pin/Unpin, Delete

### Channel CRUD

- **Create**: "New Channel" button opens `NewChannelModal`. Default emoji is speech bubble. On create, auto-switches to the new channel.
- **Edit**: Context menu "Edit" opens `NewChannelModal` pre-filled with current name and emoji.
- **Archive**: Context menu "Archive" soft-deletes channel to Archive Crate. Shows error toast on failure.
- **Pin/Unpin**: Context menu toggle. Pinned channels sort to the top of the list.

### Scroll Behavior

- Scrollbar is hidden
- A 60px fade gradient appears at the top edge when scrolled past 10px
- A 60px fade gradient appears at the bottom edge when not scrolled to within 10px of the end
- Gradients use the sidebar background color for a seamless blend effect
- Gradients are wrapped in `IgnorePointer` so they don't block interaction with underlying items

## State Management

### Providers Watched (reactive)

| Provider                | Type                     | Purpose                              |
|-------------------------|--------------------------|--------------------------------------|
| `channelsProvider`      | `AsyncValue<List<Channel>>` | Full channel list for rendering   |
| `currentChannelProvider`| `AsyncValue<int?>`       | Currently selected channel ID        |
| `notesProvider(id)`     | `AsyncValue<List<Note>>` | Latest notes per channel (for preview)|

### Providers Read (on interaction)

| Provider                         | Usage                                  |
|----------------------------------|----------------------------------------|
| `channelsProvider.notifier`      | Create, update, delete channels        |
| `currentChannelProvider.notifier`| Switch active channel                  |
| `editingNoteProvider.notifier`   | Cancel editing on channel switch       |
| `settingsVisibilityProvider.notifier` | Show/hide settings overlay        |
| `currentSettingsPageProvider.notifier` | Set settings page to main        |

### Local Widget State

| Field              | Type             | Purpose                          |
|--------------------|------------------|----------------------------------|
| `_scrollController`| `ScrollController`| Tracks scroll position for fades|
| `_showFadeOut`     | `bool`           | Bottom fade gradient visibility  |
| `_showFadeIn`      | `bool`           | Top fade gradient visibility     |

## Integration

The Sidebar is placed as the left-most child in the app's main `Row` layout (in `ChatScreen`). It is always visible at its fixed 240px width. The sidebar communicates with the rest of the app exclusively through Riverpod providers — it has no direct widget-to-widget coupling.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/sidebar.dart` | This component |
| `lib/screens/chat_screen.dart` | Parent layout that hosts the sidebar |
| `lib/providers/channels_provider.dart` | Channel list data and mutations |
| `lib/providers/current_channel_provider.dart` | Active channel selection state |
| `lib/providers/notes_provider.dart` | Note data for channel previews |
| `lib/providers/editing_note_provider.dart` | Note editing state (cleared on switch) |
| `lib/providers/settings_view_provider.dart` | Settings overlay visibility |
| `lib/providers/settings_page_provider.dart` | Settings page navigation |
| `lib/widgets/new_channel_modal.dart` | Channel create/edit dialog |
| `lib/utils/toast_utils.dart` | Error toast display |
