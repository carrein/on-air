# Design System

Canonical style reference and interaction guidelines for the Memoka app. All component specs and implementations should reference these tokens rather than hard-coding values.

---

## Design Tokens

### Color Palette

#### Core

| Token            | Hex       | RGB              | Usage                                    |
|------------------|-----------|------------------|------------------------------------------|
| `core.background`| `#00171F` | `0, 23, 31`      | Dark surfaces: dialog headers, status bar, info toasts |
| `core.surface`   | `#F6F0ED` | `246, 240, 237`  | All UI surfaces: channel list, navbar, NoteInput, note cards, modals, media panel |
| `core.text`      | `#00171F` | `0, 23, 31`      | All body text on light surfaces          |
| `core.textOnDark`| `#FFFFFF` | `255, 255, 255`  | Text/icons on dark (`core.background`) surfaces |
| `core.textMuted` | `#00171F` @ 60% | —           | Timestamps, secondary text, muted icons, placeholders on light surfaces. Replaces all `Colors.grey[400-700]` usage. |

#### Brand

| Token              | Hex       | RGB              | Usage                                  |
|--------------------|-----------|------------------|----------------------------------------|
| `brand.primary`    | `#CE2161` | `206, 33, 97`    | Selected states, primary actions, borders, tab indicators, date separator background |

#### Semantic

| Token               | Hex / Value          | Usage                          |
|----------------------|----------------------|--------------------------------|
| `semantic.selected`  | `brand.primary`     | Selected channel, active item  |
| `semantic.divider`   | `brand.primary` @ 20% | Tab bar divider lines, section dividers |
| `semantic.link`      | `#0F52BA`           | Links, external URLs, link preview accents. Never use `Colors.blue`. |
| `semantic.error`     | `#DB0000`           | Error text/icons, destructive actions, error toasts. Never use `Colors.red`. |
| `semantic.warning`   | `#FFE236`           | Warning states, caution indicators. Never use `Colors.orange` or `Colors.yellow`. |
| `semantic.success`   | `Colors.green[700]` | Success toasts                 |
| `semantic.info`      | `core.background`   | Info toasts                    |

---

### Typography

#### Font Family

| Token              | Family         | Usage                             |
|--------------------|----------------|-----------------------------------|
| `font.body`        | Space Grotesk  | All text — channel names, note content, UI text, buttons, titles |

Set globally via `GoogleFonts.spaceGrotesk()` in `main.dart`. No secondary font.

#### Font Scale

| Token              | Size  | Weight  | Usage                            |
|--------------------|-------|---------|----------------------------------|
| `type.note`        | 16px  | Normal  | Note content (markdown body), selection bar text |
| `type.body`        | 14px  | Normal  | Channel names, media panel tabs, date separator, general UI text |
| `type.caption`     | 10px  | Normal  | Channel preview text             |

---

### Spacing

| Token         | Value | Usage                                         |
|---------------|-------|-----------------------------------------------|
| `space.xs`    | 4px   | Tight inner gaps                              |
| `space.sm`    | 8px   | Emoji-to-text gap, small padding              |
| `space.md`    | 12px  | Chat view margins, note horizontal padding    |
| `space.lg`    | 16px  | Logo gap, button gap, section padding         |
| `space.xl`    | 20px  | Logo horizontal padding, button right padding |

---

### Borders & Radii

| Token              | Value | Usage                                |
|--------------------|-------|--------------------------------------|
| `radius.note`      | 0px   | Chat bubble corners (sharp)          |
| `radius.pill`      | 50px  | Date separator pills                 |
| `divider.weight`   | 1px   | Sidebar border, navbar border, note card borders |

---

### Effects

| Token                  | Value                     | Usage                       |
|------------------------|---------------------------|-----------------------------|
| `fade.height`          | 60px                      | Sidebar scroll fade overlay |
| `fade.stops`           | 0.0 / 0.5 / 1.0          | Gradient distribution       |

Note cards have no shadow or elevation.

---

### Color Rules

These rules apply to ALL widgets and screens in the app:

1. **All UI surfaces** (note cards, channel list, navbar, NoteInput, modals, settings, link cards, media panel) use `core.surface` (`#F6F0ED`). Never use white (`#FFFFFF`) as a background for app surfaces.

2. **All body text on light surfaces** uses `core.text` (`#00171F`). Never use `Colors.black`, `Colors.black87`, `Colors.black54` etc. for text — always use `Color(0xFF00171F)` or `Color(0xFF00171F).withValues(alpha: X)`.

