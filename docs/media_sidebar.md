# Media Sidebar

## Overview

A right-side sidebar that displays all media and links from the current channel, organized into tabs for easy browsing. Visible on desktop, hidden on mobile with menu access.

## Requirements

### Functional Requirements

1. **Tab Navigation**
   - Four tabs: IMAGES | VIDEOS | DOCUMENTS | LINKS
   - Active tab highlighted with underline
   - Switching tabs filters content without refetching

2. **Content Display**
   - **IMAGES**: Grid of image thumbnails (3 columns on desktop, 2 on smaller screens)
   - **VIDEOS**: Grid of video thumbnails with play icon overlay (3 columns)
   - **DOCUMENTS**: Grid of document cards with file icon, name, size (2 columns)
   - **LINKS**: Vertical list of link preview cards (full width)

3. **Interaction**
   - Click image/video: Open in lightbox/modal viewer
   - Click document: Download file
   - Click link: Open in new tab
   - Hover: Show tooltip with filename/title and date

4. **Responsive Behavior**
   - **Desktop (≥1200px)**: Always visible, 300px width, resizable 250-400px
   - **Tablet (768-1199px)**: Hidden by default, toggle via button in chat header
   - **Mobile (<768px)**: Hidden, open as bottom sheet via button

5. **Empty States**
   - Show placeholder message when tab has no content
   - E.g., "No images in this channel yet"

6. **Performance**
   - Virtualized scrolling for large collections (>50 items)
   - Lazy load thumbnails as user scrolls
   - Cache media URLs to avoid refetching

### Non-Functional Requirements

1. **Real-time Updates**: Media appears when notes are created via WebSocket
2. **Loading States**: Skeleton loaders while fetching
3. **Error Handling**: Show error message if media fails to load
4. **Accessibility**: Keyboard navigation, ARIA labels, screen reader support

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

2. **Models**:
   ```dart
   class ChannelMedia {
     List<MediaItem> images;
     List<MediaItem> videos;
     List<MediaItem> documents;
     List<LinkItem> links;
   }

   class MediaItem {
     int noteId;
     MediaAttachment attachment;
     DateTime createdAt;
     String noteContent; // For context
   }

   class LinkItem {
     int noteId;
     LinkPreview preview;
     DateTime createdAt;
     String noteContent; // Original text with link
   }
   ```

3. **State Management**:
   - Current tab: Local state in `MediaSidebar`
   - Sidebar visibility (mobile): Global state `mediaSidebarVisibleProvider`

### File Structure

```
lib/
├── models/
│   └── channel_media.dart (new)
├── providers/
│   ├── channel_media_provider.dart (new)
│   └── media_sidebar_visible_provider.dart (new)
├── widgets/
│   ├── media_sidebar.dart (new)
│   ├── media_grid.dart (new)
│   ├── media_grid_item.dart (new)
│   ├── link_list.dart (new)
│   ├── link_list_item.dart (new)
│   └── media_viewer_dialog.dart (new - lightbox)
└── utils/
    └── responsive_utils.dart (new - breakpoint helpers)
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
│  │ 📷 │ │ 📷 │ │ 📷 │  │ ← Grid (images/videos)
│  └────┘ └────┘ └────┘  │
│  ┌────┐ ┌────┐ ┌────┐  │
│  │ 📷 │ │ 📷 │ │ 📷 │  │
│  └────┘ └────┘ └────┘  │
│         ...             │
├─────────────────────────┤
│  Scrollable content     │
└─────────────────────────┘
```

### Mobile Button

- Floating action button in chat header (top right)
- Icon: `Icons.photo_library` or `Icons.collections`
- Opens bottom sheet with MediaSidebar content

## Implementation Plan

### Phase 1: Data Layer (2-3 hours)

1. **Create Models** (`channel_media.dart`)
   - `ChannelMedia` class with lists for each media type
   - `MediaItem` and `LinkItem` classes

2. **Create Provider** (`channel_media_provider.dart`)
   - Family provider: `channelMediaProvider(channelId)`
   - Watch `notesProvider(channelId)`
   - Filter and transform notes into `ChannelMedia`
   - Sort by createdAt descending (newest first)

3. **Responsive Utilities** (`responsive_utils.dart`)
   - Breakpoint constants: `mobileBreakpoint = 768`, `tabletBreakpoint = 1200`
   - Helper methods: `isMobile(context)`, `isTablet(context)`, `isDesktop(context)`

### Phase 2: Core UI (3-4 hours)

4. **Media Sidebar Widget** (`media_sidebar.dart`)
   - Tab controller with 4 tabs
   - Conditional rendering based on active tab
   - Handle empty states
   - Resizable on desktop (drag handle on left edge)

