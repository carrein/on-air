# MediaSidebar

## Overview

The MediaSidebar is a right-side panel that displays all media and links from the current channel, organized into four tabs. It provides quick browsing of images, videos, documents, and links without scrolling through the chat history. Clicking a media item scrolls the chat view to the note containing it.

**File**: `memoka_flutter/lib/widgets/media_sidebar.dart`
**Widget**: `MediaSidebar` (ConsumerStatefulWidget)
**State**: `_MediaSidebarState`

## Subcomponents

### Tab Bar

Top navigation bar with four tabs.

- Tabs: `IMAGES` | `VIDEOS` | `DOCS` | `LINKS`
- Active tab label: `#FF52A1` (pink), bold 11px
- Inactive tab label: `Colors.grey[500]`, normal 11px
- Indicator: 3px solid `#FF52A1` underline, `BorderRadius.zero` (sharp corners)
- `dividerHeight: 0` — no separator between tabs and content
- Background: `#00171F` (matches sidebar background)
- Tab count is NOT shown in tab headers

### Image Grid (`MediaGrid` + `MediaGridItem`)

Grid of image thumbnails from the channel.

- **File**: `lib/widgets/media_grid.dart`, `lib/widgets/media_grid_item.dart`
- Layout: 3-column grid, `childAspectRatio: 1.0` (square cells)
- Spacing: 0px cross-axis, 0px main-axis, no padding
- Cell background: white
- No border radius on cells
- Thumbnails loaded via `Image.network` with `BoxFit.cover`
- Loading state: `Container(color: Colors.grey[200])` with `CircularProgressIndicator(strokeWidth: 2)`
- Error state: grey[100] background with `Icons.broken_image` (32px) + "Failed to load" text (10px)
- Tap: Sets `scrollToNoteProvider` to the note ID, scrolling chat view to that note

### Video Grid (`MediaGrid` + `MediaGridItem`)

Grid of video thumbnails with play overlay.

- Same 3-column square grid layout as images
- Thumbnail loaded from server-generated thumbnail URL
- Play icon overlay: `Icons.play_arrow` (32px, white) in a `BoxShape.circle` container with `Colors.black` at 60% opacity
- Duration badge (if available): bottom-right positioned, black at 70% opacity background, 4px border radius, white bold 10px text in `MM:SS` format
- Fallback (no thumbnail): grey[100] background with `Icons.videocam` (32px) + "No preview" text
- Tap: Sets `scrollToNoteProvider` to scroll to the containing note

### Document Grid (`MediaGrid` + `MediaGridItem`)

Grid of document cards with file icon and metadata.

- Same 3-column square grid layout
- Padding: 4px horizontal, 8px vertical (tight to maximize filename space)
- File type icon: 36px, `Colors.grey[700]`, determined by `FileUtils.getFileIcon(extension)`
- Filename: 10px, `FontWeight.w500`, max 2 lines, center-aligned, ellipsis overflow
- File size: 9px, `Colors.grey[600]`, formatted by `FileUtils.formatFileSize()`
- Tap: Sets `scrollToNoteProvider` to scroll to the containing note

### Link List (`LinkList` + `LinkListItem`)

Vertical list of link preview cards.

- **File**: `lib/widgets/link_list.dart`, `lib/widgets/link_list_item.dart`
- Layout: `ListView.separated` with 12px padding and 12px separator
- Card style: white background, 8px border radius, 1px `grey[300]` border, 12px padding
- Favicon: 16px, loaded from `link.faviconUrl`, fallback: `Icons.language` (16px, grey[600])
- Title: 13px, `FontWeight.w600`, black87, max 2 lines
- Open icon: `Icons.open_in_new` (14px, grey[500])
- Description: 11px, grey[700], max 2 lines (or URL if no preview)
- URL domain: 10px, `Colors.blue[700]`, shown below description if full preview exists
- Date: 10px, grey[500], relative format ("5m ago", "3h ago", "2d ago", or "M/D/YYYY")
- Tap: Opens URL in external browser via `url_launcher`

### Empty States

Each tab shows a centered placeholder when empty.