3. **All borders on light surfaces** use `brand.primary` (`#CE2161`). Never use grey borders for note cards, link cards, or any UI container that has a border. The only exception is neutral drag handles and shimmer placeholders.

4. **All brand/pink accents** (selected indicators, action icons) use `brand.primary` (`#CE2161`). Never use `Colors.blue` for brand actions — use CE2161.

5. **Muted/secondary text and icons** use `Color(0xFF00171F).withValues(alpha: 0.6)` (`core.textMuted`). Never use `Colors.grey[400]`, `Colors.grey[500]`, `Colors.grey[600]`, or `Colors.grey[700]` on light surfaces — always use `core.textMuted`.

6. **Links and external URLs** use `semantic.link` (`#0F52BA`). Never use `Colors.blue` for links.

7. **Error states** use `semantic.error` (`#DB0000`). Never use `Colors.red` or `Colors.redAccent`.

8. **Dark overlays** (lightbox barriers, image overlays, video player backgrounds) may use `Colors.black` with appropriate alpha — these are contextually correct as they overlay media content.

---

### How to Use

**In component specs** (e.g., `docs/components/ChannelList.md`):
Reference tokens by name — e.g., "background uses `core.background`" rather than
repeating `#00171F`.

**In Dart source**:
Define `static const` fields in each widget's state class, grouped by category,
with values matching this document. See `channel_list.dart` for the reference pattern.

---

## Interaction Patterns

### Sidebar (ChannelList)

#### Layout States

The sidebar supports two width states:

- **Compact (mobile — 64px)**: Emoji/icon only, no text or preview
- **Full (desktop/web — 240px)**: Icon + channel name + message preview

#### Spacing & Padding

- **Channel Items**: left 8px, right 18px, top/bottom 10px
- **Icon-to-text Gap**: 8px (full mode only)
- **Pin Icon Gap**: 12px before the star icon

#### Visual Style

- **Background**: `#F6F0ED` (core.surface)
- **Selected channel**: `#CE2161` background, white icon/text
- **Pin indicator** (full mode): Phosphor star icon (20px) rotated 15°, `#CE2161`
- **Pin indicator** (compact, pinned but not selected): icon inside a 32x32px `#CE2161` circle

#### Channel Item Structure (Full)

```
[Icon 40x40] [Channel Name          ] [Pin Star?]
             [Latest Message Preview]
```

#### Channel Item Structure (Compact)

```
    [Icon 22px]
```

#### Emoji/Icon Display

- **Size**: 40x40px container, icon at 18px (full) / 22px (compact)
- **Background**: Transparent
- **Alignment**: Centered in container

#### Pin Indicator

- **Position**: Right end of channel item row (full mode)
- **Icon**: Phosphor star Fill (20px), rotated 15°, `#CE2161`
- **Compact pinned**: icon shown inside a 32x32px `#CE2161` circle (overridden by selected state)

#### Message Preview

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

### Channel List

#### Drag-to-Reorder

- **Trigger**: Long-press on a channel item to start drag
- **Constraint**: Pinned channels reorder only among pinned; unpinned only among unpinned
- **Persistence**: Order saved via `sortOrder` field on Channel model and `reorderChannels` endpoint
- **Widget**: `ReorderableListView` with `ReorderableDelayedDragStartListener`

#### Keyboard/Swipe Navigation

- **Web/Desktop**: Left/right arrow keys cycle through channels (when no text field is focused)
- **Mobile**: Horizontal swipe gestures cycle through channels
- **Auto-scroll**: Sidebar scrolls to center the newly active channel (250ms easeInOut)

### Context Menus

#### Note Context Menu

- **Desktop**: Right-click on a note
- **Mobile**: Long-press enters **selection mode** instead of showing a context menu (see Selection Mode section)
- **Menu Position**: Appears at cursor position on desktop; center of overlay if no position
- **Menu Options** (regular channel):
  1. Copy — copies note content to clipboard, shows toast
  2. Edit — enters edit mode (populates NoteInput)
  3. Archive — soft-deletes the note
  4. Select — enters selection mode with this note selected
- **Menu Options** (archive view):
  1. Copy
  2. Restore — returns note to original channel
  3. Delete — permanently deletes note
  4. Select

#### Channel Context Menu

Channel actions are accessed via the **Navbar 3-dot menu** (not the sidebar). See `docs/components/Navbar.md`.

### Selection Mode

#### Triggering

- **Mobile**: Long-press any note — enters selection mode with that note selected
- **Desktop**: Right-click a note — "Select" menu item

#### Behavior