5. **Media Grid** (`media_grid.dart`, `media_grid_item.dart`)
   - GridView with responsive column count
   - Image: Show thumbnail with aspect ratio preservation
   - Video: Thumbnail + duration overlay + play icon
   - Document: File icon + filename + size
   - Hover effects and click handlers

6. **Link List** (`link_list.dart`, `link_list_item.dart`)
   - ListView of link preview cards
   - Show favicon, title, description, URL
   - Click to open in new tab

### Phase 3: Integration (2-3 hours)

7. **Update Main Layout** (`main.dart` or root widget)
   - Add MediaSidebar to layout
   - Responsive logic: Show/hide based on screen width
   - Mobile: Add FAB to chat view, show bottom sheet

8. **Media Viewer Dialog** (`media_viewer_dialog.dart`)
   - Lightbox for images/videos
   - Navigate between items (prev/next buttons)
   - Close on tap outside or ESC key

9. **State Management** (`media_sidebar_visible_provider.dart`)
   - Global provider for sidebar visibility on mobile/tablet
   - Persist preference in SharedPreferences

### Phase 4: Polish (1-2 hours)

10. **Loading States**
    - Skeleton loaders for grid items
    - Shimmer effect while loading

11. **Error Handling**
    - Retry button if media fails to load
    - Fallback icon for broken thumbnails

12. **Performance Optimization**
    - Implement virtualized scrolling if needed
    - Image caching strategy

## Edge Cases

1. **Note with multiple attachments**: Each attachment appears as separate grid item
2. **Note with both attachment and link**: Appears in both relevant tabs
3. **Deleted media**: Remove from grid when note deleted (via WebSocket)
4. **Large files**: Show file size, warn before download
5. **Video thumbnails**: Use server-generated thumbnail or video first frame
6. **External vs uploaded media**: Links tab shows external URLs, others show uploaded files

## Testing Checklist

- [ ] All four tabs render correctly
- [ ] Grid displays images/videos/documents with correct layout
- [ ] Link list shows link previews
- [ ] Clicking items opens viewer/downloads/navigates
- [ ] Responsive: Sidebar hides on mobile/tablet
- [ ] Mobile: FAB opens bottom sheet
- [ ] Desktop: Sidebar is resizable
- [ ] Real-time: New media appears instantly
- [ ] Empty states show appropriate messages
- [ ] Loading states display during fetch
- [ ] Error states show retry button
- [ ] Keyboard navigation works
- [ ] Screen reader announces content

## Future Enhancements

1. **Search/Filter**: Search bar to filter media by filename
2. **Sorting**: Sort by date, name, size
3. **Bulk Actions**: Select multiple items to download as ZIP
4. **Media Upload**: Drag-drop directly into sidebar to upload
5. **Thumbnail Generation**: Server-side thumbnail generation for documents (PDF preview)
6. **Video Playback**: Inline video player in lightbox
7. **Image Editing**: Basic crop/rotate before sharing
8. **Analytics**: Track which media types are most viewed

## Technical Considerations

### Thumbnail URLs

Use existing MediaAttachment structure:
- `filePath`: Full-size file path
- `thumbnailPath`: Thumbnail for images/videos (already generated server-side)
- Construct URL: `$serverUrl/media/$filePath` or `$serverUrl/media/$thumbnailPath`

### WebSocket Updates

Listen to `chatStreamProvider` events:
- `noteCreated`: Check for attachments/links, update media lists
- `noteDeleted`: Remove media items associated with note
- `noteUpdated`: Re-evaluate media (shouldn't change often)

### Memory Management

For large channels with many media items:
- Use `ListView.builder` or `GridView.builder` for lazy rendering
- Consider pagination: Load first 50, fetch more on scroll
- Clear cached images when switching channels

### Accessibility

- Tab bar: Arrow keys to navigate tabs
- Grid: Arrow keys to navigate items, Enter to open
- Lightbox: ESC to close, Arrow keys for prev/next
- ARIA labels: "Images tab, X items", "Open image: filename.jpg"
- Focus management: Focus first item when switching tabs

## Open Questions

1. **Thumbnail size**: What dimensions for thumbnails? (e.g., 100x100px?)
2. **Video handling**: Should we support inline playback or always open in lightbox?
3. **Document previews**: Generate PDF thumbnails server-side or show generic icon?
4. **Link validation**: Should we re-fetch link previews periodically to update metadata?
5. **Drag handle**: Should sidebar be collapsible to icon-only mode (like left sidebar)?
