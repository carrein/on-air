# NewChannelModal

## Overview

A reusable modal dialog for creating and editing channels. Operates in two modes: **create** (new channel) and **edit** (modify existing channel). Used by the sidebar when the user clicks "New Channel" or selects "Edit" from a channel's context menu.

**File**: `memoka_flutter/lib/widgets/new_channel_modal.dart`
**Widget**: `NewChannelModal` (StatefulWidget)
**State**: `_NewChannelModalState`

## Modes

| Mode   | Title          | Action Button | Pre-populated | Triggered By                     |
|--------|----------------|---------------|---------------|----------------------------------|
| Create | "New Channel"  | "Create"      | No            | Sidebar "New Channel" button     |
| Edit   | "Edit Channel" | "Save"        | Yes           | Channel context menu "Edit"      |

Mode is determined by the presence of the `channel` parameter. If `channel` is `null`, the modal is in create mode.

## Subcomponents

### Title

Left-aligned text at the top of the dialog.

- "New Channel" (create mode) or "Edit Channel" (edit mode)
- Font size: 20px, weight: w600, color: `#00171F`

### Icon Selector

Centered circular button that opens the Phosphor icon picker.

- **Shape**: Circle (64x64px)
- **Border**: 1px solid `#FF52A1`
- **Icon size**: 28px, `PhosphorIconsFill` style
- **Default icon**: `chatCircle` (create mode) or existing icon key (edit mode)
- **Cursor**: Click pointer on hover
- **Position**: Centered, above the channel name field
- **Gap to field**: 20px below

### Channel Name Field

Text input for the channel name.

- **Style**: Outlined `TextField` with zero border radius
- **Background**: `#FFFFFF` (white)
- **Text color**: `#00171F`
- **Hint text**: "Channel Name" at 40% opacity
- **Content padding**: 16px horizontal, 14px vertical
- **Enabled border**: 1px solid `#DADDD8`
- **Focused border**: 1px solid `#FF52A1` (pink)
- **Autofocus**: Yes
- **Submit on Enter**: Triggers confirm action

### Action Buttons

Right-aligned row with Cancel and Create/Save buttons.

- **Cancel button**: TextButton (no background/border), `#00171F` text, zero border radius
- **Create/Save button**: `#00171F` background, white text, zero border radius
- **Gap between buttons**: 12px
- **Gap above buttons**: 24px

### Icon Picker

Modal bottom sheet triggered by tapping the icon selector. Implemented in `icon_picker.dart`.

- **Search field** at top with hint text "Search icons..."
- **Grid**: 6 columns, scrollable, showing all ~1500 Phosphor fill icons
- Typing filters the grid in real-time by icon name (camelCase converted to words)
- Selected icon gets pink border/highlight
- Tapping an icon selects it and closes the picker

## Styling

### Color Palette

| Token               | Value     | Usage                                        |
|---------------------|-----------|----------------------------------------------|
| `_borderColor`      | `#FF52A1` | Dialog border, focused input border          |
| `_darkColor`        | `#00171F` | Title text, input text, Create/Save button   |
| `_emojiCircleBorder`| `#DADDD8` | Input enabled border                         |
| Dialog background   | `#FFFFFF` | Modal background                             |
| Input fill          | `#FFFFFF` | Channel name field background                |

### Typography

| Element         | Font   | Size | Weight | Color               |
|-----------------|--------|------|--------|---------------------|
| Title           | System | 20px | w600   | `#00171F`           |
| Icon            | Phosphor | 28px | Fill | `#00171F`           |
| Input text      | System | —    | Normal | `#00171F`           |
| Hint text       | System | —    | Normal | `#00171F` @ 40%     |
| Button text     | System | —    | Normal | Varies by button    |

### Dimensions

| Element                 | Value           | Usage                         |
|-------------------------|-----------------|-------------------------------|
| Dialog width            | 350px           | Fixed dialog content width    |
| Dialog padding          | 24px all sides  | Inner padding                 |
| Icon circle size        | 64x64px         | Icon selector dimensions      |
| Icon to field gap       | 20px            | Space between icon and input  |
| Input content padding   | H: 16px, V: 14px | TextField inner padding     |
| Button gap              | 12px            | Space between Cancel and Create/Save |
| Section gap             | 24px            | Title to emoji, input to buttons |

## Interactions

### Create Flow

1. User clicks "New Channel" in sidebar
2. Modal opens with empty name, default speech bubble emoji
3. Name field is auto-focused
4. User optionally taps icon circle to open picker, selects icon
5. User types channel name
6. User clicks "Create" or presses Enter
7. `onConfirm` callback fires with name and icon key
8. Modal closes automatically after callback completes
9. Sidebar switches to the newly created channel

### Edit Flow

1. User right-clicks a channel, selects "Edit"
2. Modal opens pre-populated with channel's current name and icon
3. Name field is auto-focused
4. User modifies name and/or icon
5. User clicks "Save" or presses Enter
6. `onConfirm` callback fires with updated name and icon key
7. Modal closes automatically

### Validation

- Create/Save button does nothing if name is empty (after trimming whitespace)
- Enter key in the name field triggers the same confirm action

## API

### Constructor

```dart
NewChannelModal({
  Channel? channel,        // null = create mode, provided = edit mode
  required Future<void> Function(String name, String emoji) onConfirm,
})
```

### Static Method

```dart
static Future<void> show(
  BuildContext context, {
  Channel? channel,
  required Future<void> Function(String name, String emoji) onConfirm,
})
```

## State Management

### Local Widget State

| Field              | Type                   | Purpose                          |
|--------------------|------------------------|----------------------------------|
| `_nameController`  | `TextEditingController`| Channel name input               |
| `_selectedIconKey` | `String`               | Currently selected icon key      |

The modal is a pure stateful widget with no provider dependencies. All side effects (creating/updating channels, switching channels) are handled by the `onConfirm` callback provided by the caller.

## Integration

The sidebar imports `NewChannelModal` and calls `NewChannelModal.show()` from two locations:

- `_showCreateChannelDialog()` — passes `onConfirm` that creates a channel and switches to it
- `_showEditChannelDialog()` — passes the existing `Channel` and `onConfirm` that updates it

| `lib/widgets/icon_picker.dart` | Icon picker bottom sheet |
| `lib/utils/icon_utils.dart` | Icon name ↔ PhosphorIconData lookup |

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/new_channel_modal.dart` | This component |
| `lib/widgets/channel_list.dart` | Caller that shows the modal |
| `lib/providers/channels_provider.dart` | Channel create/update (called via onConfirm) |
| `lib/providers/current_channel_provider.dart` | Channel switching (called via onConfirm) |
