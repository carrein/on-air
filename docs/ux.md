# UX Design Guidelines

## Overview
This document captures the user experience design decisions for the Memoka application, focusing on interaction patterns, visual styling, and behavior.

## Sidebar Design

### Layout States

The sidebar supports two width states:

- **Compact (mobile — 64px)**: Emoji/icon only, no text or preview
- **Full (desktop/web — 240px)**: Icon + channel name + message preview

### Spacing & Padding

- **Channel Items**: left 8px, right 18px, top/bottom 10px
- **Icon-to-text Gap**: 8px (full mode only)
- **Pin Icon Gap**: 12px before the star icon

### Visual Style

- **Background**: `#F6F0ED` (core.surface)
- **Selected channel**: `#CE2161` background, white icon/text
- **Pin indicator** (full mode): Phosphor star icon (20px) rotated 15°, `#CE2161`
- **Pin indicator** (compact, pinned but not selected): icon inside a 32×32px `#CE2161` circle

### Channel Item Structure (Full)

```
[Icon 40x40] [Channel Name          ] [Pin Star?]
             [Latest Message Preview]
```

### Channel Item Structure (Compact)

```
    [Icon 22px]
```

### Emoji/Icon Display

- **Size**: 40x40px container, icon at 18px (full) / 22px (compact)
- **Background**: Transparent
- **Alignment**: Centered in container

### Pin Indicator

- **Position**: Right end of channel item row (full mode)
- **Icon**: Phosphor star Fill (20px), rotated 15°, `#CE2161`
- **Compact pinned**: icon shown inside a 32×32px `#CE2161` circle (overridden by selected state)

### Message Preview

- **Font Size**: 10px
- **Color**: `#00171F` at 70% opacity (unselected) / white at 70% (selected)
- **Lines**: Single line with ellipsis
- **Content**: Shows newest note in the channel
- **Updates**: Real-time via WebSocket
- **Smart Display**:
  - If note has text content: Show text with whitespace collapsed
  - If media-only (no text): Show "Image: filename.jpg" or "3 files"
  - If link-only: Show "Link: Page Title"
  - If completely empty: Hide preview line (no empty space)

## Channel List Design

### Drag-to-Reorder

- **Trigger**: Long-press on a channel item to start drag
- **Constraint**: Pinned channels reorder only among pinned; unpinned only among unpinned
- **Persistence**: Order saved via `sortOrder` field on Channel model and `reorderChannels` endpoint
- **Widget**: `ReorderableListView` with `ReorderableDelayedDragStartListener`

### Keyboard/Swipe Navigation

- **Web/Desktop**: Left/right arrow keys cycle through channels (when no text field is focused)
- **Mobile**: Horizontal swipe gestures cycle through channels
- **Auto-scroll**: Sidebar scrolls to center the newly active channel (250ms easeInOut)

## Context Menus

### Note Context Menu

- **Desktop**: Right-click on a note
- **Mobile**: Long-press enters **selection mode** instead of showing a context menu (see Selection Mode section)
- **Menu Position**: Appears at cursor position on desktop; center of overlay if no position
- **Menu Options** (regular channel):
  1. Copy — copies note content to clipboard, shows toast
  2. Edit — enters edit mode (populates input bar)
  3. Archive — soft-deletes the note
  4. Select — enters selection mode with this note selected
- **Menu Options** (archive view):
  1. Copy
  2. Restore — returns note to original channel
  3. Delete — permanently deletes note
  4. Select

### Channel Context Menu

Channel actions are accessed via the **TopBar 3-dot menu** (not the sidebar). See `docs/components/TopBar.md`.

## Selection Mode

### Triggering

- **Mobile**: Long-press any note → enters selection mode with that note selected
- **Desktop**: Right-click a note → "Select" menu item

### Behavior

- **TopBar transforms**: replaces normal bar with `[xCircle cancel]` + `[N selected]` + `[archive button]`
- **Note appearance**: each note shows a `PhosphorIcons.circle()` / `PhosphorIcons.checkCircle()` checkbox on the left (pink, `#CE2161`)
- **Toggle**: Tap a note in selection mode to toggle its checkbox
- **Cancel**: Tap xCircle in TopBar to exit selection mode
- **Bulk archive**: Tap archive icon in TopBar → archives all selected notes, clears selection, shows toast