- Icon: 64px, `Colors.grey[400]`
  - Images: `Icons.image_outlined`
  - Videos: `Icons.videocam_outlined`
  - Documents: `Icons.description_outlined`
  - Links: `Icons.link_off`
- Message: 14px, grey[600], center-aligned
  - "No images in this channel yet"
  - "No videos in this channel yet"
  - "No documents in this channel yet"
  - "No links in this channel yet"

## Styling

### Color Palette

| Token             | Value       | Usage                                    |
|-------------------|-------------|------------------------------------------|
| Background        | `#00171F`   | Sidebar and tab bar background           |
| Tab active        | `#FF52A1`   | Active tab label and indicator           |
| Tab inactive      | `grey[500]` | Inactive tab label                       |
| Grid cell         | `#FFFFFF`   | Image/video/document cell background     |
| Link card         | `#FFFFFF`   | Link list item background                |
| Link card border  | `grey[300]` | Link list item border                    |

### Typography

| Element            | Size | Weight | Color                |
|--------------------|------|--------|----------------------|
| Tab label (active) | 11px | Bold   | `#FF52A1`            |
| Tab label (inactive)| 11px| Normal | `grey[500]`          |
| Document filename  | 10px | w500   | Default (dark)       |
| Document file size | 9px  | Normal | `grey[600]`          |
| Link title         | 13px | w600   | `black87`            |
| Link description   | 11px | Normal | `grey[700]`          |
| Link URL           | 10px | Normal | `blue[700]`          |
| Link date          | 10px | Normal | `grey[500]`          |
| Error message      | 10px | Normal | `grey[500]`          |
| Empty state message| 14px | Normal | `grey[600]`          |

### Dimensions

| Token              | Value         | Usage                           |
|--------------------|---------------|---------------------------------|
| Sidebar width      | 300px         | Fixed width (when `fixedWidth: true`) |
| Grid columns       | 3             | All media grids                 |
| Grid spacing       | 0px           | Cross-axis and main-axis        |
| Grid aspect ratio  | 1.0           | Square cells                    |
| Doc cell padding   | H: 4px, V: 8px | Document card inner padding   |
| Doc icon size      | 36px          | File type icon                  |
| Link list padding  | 12px          | ListView outer padding          |
| Link separator     | 12px          | Gap between link cards          |
| Link card padding  | 12px          | Card inner padding              |
| Link card radius   | 8px           | Card border radius              |
| Tab indicator      | 3px           | Underline thickness             |

## Interactions

### Click-to-Scroll (Media Grid Items)

Clicking any image, video, or document in the grid scrolls the chat view to the note that contains it.

- Sets `scrollToNoteProvider` state to the `noteId` of the clicked item
- `ChatView` listens to `scrollToNoteProvider` and calls `_itemScrollController.scrollTo()` using `scrollable_positioned_list`
- Target note is highlighted with a pink tint (`AnimatedContainer`) for 2 seconds
- Works for any distance — uses index-based scrolling (not GlobalKey), so it handles virtualized off-screen items
- Scroll alignment: `0.0` (top of viewport)
- Scroll animation: 300ms `Curves.easeOut`
- Physics: `ClampingScrollPhysics` (no overshoot bounce on last item)

### Click Link

- Opens URL in external browser via `url_launcher` (`LaunchMode.externalApplication`)
- Shows snackbar on failure

### Tab Switching

- `TabController` with 4 tabs, local state
- Switching tabs filters displayed content (no refetch, data already in memory)
- Content comes from `channelMediaDataProvider` which derives from `notesProvider`

## State Management

### Providers Watched (reactive)

| Provider                        | Type                        | Purpose                           |
|---------------------------------|-----------------------------|-----------------------------------|
| `currentChannelProvider`        | `AsyncValue<int?>`          | Current channel ID                |
| `channelMediaDataProvider(id)`  | `AsyncValue<ChannelMedia>`  | Organized media for the channel   |

### Providers Read (on interaction)

| Provider                     | Usage                                    |
|------------------------------|------------------------------------------|
| `scrollToNoteProvider.notifier` | Set note ID to trigger chat scroll     |

### Local Widget State

