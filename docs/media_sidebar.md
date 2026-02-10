# Media Sidebar

**Status**: Implemented

## Overview

A right-side sidebar that displays all media and links from the current channel, organized into tabs for easy browsing. Visible on desktop, hidden on mobile with menu access.

## Features

### Tab Navigation
- Four tabs: IMAGES | VIDEOS | DOCUMENTS | LINKS
- Active tab highlighted with underline
- Switching tabs filters content without refetching

### Content Display
- **IMAGES**: Grid of image thumbnails (3 columns on desktop, 2 on smaller screens)
- **VIDEOS**: Grid of video thumbnails with play icon overlay (3 columns)
- **DOCUMENTS**: Grid of document cards with file icon, name, size (2 columns)
- **LINKS**: Vertical list of link preview cards (full width)

### Interaction
- Click image/video: Open in lightbox/modal viewer
- Click document: Download file
- Click link: Open in new tab
- Hover: Show tooltip with filename/title and date

### Responsive Behavior
- **Desktop (>=1200px)**: Always visible, 300px width, resizable 250-400px
- **Tablet (768-1199px)**: Hidden by default, toggle via button in chat header
- **Mobile (<768px)**: Hidden, open as bottom sheet via button

### Empty States
- Placeholder message when tab has no content
- E.g., "No images in this channel yet"

### Real-time Updates
- Media appears when notes are created via WebSocket
- Items removed when notes are deleted

## Architecture

### Component Hierarchy

```
MediaSidebar
├── TabBar (IMAGES | VIDEOS | DOCUMENTS | LINKS)
├── MediaGrid (for IMAGES/VIDEOS/DOCUMENTS)
│   ├── MediaGridItem (thumbnail + metadata)
│   └── EmptyState
└── LinkList (for LINKS)
    ├── LinkListItem (preview card)
    └── EmptyState
```

### Data Flow

1. **Provider**: `channelMediaProvider(channelId)` - family provider
   - Watches `notesProvider(channelId)`
   - Filters notes client-side by media type
   - Returns structured data: `ChannelMedia` with separate lists

2. **State Management**:
   - Current tab: Local state in `MediaSidebar`
   - Sidebar visibility (mobile): Global state `mediaSidebarVisibleProvider`

### File Structure

```
lib/
├── models/
│   └── channel_media.dart
├── providers/
│   ├── channel_media_provider.dart
│   └── media_sidebar_visible_provider.dart
├── widgets/
│   ├── media_sidebar.dart
│   ├── media_grid.dart
│   ├── media_grid_item.dart
│   ├── link_list.dart
│   ├── link_list_item.dart
│   └── media_viewer_dialog.dart
└── utils/
    └── responsive_utils.dart
```

## UI Design

### Layout

```
┌─────────────────────────────────────────────────────────┐
│ Left Sidebar │       Chat View        │ Right Sidebar   │
│   (Channels) │                        │  (Media)        │
│              │                        │                 │
│   60-250px   │      Flexible          │    300px        │
└─────────────────────────────────────────────────────────┘
```

### Media Sidebar Design

```
┌─────────────────────────┐
│ IMAGES VIDEOS DOCS LINKS│ ← Tab bar
├─────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐  │
│  │    │ │    │ │    │  │ ← Grid (images/videos)
│  └────┘ └────┘ └────┘  │
│  ┌────┐ ┌────┐ ┌────┐  │
│  │    │ │    │ │    │  │
│  └────┘ └────┘ └────┘  │
│         ...             │
├─────────────────────────┤
│  Scrollable content     │
└─────────────────────────┘
```

## Design Decisions

- **Thumbnail size**: Server-generated thumbnails used for images; generic icons for documents
- **Video handling**: Opens in lightbox viewer
- **Document previews**: Generic file type icon (no server-side PDF thumbnail generation)
- **Link validation**: Previews fetched once at note creation time, not re-fetched
- **Sidebar**: Resizable with drag handle, not collapsible to icon-only mode

## Edge Cases

1. **Note with multiple attachments**: Each attachment appears as separate grid item
2. **Note with both attachment and link**: Appears in both relevant tabs
3. **Deleted media**: Removed from grid when note deleted (via WebSocket)
4. **Large files**: Show file size, warn before download
5. **External vs uploaded media**: Links tab shows external URLs, others show uploaded files

## Technical Considerations

### Thumbnail URLs

Uses existing MediaAttachment structure:
- `filePath`: Full-size file path
- `thumbnailPath`: Thumbnail for images (already generated server-side)
- Construct URL: `$serverUrl/media/$filePath` or `$serverUrl/media/$thumbnailPath`

### WebSocket Updates

Listens to `chatStreamProvider` events:
- `noteCreated`: Check for attachments/links, update media lists
- `noteDeleted`: Remove media items associated with note
- `noteUpdated`: Re-evaluate media

### Memory Management

For large channels with many media items:
- `ListView.builder` / `GridView.builder` for lazy rendering
- Image caching strategy
- Clear cached images when switching channels

### Accessibility

- Tab bar: Arrow keys to navigate tabs
- Grid: Arrow keys to navigate items, Enter to open
- Lightbox: ESC to close, Arrow keys for prev/next
- ARIA labels for screen reader support
- Focus management when switching tabs

## Future Enhancements

1. **Search/Filter**: Search bar to filter media by filename
2. **Sorting**: Sort by date, name, size
3. **Bulk Actions**: Select multiple items to download as ZIP
4. **Media Upload**: Drag-drop directly into sidebar to upload
5. **Thumbnail Generation**: Server-side thumbnail generation for documents (PDF preview)
6. **Video Playback**: Inline video player in lightbox
7. **Image Editing**: Basic crop/rotate before sharing
