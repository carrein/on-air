# UX Design Guidelines

## Overview
This document captures the user experience design decisions for the On Air application, focusing on interaction patterns, visual styling, and behavior.

## Sidebar Design

### Layout States
The sidebar supports two width states (web only):
- **Collapsed**: 70px width, emoji-only view
- **Expanded**: 250px width, shows emoji + channel name + message preview
- **Mobile**: Always collapsed (70px)

### Draggable Behavior (Web)
- Sidebar can be dragged from the right edge
- 8px wide draggable divider
- Snaps to one of two positions:
  - Threshold at 150px
  - < 150px → snaps to 70px (collapsed)
  - ≥ 150px → snaps to 250px (expanded)
- Visual feedback: Blue highlight on divider during drag

### Spacing & Padding
- **Container**: No outer padding (edge-to-edge content)
- **Channel Items**: 12px horizontal and vertical padding
- **Inter-channel Spacing**: 4px gap between items
- **Emoji-to-text Gap**: 12px spacing in expanded mode

## Channel List Design

### Visual Style
- **No border radius**: All elements use sharp corners
- **Background**: Light gray (Colors.grey[200])
- **Selection**: Light blue background (Colors.blue[100])
- **Divider**: Horizontal line between pinned and unpinned channels

### Channel Item Structure (Expanded)
```
[Emoji Circle] [Channel Name          ] [Pin Icon]
               [Latest Message Preview]
```

### Channel Item Structure (Collapsed)
```
    [Emoji Circle]
```

### Emoji Display
- **Size**: 40x40px circle
- **Background**: Transparent
- **Border**: 1px solid gray
- **Emoji Size**: 20px font size
- **Alignment**: Centered in circle

### Pin Indicator
- **Position**: Right side of channel item (end of row)
- **Icon**: Small blue pin (16px)
- **Not overlaid on emoji** (previous design had it as badge on emoji)

### Message Preview
- **Font Size**: 12px
- **Color**: Gray (Colors.grey[600])
- **Lines**: Single line with ellipsis
- **Content**: Shows newest note in the channel
- **Updates**: Real-time via WebSocket

### "New Channel" Button
- **Styling**: Matches channel items exactly
- **Same padding**: 12px horizontal and vertical
- **Same height**: Uses Column structure with spacer to match channel items
- **Icon**: Plus icon (24px collapsed, 20px expanded)
- **Alignment**: Centered when collapsed, left-aligned when expanded

## Context Menus

### Interaction Patterns
- **Desktop**: Right-click on channel item
- **Mobile**: Long-press on channel item
- **Menu Position**: Appears at cursor position (desktop) or widget position (mobile)

### Menu Options
1. Edit - Opens dialog to modify channel name and emoji
2. Pin/Unpin - Toggles pin state
3. Delete - Removes channel (with confirmation via cascade behavior)

### Removed Elements
- No three-dot menu button (replaced with context menu)
- No circular button ripple effects (consistent rectangular InkWell)

## Chat View

### Message Ordering
- **Newest at bottom**: Natural chat progression
- **Oldest at top**: Scroll up to see history
- **Auto-scroll**: New messages appear at bottom
- **Pagination**: Loads older messages when scrolling near top

### Message Display
- Standard list items
- Timestamp shown below each message
- Edit/delete options on long-press

## Input Behavior

### Keyboard Shortcuts
- **Enter**: Submit message
- **Shift+Enter**: Insert new line (multiline support)
- **Hint text**: Reminds users about Shift+Enter

### Visual Feedback
- Send button enabled only when text is non-empty
- Edit mode shows cancel (X) button
- Save icon replaces send icon during edit

## Real-time Updates

### Live Features
- New channels appear instantly
- Channel updates (name, emoji, pin) reflect immediately
- Message previews update as notes are posted
- Divider appears/disappears as channels are pinned/unpinned

### WebSocket Integration
- All changes broadcast to connected clients
- No page refresh needed
- Optimistic updates for better UX

## Design Principles

### Consistency
- All interactive items (channels, buttons) use same padding and structure
- No mixed interaction patterns (all use Material/InkWell)
- Sharp corners throughout (no border radius)

### Clarity
- Transparent backgrounds with borders for definition
- Clear visual hierarchy (name bold, preview gray)
- Adequate spacing prevents crowding

### Efficiency
- Quick actions via context menus
- Keyboard shortcuts for common operations
- Real-time updates eliminate manual refreshes

### Accessibility
- Right-click and long-press support both desktop and mobile
- Visual feedback for all interactions
- Clear hover states and selection indicators
