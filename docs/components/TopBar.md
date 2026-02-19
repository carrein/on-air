# TopBar

## Overview

The TopBar is the channel title bar displayed at the top of the screen. It shows the current channel name and, on mobile/tablet, a three-dot menu button for accessing media.

**File**: `memoka_flutter/lib/widgets/channel_top_bar.dart`
**Widget**: `ChannelTopBar` (ConsumerWidget)

## Subcomponents

### Bar Container

The outer container spanning full width.

- Background: `#00171F`
- Padding: left 16px, top 8px, bottom 8px, right 8px
- Height driven by children (icon button = 40px tall, so bar = 56px with padding)

### Channel Title

Left-aligned text showing the current channel name.

- Font size: 20px, normal weight, white
- Shows "Archive" when viewing the Archive channel
- Ellipsis overflow for long names

### Menu Button (mobile/tablet only)

Right-aligned three-dot icon using `IconButtonStyled`.

- Icon: `PhosphorIconsDuotone.dotsThreeCircle`
- Only shown when the media sidebar is NOT visible (mobile/tablet breakpoints)
- Opens a popup menu on tap

### Popup Menu

Dark popup menu triggered by the menu button.

- Background: `#00171F`
- Single item: "Media" with `PhosphorIconsDuotone.images` icon (20px) + white text
- Selecting "Media" opens the media bottom sheet

### Media Bottom Sheet

Draggable modal bottom sheet showing `MediaSidebar`.

- Initial size: 90% of screen height
- Min size: 50%, max size: 95%
- White background with 20px top border radius
- Handle bar: 40x4px grey rounded bar at top
- Contains `MediaSidebar(fixedWidth: false)` for full-width tab content

## Styling

### Color Palette

| Token              | Value     | Usage                           |
|--------------------|-----------|---------------------------------|
| `_backgroundColor` | `#00171F` | Bar background, popup menu      |
| Title text         | `#FFFFFF` | Channel name text               |
| Menu icon          | `#FFFFFF` | Three-dot icon primary color    |
| Menu icon secondary| `#F9A302` | Three-dot icon duotone color    |

### Typography

| Element       | Font   | Size | Weight | Color  |
|---------------|--------|------|--------|--------|
| Channel title | System | 20px | Normal | White  |
| Menu item     | System | 14px | Normal | White  |

### Dimensions

| Token         | Value                          | Usage                    |
|---------------|--------------------------------|--------------------------|
| `_padding`    | L: 16, T: 8, B: 8, R: 8      | Bar container padding    |
| Icon size     | 24px (default from IconButtonStyled) | Menu button icon   |
| Icon padding  | 8px (default from IconButtonStyled)  | Menu button tap area |
| Total height  | 56px (8 + 40 + 8)             | Bar height with icon     |

## Interactions

### Menu Button

- Tap opens a popup menu anchored to the top-right
- Menu items: "Media" (opens media bottom sheet)
- Only visible on mobile/tablet (when `shouldShowMediaSidebar` returns false)

### Media Bottom Sheet

- Draggable to resize between 50-95% of screen height
- Tap outside the sheet to dismiss
- Contains the same `MediaSidebar` widget used on desktop, but with `fixedWidth: false`

## State Management

### Providers Watched (reactive)

| Provider                | Type                       | Purpose                     |
|-------------------------|----------------------------|-----------------------------|
| `currentChannelProvider`| `AsyncValue<int>`          | Current channel ID          |
| `channelsProvider`      | `AsyncValue<List<Channel>>`| Channel list for name lookup|

### Responsive Behavior

| Breakpoint      | Menu Button | Media Access              |
|-----------------|-------------|---------------------------|
| Mobile (<768px) | Shown       | Via menu → bottom sheet   |
| Tablet (768-1199px) | Shown   | Via menu → bottom sheet   |
| Desktop (1200px+)| Hidden     | Permanent MediaSidebar    |

## Integration

The `ChannelTopBar` is placed in the `ChatScreen` column above the main `Row` layout. It spans full width across both the sidebar and content area. It is hidden when the settings view is open.

Previously, media access on mobile was via a `FloatingActionButton` in `ChatView`. This was replaced with the top bar menu for a cleaner UI.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/channel_top_bar.dart` | This component |
| `lib/widgets/icon_button_styled.dart` | Menu button widget |
| `lib/widgets/media_sidebar.dart` | Media content in bottom sheet |
| `lib/screens/chat_screen.dart` | Parent layout that hosts the top bar |
| `lib/providers/current_channel_provider.dart` | Active channel ID |
| `lib/providers/channels_provider.dart` | Channel list data |
| `lib/utils/responsive_utils.dart` | Breakpoint detection |
