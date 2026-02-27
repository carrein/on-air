# ChannelList

## Overview

ChannelList is the primary navigation component of the Memoka app. It displays a fixed-width panel on the left side of the screen containing a scrollable, reorderable list of channels.

**File**: `memoka_flutter/lib/widgets/channel_list.dart`
**Widget**: `ChannelList` (ConsumerStatefulWidget)
**State**: `_ChannelListState`

## Subcomponents

### Channel List

Scrollable, drag-to-reorder list of all channels, sorted with pinned channels first.

- Uses `ReorderableListView` inside a `Stack` (for fade gradients)
- **Drag-to-reorder**: Drag a channel item to reorder
  - Pinned channels can only be reordered among pinned channels
  - Unpinned channels can only be reordered among unpinned channels
  - Order is persisted via `sortOrder` field and `reorderChannels` endpoint
  - **Desktop/web**: `ReorderableDragStartListener` — drag starts immediately on pointer down
  - **Mobile**: `ReorderableDelayedDragStartListener` — requires a long-press to avoid conflicting with tap-to-select
- Scrollbar hidden via `ScrollConfiguration`
- Fade gradients (60px tall) appear at top/bottom edges when content is scrollable beyond view
- Fade gradients use the sidebar background color transitioning to transparent

### Channel Item

Individual channel row within the channel list.

**Non-compact (desktop/web — 240px sidebar):**
- **Icon container**: 40x40px centered box with Phosphor icon at 18px
- **Pinned indicator**: when pinned, icon is enclosed in a 38×38px circle border (1.5px, `core.text` / white when selected) — no trailing star
- **Text column**: Channel name (14px, normal weight) with optional preview line below
- **Preview text**: 10px, 70% opacity, single line with ellipsis overflow
- **Padding**: left 8px, right 18px, top/bottom 10px
- **Gap** between icon and text: 8px

**Compact (mobile — 64px sidebar):**
- Channel icon only (20px), vertically centred, no text or preview
- **Pinned indicator**: same circle border treatment as desktop (38×38px, 1.5px border)
- Selected state: full-row `brand.primary` background with white icon; circle border turns white

**States:**
- **Default**: transparent background, `core.text` icon/text
- **Selected**: `brand.primary` background, white icon/text
- **Drag active**: scale 1.04×, `brand.primary` border, elevated shadow (`proxyDecorator`)

**Interactions:**
- **Tap**: switch to channel
- **Long-press**: start drag-to-reorder

## Styling

### Color Palette

| Token               | Value       | Usage                                        |
|---------------------|-------------|----------------------------------------------|
| `_backgroundColor`  | `#F6F0ED`   | Sidebar background, fade gradients           |
| `_selectedColor`    | `#CE2161`   | Selected channel item background             |
| `_borderColor`      | `#CE2161`   | Right border, drag-active item border        |
| `_textColor`        | `#00171F`   | Channel names, preview text (unselected)     |
| `_previewTextAlpha` | `0.7`       | Preview text opacity                         |

### Typography

| Element       | Size  | Weight  | Color                              |
|---------------|-------|---------|------------------------------------|
| Channel name  | 14px  | Normal  | `#00171F` (unselected) / white (selected) |
| Preview text  | 10px  | Normal  | `#00171F` @ 70% / white @ 70%     |

### Dimensions

| Token                  | Value                           | Usage                    |
|------------------------|---------------------------------|--------------------------|
| `_sidebarWidth`        | 240px                           | Desktop sidebar width    |
| `_sidebarCompactWidth` | 64px                            | Mobile sidebar width     |
| `_emojiContainerSize`  | 40px                            | Icon box width/height    |
| `_emojiFontSize`       | 18px                            | Icon size                |
| `_channelItemPadding`  | L: 8, R: 18, T: 10, B: 10     | Channel item padding     |
| `_emojiToTextGap`      | 8px                             | Gap icon to text column  |
| `_fadeGradientHeight`  | 60px                            | Top/bottom scroll fades  |
| `_scrollThreshold`     | 10px                            | Scroll edge detection    |

## Interactions

### Channel Selection

- Tap a channel item to switch to it — **no animation** (instant snap)
- Switching discards any in-progress note editing state
- Switching hides the settings view if open
- Selected channel is highlighted with `_selectedColor` background
- Sets `channelSwitchDirectionProvider` to `0` so `ChatView` skips the slide animation