- **Navbar transforms**: replaces normal bar with `[xCircle cancel]` + `[N selected]` + `[archive button]`
- **Note appearance**: each note shows a `PhosphorIcons.circle()` / `PhosphorIcons.checkCircle()` checkbox on the left (pink, `#CE2161`)
- **Toggle**: Tap a note in selection mode to toggle its checkbox
- **Cancel**: Tap xCircle in Navbar to exit selection mode
- **Bulk archive**: Tap archive icon in Navbar — archives all selected notes, clears selection, shows toast

#### Selection Checkbox Icons

| State | Icon |
|-------|------|
| Unselected | `PhosphorIcons.circle()` |
| Selected | `PhosphorIcons.checkCircle()` |

Both at 24px, `#CE2161` color.

### Settings and Archive Pages (Detail Mode)

#### What is Detail Mode

When the user opens Settings or navigates to the Archive, the app enters **detail mode**:

- The sidebar and media panel are **hidden**
- The Navbar shows a **back button** (`PhosphorIcons.arrowCircleLeft()`) on the left + plain text title ("Settings" or "Archive")
- The content area expands to full width

#### Transition Animation

Content transitions use a **220ms fade animation** (`AnimatedSwitcher` with `FadeTransition`). Three distinct keys are used:

- `'settings'` — settings view
- `'archive'` — archive
- `'chat'` — normal channel chat

#### Back Navigation

- **From Settings**: hides the settings overlay, returns to the previously viewed channel
- **From Archive**: restores the channel recorded in `previousChannelProvider` (set when navigating to archive), falls back to the first non-system channel

#### NoteInput

NoteInput is **hidden** in detail mode (archive and settings).

### Chat View

#### Note Ordering

- **Newest at bottom**: Natural chat progression
- **Oldest at top**: Scroll up to see history
- **Auto-scroll**: New notes appear at bottom
- **Pagination**: Loads older notes when scrolling near top (cursor-based)

#### Note Cards — Regular Channel

- **Background**: `#F6F0ED` (core.surface)
- **Border**: 1px `#CE2161` (brand.primary)
- **Border radius**: 0px (sharp corners)
- **Padding**: 12px all sides
- **No shadow**
- **Max width**: 600px max, 350px min (responsive via `NoteConstraints`)
- **Outer padding**: 14px horizontal, 6px vertical between cards

**Media-only notes** (attachments but no text) render without the container — no border or background, just the media + footer floating directly.

**Content inside card**:
- Markdown-formatted text with link support
- Media attachments (images, videos, documents)
- Link preview cards

#### Note Footer (always visible)

The note footer is permanently visible below each note card. No hover state required.

| Icon | Archive mode | Regular mode | Document-only note |
|------|-------------|--------------|-------------------|
| Edit (`pencilSimple`) | hidden | visible | hidden |
| Copy (`copySimple`) | visible | visible | hidden |
| Archive/Restore (`archive` / `arrowCounterClockwise`) | restore | archive | archive |
| Share (`shareNetwork`) | visible | visible | visible |

All footer icons: 20px, `core.textMuted` (`#00171F` at 60% opacity).

#### Date Separator

- **Background**: `brand.primary` (`#CE2161`)
- **Text**: `#FFFFFF`, 12px, medium weight (w500)
- **Border radius**: 50px (pill)
- **Padding**: 14px horizontal, 6px vertical
- **Margin**: 16px vertical

### Input Behavior

#### Keyboard Shortcuts

- **Enter**: Submit note (via `Shortcuts`/`Actions` with `SingleActivator`)
- **Shift+Enter**: Insert new line (TextField multiline behavior)
- **Enter in FileUploadDialog**: Submits the upload (also via `Shortcuts`/`Actions`)
- **Ctrl+V / Cmd+V**: Paste text in text field (file paste detected when not focused)

#### Visual Feedback

- Send icon (`paperPlaneRight`) appears when text is non-empty; attachment/camera visible when empty
- **Edit mode**: Cancel (`xCircle`) + Save (`highlighter`) icons both on the **right side** of the text field
- Save icon dimmed at 40% opacity when text field is empty

#### Channel Drafts

- **Per-Channel State**: Each channel maintains its own input draft
- **Auto-Save**: Text is automatically saved when switching channels
- **Auto-Load**: Switching back to a channel restores the draft
- **Clear on Send**: Draft is cleared after successfully sending
- **Storage**: In-memory only (not persisted on app restart)
- **Implementation**: `DraftsProvider` with `Map<int, String>` keyed by channel ID

### Real-time Updates

#### Live Features

- New channels appear instantly
- Channel updates (name, emoji, pin) reflect immediately
- Message previews update as notes are posted
- Divider appears/disappears as channels are pinned/unpinned

#### WebSocket Integration

