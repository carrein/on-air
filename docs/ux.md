# UX Design Guidelines

## Overview
This document captures the user experience design decisions for the Memoka application, focusing on interaction patterns, visual styling, and behavior.

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

### Drag-to-Reorder
- **Trigger**: Long-press on a channel item to start drag
- **Constraint**: Pinned channels reorder only among pinned; unpinned only among unpinned
- **Persistence**: Order saved via `sortOrder` field on Channel model and `reorderChannels` endpoint
- **Widget**: `ReorderableListView` replaces `ListView.separated`

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
- **Smart Display**:
  - If note has text content: Show text with whitespace collapsed
  - If media-only (no text): Show "Image: filename.jpg" or "3 files"
  - If link-only: Show "Link: Page Title"
  - If completely empty: Hide preview line (no empty space)

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

### Message Display - Chat Bubbles
- **Container Style**:
  - White background (`Colors.white`)
  - 12px padding on all sides
  - 12px border radius (rounded corners)
  - Subtle shadow: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: Offset(0, 2))`
  - 8px horizontal margin, 4px vertical margin between messages
- **Image-only notes**: Notes with only image attachments (no text) render without the white bubble wrapper for a cleaner look
- **Compressed badge**: Media attachments that were compressed show a small "Compressed" badge overlay at bottom-right
- **Content**:
  - Markdown-formatted text with link support
  - Media attachments (images, videos, documents)
  - Link preview cards
- **Timestamp**: Below content, 11px font, grey color
- **Actions**: Available via right-click context menu (see below)

### Note Context Menu
- **Interaction Patterns**:
  - **Desktop**: Right-click on note
  - **Mobile**: Long-press on note
  - **Menu Position**: Appears at cursor position
- **Menu Options**:
  1. Copy - Copies note content to clipboard, shows toast notification
  2. Edit - Enters edit mode (populates input bar with note content)
  3. Delete - Removes note with confirmation
- **Removed Elements**: No visible copy/delete icons (moved to context menu for cleaner UI)

## Input Behavior

### Keyboard Shortcuts
- **Enter**: Submit message (handled via `Shortcuts`/`Actions` with `SingleActivator`)
- **Shift+Enter**: Insert new line (natural TextField multiline behavior, not manually intercepted)
- **Enter in FileUploadDialog**: Submits the upload (also via `Shortcuts`/`Actions`)
- **Hint text**: Reminds users about Shift+Enter
- **Ctrl+V / Cmd+V**: Paste text in textfield (file paste detected when not focused)

### Visual Feedback
- Send button enabled only when text is non-empty
- Edit mode shows cancel (X) button
- Save icon replaces send icon during edit

### Channel Drafts
- **Per-Channel State**: Each channel maintains its own input draft
- **Auto-Save**: Text is automatically saved when switching channels
- **Auto-Load**: Switching back to a channel restores the draft
- **Clear on Send**: Draft is cleared after successfully sending a message
- **Edit Mode Preservation**: Draft is saved when entering edit mode, restored on cancel
- **Storage**: In-memory only (not persisted on app restart, good for privacy)
- **Implementation**: `DraftsProvider` with `Map<int, String>` keyed by channel ID

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

## Toast Notifications

### Design System
- **Position**: Top-right corner of viewport
- **Stacking**: Up to 3 toasts visible simultaneously
- **Auto-Dismiss**: 2500ms duration, then fade out (800ms animation)
- **Overflow Behavior**: When 4th toast appears, oldest is removed
- **Animation**: Fade in (300ms), repositioning when dismissed

### Toast Types
1. **Error** (Red background):
   - Upload failures
   - Delete constraints (e.g., "Cannot delete last channel")
   - Network errors
2. **Success** (Green background):
   - File upload completed
   - Actions completed successfully
3. **Info** (Grey background, default):
   - Copy confirmation: "Copied: [preview]"
   - General notifications

### Implementation
- **Utility**: `ToastUtils.show(context, message, {type, duration})`
- **Technology**: `OverlayEntry` with `AnimatedPositioned` and `FadeTransition`
- **State Management**: `List<_NotificationData>` tracks active toasts with `ValueNotifier<double>` for positioning
- **Replaced**: All `SnackBar` usage converted to toast system for consistency

## Full-Screen Image Viewer (Lightbox)

### Gallery Navigation
- **Open**: Click any inline image to open the lightbox
- **Gallery mode**: All images in the current chat are navigable as a gallery
- **Navigation**: Left/right arrow buttons, keyboard arrow keys, swipe gestures
- **Counter**: Shows "X / Y" indicator for current position in gallery
- **Close**: Click backdrop, press Escape, or tap close button
- **Implementation**: Dialog overlay (`FullScreenImageView.show()`)

### Video Lightbox
- **Open**: Click any inline video thumbnail to open the video lightbox
- **Dialog**: Full-screen dialog overlay (not a route), `Colors.black` at 92% opacity backdrop
- **Controls**: Play/pause button, progress bar with seek, duration display
- **Keyboard**: Space to play/pause, Escape to close
- **Implementation**: `_VideoLightbox.show()` in `video_attachment_widget.dart`

## Chat Backgrounds

### Background Picker
- Accessible via Settings overlay → Background Picker screen
- Selection of themed background patterns (flower, food, gift, leaves, light, memphis, morocco, pentagon, sakura, sun, terrazzo, tree, wheat, wormz)
- Selected background is applied behind the chat view
- Persisted via `BackgroundProvider` with Riverpod state management

## Media Loading Behavior

### Shimmer Placeholders
- **Pre-sized**: Placeholders use server-provided `width` and `height` metadata to match the final image dimensions exactly
- **No layout jump**: Since the placeholder is the same size as the loaded image, the chat list doesn't shift when images finish loading
- **Animated shimmer**: Grey gradient sweep (grey[800] → grey[700] → grey[800]) with 1200ms cycle, 8px rounded corners
- **Fallback**: If dimensions are unavailable, defaults to 300x200

### Scroll Virtualization
- Flutter's `ListView` disposes off-screen widgets; scrolling back re-creates them
- `CachedNetworkImage` reads from disk cache but still shows a placeholder during the read
- **Mitigation**: Pre-sized shimmer + 150ms fade-in makes cache reads feel instant (vs default 500ms spinner)

### Media Sidebar Images
- **Full resolution**: Media sidebar loads full-res images (not thumbnails) with `cacheWidth: 400` for memory efficiency
- **Implementation**: `Image.network` with `cacheWidth: 400` in `MediaGridItem`

### Size Constraints
- **Images**: Max 600x500, aspect ratio preserved via `computeDisplaySize()`
- **Video thumbnails**: Max 400x300, same aspect-ratio logic
- **Error widgets**: Sized identically to the placeholder so layout stays stable

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