### Drag-to-Reorder

- **Desktop/web**: Drag begins immediately on pointer down (`ReorderableDragStartListener`)
- **Mobile**: Long-press to begin drag (`ReorderableDelayedDragStartListener`) — avoids conflict with tap
- Dragging is constrained to the item's group (pinned stays with pinned, unpinned stays with unpinned)
- While dragging, the item shows a scale/border/shadow animation via `proxyDecorator`
- Channel order is persisted immediately on drop via `reorderChannels`

### Channel CRUD

Channel create/edit/pin/archive actions are accessed via the **Navbar 3-dot menu** (not the sidebar). See `docs/components/Navbar.md`.

### Scroll Behaviour

- Scrollbar is hidden
- A 60px fade gradient appears at the top edge when scrolled past 10px
- A 60px fade gradient appears at the bottom edge when not scrolled to within 10px of the end
- Gradients use the sidebar background color for a seamless blend effect
- Gradients are wrapped in `IgnorePointer` so they don't block interaction

### Scroll-to-Active-Channel

When the active channel changes (via any means — tap, keyboard arrow keys, or swipe gesture), the sidebar automatically scrolls to center the newly selected channel in the viewport.

- Triggered via `ref.listen(currentChannelProvider)` with `addPostFrameCallback`
- Item height: `_emojiContainerSize + 20.0 = 60px` (40px icon + 10px top + 10px bottom padding)
- Target position: `itemTop - (viewportHeight - itemHeight) / 2`, clamped to valid scroll extents
- Animation: 250ms `easeInOut`
- No-op if target is within 1px of current position (avoids jitter)

## State Management

### Providers Watched (reactive)

| Provider                | Type                        | Purpose                               |
|-------------------------|-----------------------------|---------------------------------------|
| `channelsProvider`      | `AsyncValue<List<Channel>>` | Full channel list for rendering       |
| `currentChannelProvider`| `AsyncValue<int?>`          | Currently selected channel ID         |
| `notesProvider(id)`     | `AsyncValue<List<Note>>`    | Latest notes per channel (preview)    |

### Providers Read (on interaction)

| Provider                              | Usage                            |
|---------------------------------------|----------------------------------|
| `channelsProvider.notifier`           | Reorder channels                 |
| `currentChannelProvider.notifier`      | Switch active channel             |
| `channelSwitchDirectionProvider.notifier` | Set to `0` to suppress animation |
| `editingNoteProvider.notifier`         | Cancel editing on channel switch  |
| `settingsVisibilityProvider.notifier`  | Hide settings on channel switch   |

### Local Widget State

| Field               | Type               | Purpose                                        |
|---------------------|--------------------|------------------------------------------------|
| `_scrollController` | `ScrollController` | Tracks scroll position for fades and auto-scroll |
| `_showFadeOut`      | `bool`             | Bottom fade gradient visibility                |
| `_showFadeIn`       | `bool`             | Top fade gradient visibility                   |

### Side Effects

| Listener | Trigger | Effect |
|----------|---------|--------|
| `ref.listen(currentChannelProvider)` | Channel ID changes | Scrolls to center the new active channel (`addPostFrameCallback`) |

## Integration

ChannelList is placed as the left-most child in the app's main `Row` layout (in `ChatScreen`). It is **hidden in detail mode** — when the settings view is open or the Archive is selected (`isInDetailMode = isShowingSettings || isArchive`). ChannelList communicates with the rest of the app exclusively through Riverpod providers — it has no direct widget-to-widget coupling.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/channel_list.dart` | This component |
| `lib/screens/chat_screen.dart` | Parent layout that hosts the sidebar |
| `lib/widgets/navbar.dart` | Hosts channel actions (edit/pin/archive) |
| `lib/providers/channels_provider.dart` | Channel list data and mutations |
| `lib/providers/current_channel_provider.dart` | Active channel selection state |
| `lib/providers/notes_provider.dart` | Note data for channel previews |
| `lib/providers/editing_note_provider.dart` | Note editing state (cleared on switch) |
| `lib/providers/settings_view_provider.dart` | Settings overlay visibility |
