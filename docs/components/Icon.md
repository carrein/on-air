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
| **Duotone** | Interactive/tappable icons (buttons, actions) | Input bar camera, send, attach |
| **Fill** | Static display icons (channel icons, sidebar, picker) | Channel icons in sidebar, icon picker grid |

## IconButtonStyled

The standard widget for any tappable Phosphor icon in the app.

### Features

- Circular `InkWell` with white splash/highlight on press
- Transparent `Material` wrapper for proper ink rendering
- Phosphor duotone icon with configurable primary and secondary colors
- Optional tooltip (via `StyledTooltip`, shown on desktop/web only)
- Configurable size and padding

### API

```dart
IconButtonStyled({
  required PhosphorIconData icon,   // Phosphor icon to display
  required VoidCallback onPressed,  // Tap callback
  String? tooltip,                  // Optional hover tooltip
  double size = 24,                 // Icon size (px)
  double padding = 8,              // Padding inside InkWell
  Color color = Colors.white,       // Primary icon color
  Color duotoneSecondaryColor = Color(0xFFF9A302),  // Secondary color
  double duotoneSecondaryOpacity = 1.0,             // Secondary opacity
  Color splashColor = Colors.white24,   // InkWell splash
  Color highlightColor = Colors.white24, // InkWell highlight
})
```

### Usage

```dart
// Basic usage
IconButtonStyled(
  icon: PhosphorIconsDuotone.camera,
  onPressed: _capturePhoto,
  tooltip: 'Camera',
)

// Custom size and colors
IconButtonStyled(
  icon: PhosphorIconsDuotone.paperPlaneRight,
  onPressed: _submit,
  tooltip: 'Send',
  size: 20,
  duotoneSecondaryColor: Color(0xFFF9A302),
)
```

### Widget Tree

```
StyledTooltip? (desktop/web only)
  └─ Material (transparent)
       └─ InkWell (CircleBorder)
            └─ Padding (8px)
                 └─ PhosphorIcon (duotone)
```

## Styling

### Default Colors

| Token | Value | Usage |
|-------|-------|-------|
| Primary color | `#FFFFFF` | Icon primary layer |
| Secondary color | `#F9A302` | Duotone secondary layer |
| Secondary opacity | `1.0` | Full visibility for secondary |
| Splash color | `Colors.white24` | InkWell press splash |
| Highlight color | `Colors.white24` | InkWell press highlight |

### Dimensions

| Token | Value | Usage |
|-------|-------|-------|
| Icon size | 24px | Default icon size |
| Padding | 8px | Space inside InkWell around icon |
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
| Input bar (empty) | `IconButtonStyled` | `camera`, `paperclip` |
| Input bar (text) | `IconButtonStyled` | `paperPlaneRight` |
| Input bar (edit mode) | `IconButton` | Material `close`, `check` |
| Top bar menu | `IconButtonStyled` | `dotsThreeCircle` |
| Top bar popup items | `PhosphorIcon` (static) | `images` |
| Sidebar channels | `PhosphorIcon` (static) | Per-channel Fill icon |
| Channel modal | `PhosphorIcon` (static) | Selected Fill icon |
| Icon picker grid | `PhosphorIcon` (static) | All Fill icons |

## Integration

The icon system integrates with:

- **Channel model**: `emoji` field stores Phosphor icon key names (e.g., `'chatCircle'`)
- **Database**: No migration needed — reuses existing String field
- **Sidebar**: Both compact and full modes render `PhosphorIcon(getChannelIcon(channel.emoji))`
- **Seed data**: Demo and full seeds use icon key names

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/icon_button_styled.dart` | Reusable tappable icon widget |
| `lib/widgets/styled_tooltip.dart` | Tooltip wrapper (used by IconButtonStyled) |
| `lib/utils/icon_utils.dart` | Icon name → PhosphorIconData mapping |
| `lib/widgets/icon_picker.dart` | Channel icon selection bottom sheet |
| `lib/widgets/input_bar.dart` | Primary consumer (camera, send, attach) |
| `lib/widgets/channel_top_bar.dart` | Top bar menu icon |
| `lib/widgets/sidebar.dart` | Channel icon display |
| `lib/widgets/new_channel_modal.dart` | Channel icon selector |