- All changes broadcast to connected clients
- No page refresh needed
- Optimistic updates for better UX

### Toast Notifications

#### Design System

- **Position**: Top-right corner of viewport
- **Stacking**: Up to 3 toasts visible simultaneously
- **Auto-Dismiss**: 2500ms duration, then fade out (800ms animation)
- **Overflow Behavior**: When 4th toast appears, oldest is removed
- **Animation**: Fade in (300ms), repositioning when dismissed

#### Toast Types

1. **Error** (`semantic.error` `#DB0000` background):
   - Upload failures
   - Delete constraints (e.g., "Cannot delete last channel")
   - Network errors
2. **Success** (`semantic.success` green background):
   - File upload completed
   - Actions completed successfully
3. **Info** (`core.background` `#00171F` background):
   - Copy confirmation: "Copied: [preview]"
   - General notifications

#### Implementation

- **Utility**: `ToastUtils.show(context, message, {type, duration})`
- **Technology**: `OverlayEntry` with `AnimatedPositioned` and `FadeTransition`
- **State Management**: `List<_NotificationData>` tracks active toasts with `ValueNotifier<double>` for positioning
- **Replaced**: All `SnackBar` usage converted to toast system for consistency

### Full-Screen Image Viewer (Lightbox)

#### Gallery Navigation

- **Open**: Click any inline image to open the lightbox
- **Gallery mode**: All images in the current chat are navigable as a gallery
- **Navigation**: Left/right arrow buttons, keyboard arrow keys, swipe gestures
- **Counter**: Shows "X / Y" indicator for current position in gallery
- **Close**: Click backdrop, press Escape, or tap close button
- **Implementation**: Dialog overlay (`FullScreenImageView.show()`)

#### Video Lightbox

- **Open**: Click any inline video thumbnail to open the video lightbox
- **Dialog**: Full-screen dialog overlay (not a route), `Colors.black` at 92% opacity backdrop
- **Controls**: Play/pause button, progress bar with seek, duration display
- **Keyboard**: Space to play/pause, Escape to close
- **Implementation**: `_VideoLightbox.show()` in `video_attachment_widget.dart`

### Chat Backgrounds

#### Background Picker

- Accessible via Settings overlay — Background Picker screen
- Selection of themed background patterns (flower, food, gift, leaves, light, memphis, morocco, pentagon, sakura, sun, terrazzo, tree, wheat, wormz)
- Selected background is applied behind the chat view
- Persisted via `BackgroundProvider` with Riverpod state management

### Media Panel

- **Width**: 340px (fixed on desktop), full-width in bottom sheet on mobile
- **Background**: `core.surface` (`#F6F0ED`)
- **Left border**: 1px `brand.primary` (`#CE2161`)
- **Tabs**: Images, Videos, Docs, Links (Titlecase, 14px)
- **Selected tab**: `brand.primary` with 3px underline indicator
- **Unselected tab**: `core.textMuted`
- **Tab divider**: `brand.primary` @ 20%, 1px
- **Empty state**: 32px icon + "No images" / "No videos" / "No documents" / "No links" in `core.textMuted`
- **Default visibility**: Open on web, closed on native

### Media Loading Behavior

#### Shimmer Placeholders

- **Pre-sized**: Placeholders use server-provided `width` and `height` metadata to match the final image dimensions exactly
- **No layout jump**: Since the placeholder is the same size as the loaded image, the chat list doesn't shift when images finish loading
- **Animated shimmer**: Grey gradient sweep (grey[800] -> grey[700] -> grey[800]) with 1200ms cycle, 8px rounded corners
- **Fallback**: If dimensions are unavailable, defaults to 300x200

#### Scroll Virtualization

- Flutter's `ListView` disposes off-screen widgets; scrolling back re-creates them
- `CachedNetworkImage` reads from disk cache but still shows a placeholder during the read
- **Mitigation**: Pre-sized shimmer + 150ms fade-in makes cache reads feel instant (vs default 500ms spinner)

#### Media Panel Images

- **Full resolution**: Media panel loads full-res images (not thumbnails) with `cacheWidth: 400` for memory efficiency
- **Implementation**: `Image.network` with `cacheWidth: 400` in `MediaGridItem`

#### Size Constraints

- **Images**: Max 600x500, aspect ratio preserved via `computeDisplaySize()`
- **Video thumbnails**: Max 400x300, same aspect-ratio logic
- **Error widgets**: Sized identically to the placeholder so layout stays stable

---

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

- Right-click (desktop) and long-press (mobile — selection mode) for note actions
- Visual feedback for all interactions
- Clear selection states with checkboxes
