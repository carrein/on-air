# Icon System

## Overview

Memoka uses [Phosphor Icons](https://phosphoricons.com/) as its icon library via the `phosphor_flutter` package. A reusable `IconButtonStyled` widget provides a consistent design language for all tappable icons across the app.

**Reusable widget**: `memoka_flutter/lib/widgets/icon_button_styled.dart`
**Icon utilities**: `memoka_flutter/lib/utils/icon_utils.dart`
**Icon picker**: `memoka_flutter/lib/widgets/icon_picker.dart`

## Icon Styles

Phosphor offers multiple styles. Memoka uses two:

| Style | Usage | Example |
|-------|-------|---------|
| **Regular** | Interactive/tappable icons (buttons, actions) | Note input camera, send, attach; Navbar buttons |
| **Fill** | Static display icons (channel icons, sidebar, picker) | Channel icons in channel list, icon picker grid |

Regular style is accessed via function calls: `PhosphorIcons.camera()`, `PhosphorIcons.archive()`, etc.
Fill style is accessed via static fields: `PhosphorIconsFill.chatCircle`, `PhosphorIconsFill.star`, etc.

## IconButtonStyled

The standard widget for any tappable Phosphor icon in the app.

### Features

- Animated circular border on hover (desktop) and press (all platforms)
- Regular Phosphor icon with configurable color
- Optional tooltip (via `StyledTooltip`, shown on desktop/web only)
- Configurable size and padding

### API

```dart
IconButtonStyled({
  required IconData icon,          // Phosphor regular icon (e.g. PhosphorIcons.camera())
  required VoidCallback onPressed, // Tap callback
  String? tooltip,                 // Optional hover tooltip
  double size = 24,                // Icon size (px)
  double padding = 8,              // Padding inside button around icon
  Color color = Color(0xFFCE2161), // Icon and border color (brand.primary)
})
```

### Usage

```dart
// Basic usage
IconButtonStyled(
  icon: PhosphorIcons.camera(),
  onPressed: _capturePhoto,
  tooltip: 'Camera',
)

// Custom size and color
IconButtonStyled(
  icon: PhosphorIcons.paperPlaneRight(),
  onPressed: _submit,
  size: 20,
  color: Color(0xFFCE2161),
)
```

### Widget Tree

```
StyledTooltip? (desktop/web only)
  └─ MouseRegion (cursor: click)
       └─ GestureDetector (onTap/onTapDown/onTapUp/onTapCancel)
            └─ AnimatedContainer (circle border, 120ms)
                 └─ Padding (8px)
                      └─ Icon (Phosphor regular)
```

The circular border is transparent by default, animating to `color @ 50%` on hover and `color @ 100%` on press.

## Styling

### Default Colors

| Token | Value | Usage |
|-------|-------|-------|
| `color` | `#CE2161` (brand.primary) | Icon color and animated border |
| Hover border | `color @ 50%` | Circle border on hover |
| Press border | `color @ 100%` | Circle border on press |

### Dimensions

| Token | Value | Usage |
|-------|-------|-------|
| Icon size | 24px | Default icon size |
| Padding | 8px | Space inside button around icon |
| Total hit target | 40x40px | Icon (24) + padding (8×2) |

## Icon Utilities (`icon_utils.dart`)

Provides a mapping of all 1511 `PhosphorIconsFill` entries for channel icons.

| Export | Type | Purpose |
|--------|------|---------|
| `kDefaultChannelIcon` | `String` | Default icon key (`'chatCircle'`) |
| `kPhosphorFillIcons` | `Map<String, PhosphorIconData>` | Full icon name → data map |
| `getChannelIcon(key)` | `PhosphorIconData` | Lookup with `chatCircle` fallback |

## Icon Picker (`icon_picker.dart`)

Modal bottom sheet for selecting channel icons.

- **Search field** at top with hint text "Search icons..."
- **Grid** of all ~1511 Phosphor fill icons (6 columns, scrollable)
- Real-time filtering by icon name (camelCase converted to words)
- Selected icon highlighted with pink background (`#CE2161`)
- Tap to select and close

```dart
final iconKey = await IconPicker.show(
  context,
  currentIcon: channel.emoji,
);
```

## Usage Across the App

| Location | Widget | Icons Used |
|----------|--------|------------|
| Input (empty) | `IconButtonStyled` | `camera`, `paperclip` |
| Input (text) | `IconButtonStyled` | `paperPlaneRight` |
| NoteInput (edit mode) | `IconButtonStyled` | `xCircle` (cancel), `highlighter` (save) |
| Navbar (standard) | `IconButtonStyled` | `pushPin`/`pushPinSlash`, `dotsThreeCircle` |
| Navbar (detail/selection) | `IconButtonStyled` | `arrowCircleLeft`, `xCircle`, `archive` |
| Navbar popup items | `PhosphorIcon` (static) | `pencilSimple`, `archive`, `plusCircle`, `images`, `gear` |
| ChannelList channels | `PhosphorIcon` (static) | Per-channel Fill icon |
| Channel modal | `PhosphorIcon` (static) | Selected Fill icon |
| Icon picker grid | `PhosphorIcon` (static) | All Fill icons |
| Note footer | `PhosphorIcon` (static) | `pencilSimple`, `copySimple`, `archive`/`arrowCounterClockwise`, `shareNetwork` |

## Integration

The icon system integrates with:

- **Channel model**: `emoji` field stores Phosphor icon key names (e.g., `'chatCircle'`)
- **Database**: No migration needed — reuses existing String field
- **ChannelList**: Both compact and full modes render `PhosphorIcon(getChannelIcon(channel.emoji))`
- **Seed data**: Demo and full seeds use icon key names

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/icon_button_styled.dart` | Reusable tappable icon widget |
| `lib/widgets/styled_tooltip.dart` | Tooltip wrapper (used by IconButtonStyled) |
| `lib/utils/icon_utils.dart` | Icon name → PhosphorIconData mapping |
| `lib/widgets/icon_picker.dart` | Channel icon selection bottom sheet |
| `lib/widgets/note_input.dart` | Primary consumer (camera, send, attach, edit) |
| `lib/widgets/navbar.dart` | Navbar icon buttons |
| `lib/widgets/channel_list.dart` | Channel icon display |
| `lib/widgets/new_channel_modal.dart` | Channel icon selector |
| `lib/widgets/note_item.dart` | Note footer action icons |
