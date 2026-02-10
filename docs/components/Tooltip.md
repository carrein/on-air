# Tooltip

## Overview

The Tooltip component provides consistent, styled hover tooltips across the Memoka app. It uses a custom theme override to apply brand-consistent styling to Flutter's built-in `Tooltip` widget.

**Pattern**: Theme override wrapper
**Current Usage**: InputBar icon buttons, Archive delete button
**Recommended Usage**: All interactive elements that benefit from explanatory hover text

## Styling

### Visual Design

Custom-styled tooltips with sharp corners and brand colors.

- **Background**: `core.surface` (white, #FFFFFF)
- **Border**: 1px solid `brand.accent` (#FF52A1)
- **Border radius**: 0px (sharp corners)
- **Text color**: `core.background` (#00171F)
- **Font**: Space Grotesk, 12px, normal weight
- **Padding**: 8px vertical, 12px horizontal

### Color Palette

| Token               | Value       | Theme Token       | Usage                |
|---------------------|-------------|-------------------|----------------------|
| Background          | `#FFFFFF`   | `core.surface`    | Tooltip background   |
| Border              | `#FF52A1`   | `brand.accent`    | Border stroke        |
| Text                | `#00171F`   | `core.background` | Tooltip text color   |

### Typography

| Element      | Font          | Size  | Weight  | Color     |
|--------------|---------------|-------|---------|-----------|
| Tooltip text | Space Grotesk | 12px  | Normal  | `#00171F` |

### Dimensions

| Token              | Value                    | Usage                     |
|--------------------|--------------------------|---------------------------|
| Padding vertical   | 8px                      | Top/bottom padding        |
| Padding horizontal | 12px                     | Left/right padding        |
| Border width       | 1px                      | Border stroke width       |
| Border radius      | 0px                      | Sharp corners             |

## Implementation Patterns

### Pattern 1: Theme Override (Current)

**Used in**: InputBar

Wrap a subtree with a `Theme` widget that overrides `tooltipTheme`:

```dart
Theme(
  data: Theme.of(context).copyWith(
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFF52A1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      textStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF00171F),
        fontSize: 12,
      ),
    ),
  ),
  child: /* your widget tree with Tooltip widgets */,
)
```

**Then use standard Tooltip widgets**:

```dart
Tooltip(
  message: 'Upload file',
  child: IconButton(/* ... */),
)
```

### Pattern 2: Reusable Widget (Proposed)

Create a `StyledTooltip` widget for consistency:

```dart
class StyledTooltip extends StatelessWidget {
  final String message;
  final Widget child;

  const StyledTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFF52A1),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      textStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF00171F),
        fontSize: 12,
      ),
      child: child,
    );
  }
}
```

**Usage**:

```dart
StyledTooltip(
  message: 'Delete note',
  child: GestureDetector(/* ... */),
)
```

## Current Usage

### InputBar

- **Upload file**: Attachment button
- **Send**: Send button (normal mode)
- **Save**: Send button (edit mode)
- **Cancel**: Cancel button (edit mode)

All tooltips use the Theme override pattern wrapping the entire InputBar widget tree.

### Archive Delete Button

Currently uses default Flutter `Tooltip` widget without custom styling (needs migration).

## Implementation Details

### Configuration

- **Wait duration**: 500ms hover delay before tooltip appears
- **Positioning**: Automatic (Flutter default smart positioning)
- **Mobile behavior**: Tooltips disabled on Android/iOS (mobile devices)
- **Web behavior**: Tooltips always enabled on web platform

### Platform Detection

The component detects mobile platforms and skips rendering tooltips:

```dart
bool get _isMobile {
  if (kIsWeb) return false; // Web is always desktop-like
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}
```

### Migration Status

✅ **Completed**:
- Created `StyledTooltip` widget in `lib/widgets/styled_tooltip.dart`
- Migrated InputBar tooltips (Upload file, Send, Save, Cancel)
- Migrated Archive delete button tooltip
- Removed Theme override pattern from InputBar

### Usage Guidelines

Use `StyledTooltip` for all interactive elements that benefit from hover hints:
- Icon buttons without text labels
- Action buttons with unclear purpose
- Toolbar items
- Quick action buttons

**Do NOT use for**:
- Text buttons with visible labels
- Elements with clear affordance
- Mobile-only interfaces

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/styled_tooltip.dart` | Proposed reusable component |
| `lib/widgets/input_bar.dart` | Current theme override implementation |
| `lib/widgets/chat_view.dart` | Archive delete button (needs migration) |
| `docs/Theme.md` | Color and typography token reference |