| Field             | Type             | Purpose                       |
|-------------------|------------------|-------------------------------|
| `_tabController`  | `TabController`  | Controls tab navigation       |

## Data Flow

1. `MediaSidebar` watches `currentChannelProvider` to get the active channel
2. Watches `channelMediaDataProvider(channelId)` which internally watches `notesProvider(channelId)`
3. `ChannelMediaData` provider filters notes client-side into `ChannelMedia` with separate lists:
   - Images: attachments where `mimeType.startsWith('image/')`
   - Videos: attachments where `mimeType.startsWith('video/')`
   - Documents: all other attachments
   - Links: URLs extracted from note content via regex, matched with `LinkPreview` if available
4. All lists sorted by `createdAt` descending (newest first)
5. Grids and lists render from these pre-sorted lists

## Data Models

### ChannelMedia

Aggregated media container returned by the provider.

```dart
class ChannelMedia {
  final List<MediaItem> images;
  final List<MediaItem> videos;
  final List<MediaItem> documents;
  final List<LinkItem> links;
}
```

### MediaItem

Represents a single media attachment from a note.

```dart
class MediaItem {
  final int noteId;
  final MediaAttachment attachment;
  final DateTime createdAt;
  final String noteContent;

  String getMediaUrl(String serverUrl);
  String? getThumbnailUrl(String serverUrl);
  bool get isImage;   // mimeType.startsWith('image/')
  bool get isVideo;   // mimeType.startsWith('video/')
  bool get isDocument; // !isImage && !isVideo
}
```

### LinkItem

Represents a link extracted from note content.

```dart
class LinkItem {
  final int noteId;
  final LinkPreview preview;
  final DateTime createdAt;
  final String noteContent;

  String get url;
  String get displayTitle;  // preview.title or domain fallback
  String? get description;
  bool get hasFullPreview;
  String? get faviconUrl;
}
```

## Component Hierarchy

```
MediaSidebar
├── TabBar (IMAGES | VIDEOS | DOCS | LINKS)
├── TabBarView
│   ├── MediaGrid (images)
│   │   └── MediaGridItem[] (thumbnail, BoxFit.cover)
│   ├── MediaGrid (videos)
│   │   └── MediaGridItem[] (thumbnail + play overlay + duration)
│   ├── MediaGrid (documents)
│   │   └── MediaGridItem[] (file icon + filename + size)
│   └── LinkList
│       └── LinkListItem[] (favicon + title + description + date)
└── EmptyState (per tab, when list is empty)
```

## Real-time Updates

- Media appears/disappears reactively because `channelMediaDataProvider` watches `notesProvider`
- When a note is created/deleted via WebSocket (`chatStreamProvider`), `notesProvider` updates, which triggers `channelMediaDataProvider` to re-derive media lists
- No separate WebSocket listener needed in the sidebar

## Integration

The MediaSidebar is placed as the right-most child in the app's main `Row` layout (in `ChatScreen`). It sits alongside the left Sidebar and the central ChatView. It communicates with the chat view exclusively through Riverpod providers — setting `scrollToNoteProvider` triggers the chat to scroll.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/media_sidebar.dart` | This component (container + tabs) |
| `lib/widgets/media_grid.dart` | Grid layout for images/videos/documents |
| `lib/widgets/media_grid_item.dart` | Individual grid cell (ConsumerWidget) |
| `lib/widgets/link_list.dart` | Link list layout |
| `lib/widgets/link_list_item.dart` | Individual link card |
| `lib/models/channel_media.dart` | ChannelMedia, MediaItem, LinkItem models |
| `lib/providers/channel_media_provider.dart` | Derives media from notes provider |
| `lib/providers/scroll_to_note_provider.dart` | Cross-component scroll trigger |
| `lib/providers/current_channel_provider.dart` | Active channel selection |
| `lib/providers/notes_provider.dart` | Source note data |
| `lib/screens/chat_screen.dart` | Parent layout that hosts the sidebar |
| `lib/widgets/chat_view.dart` | Listens to scroll provider, performs scroll |
| `lib/utils/file_utils.dart` | File icon mapping, size formatting, URL building |