### Selection Checkbox Icons

| State | Icon |
|-------|------|
| Unselected | `PhosphorIcons.circle()` |
| Selected | `PhosphorIcons.checkCircle()` |

Both at 24px, `#CE2161` color.

## Settings and Archive Pages (Detail Mode)

### What is Detail Mode

When the user opens Settings or navigates to the Archive Crate, the app enters **detail mode**:

- The sidebar and media sidebar are **hidden**
- The TopBar shows a **back button** (`PhosphorIcons.arrowCircleLeft()`) on the left + plain text title ("Settings" or "Archive")
- The content area expands to full width

### Transition Animation

Content transitions use a **220ms fade animation** (`AnimatedSwitcher` with `FadeTransition`). Three distinct keys are used:

- `'settings'` — settings view
- `'archive'` — archive crate
- `'chat'` — normal channel chat

### Back Navigation

- **From Settings**: hides the settings overlay, returns to the previously viewed channel
- **From Archive**: restores the channel recorded in `previousChannelProvider` (set when navigating to archive), falls back to the first non-system channel

### Input Bar

The input bar is **hidden** in detail mode (archive and settings).

## Chat View

### Note Ordering

- **Newest at bottom**: Natural chat progression
- **Oldest at top**: Scroll up to see history
- **Auto-scroll**: New notes appear at bottom
- **Pagination**: Loads older notes when scrolling near top (cursor-based)

### Note Cards — Regular Channel

- **Background**: `#F6F0ED` (core.surface)
- **Border**: 1px `#CE2161` (brand.primary)
- **Border radius**: 0px (sharp corners)
- **Padding**: 12px all sides
- **No shadow**
- **Max width**: 75% of screen width
- **Outer padding**: 14px horizontal, 6px vertical between cards

**Media-only notes** (attachments but no text) render without the container — no border or background, just the media + footer floating directly.

**Content inside card**:
- Markdown-formatted text with link support
- Media attachments (images, videos, documents)
- Link preview cards

### Note Footer (always visible)

The note footer is permanently visible below each note card. No hover state required.

| Icon | Archive mode | Regular mode |
|------|-------------|--------------|
| Edit (`pencilSimple`) | hidden | visible |
| Copy (`copySimple`) | visible | visible |
| Archive/Restore (`archive` / `arrowCounterClockwise`) | restore | archive |
| Share (`shareNetwork`) | visible | visible |

All footer icons: 20px, `#00171F` at 50% opacity.

## Input Behavior

### Keyboard Shortcuts

- **Enter**: Submit note (via `Shortcuts`/`Actions` with `SingleActivator`)
- **Shift+Enter**: Insert new line (TextField multiline behavior)
- **Enter in FileUploadDialog**: Submits the upload (also via `Shortcuts`/`Actions`)
- **Ctrl+V / Cmd+V**: Paste text in text field (file paste detected when not focused)

### Visual Feedback

- Send icon (`paperPlaneRight`) appears when text is non-empty; attachment/camera visible when empty
- **Edit mode**: Cancel (`xCircle`) + Save (`highlighter`) icons both on the **right side** of the text field
- Save icon dimmed at 40% opacity when text field is empty

### Channel Drafts

- **Per-Channel State**: Each channel maintains its own input draft
- **Auto-Save**: Text is automatically saved when switching channels
- **Auto-Load**: Switching back to a channel restores the draft
- **Clear on Send**: Draft is cleared after successfully sending
- **Storage**: In-memory only (not persisted on app restart)
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
- No mixed interaction patterns (all use Material/InkWell or GestureDetector+AnimatedContainer)
- Sharp corners throughout (0px border radius on note cards, dialogs)

### Clarity

- Light surface (`#F6F0ED`) with `#CE2161` borders for definition
- Clear visual hierarchy (name bold, preview muted)
- Adequate spacing prevents crowding

### Efficiency

- Quick actions via context menus (desktop) or selection mode (mobile)
- Keyboard shortcuts for common operations
- Real-time updates eliminate manual refreshes

### Accessibility

- Right-click (desktop) and long-press (mobile → selection mode) for note actions
- Visual feedback for all interactions
- Clear selection states with checkboxes
