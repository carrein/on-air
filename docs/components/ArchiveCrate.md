# Archive Crate

## Overview

The Archive Crate is the soft-delete destination for both notes and channels. It appears as a special sidebar entry (channelId `-1`) that displays a mixed chronological list of archived notes and archived channels. Items can be restored to their original location or permanently deleted from the Archive Crate.

**Files**:
- `memoka_flutter/lib/widgets/chat_view.dart` (archive view rendering within ChatView)
- `memoka_flutter/lib/providers/archive_items_provider.dart` (data provider)
- `memoka_server/lib/src/chat/chat_endpoint.dart` (server endpoints)
- `memoka_server/lib/src/chat/archive_item.spy.yaml` (protocol model)

**Widget**: Archive view is rendered inside `ChatView` (ConsumerStatefulWidget) when `channelId == -1`
**State**: `_ChatViewState`

## Data Model

### ArchiveItem (protocol model, non-table)

| Field       | Type       | Description                                |
|-------------|------------|--------------------------------------------|
| `type`      | `String`   | `"note"` or `"channel"`                    |
| `note`      | `Note?`    | The archived note (when type is "note")    |
| `channel`   | `Channel?` | The archived channel (when type is "channel") |
| `archivedAt`| `DateTime` | Timestamp for chronological sorting        |

### Channel archiving fields

| Field        | Type        | Default | Description                        |
|--------------|-------------|---------|------------------------------------|
| `archived`   | `bool`      | `false` | Whether the channel is archived    |
| `archivedAt` | `DateTime?` | `null`  | When the channel was archived      |

Key distinction from note archiving: when a channel is archived, its notes stay with their original `channelId`. They are NOT moved to channelId `-1`. Only individual note archiving uses the `-1` channelId convention.

## Subcomponents

### Archive Crate Sidebar Button

Entry point in the sidebar for navigating to the Archive Crate.

- SVG icon (recycle.svg, 28x28px) + "Archive Crate" text in Combo font (16px, white)
- Padding: left 16px, right 20px, top/bottom 16px
- Gap between icon and text: 16px
- Selected state: background changes to `#CE2161` when channelId is `-1`
- Located below the "New Channel" button in the sidebar

### Mixed Archive List

Top-to-bottom `ListView.builder` (non-reversed) displaying both archived notes and archived channels sorted by `archivedAt` descending (newest first).

- Watches `archiveItemsProvider` instead of `notesProvider`
- Each item renders as either a note item or a channel item based on `ArchiveItem.type`
- Empty state: same "All Caught Up!" card as regular channels (white container, pink border, checkmark SVG)

### Archived Note Item

Reuses the existing `_buildNoteItem()` with `channelId == -1`. Behavior in archive context:

- White container with `#CE2161` border (1px)
- Content: markdown text, media attachments, link previews (same as regular notes)
- Timestamp displayed below content
- **Restore button** (restore.svg, 24x24px) positioned 12px to the right of the note container
- Restore button tooltip: "Restore note"
- **Cancel button** (cancel.svg, 24x24px) positioned 8px to the right of the restore button
- Cancel button tooltip: "Delete note"
- Cancel button permanently deletes the note
- **Context menu** (right-click / long-press): Copy, Restore, Delete, Select

### Archived Channel Item

Distinct visual representation for archived channels.

- **Container**: White background with `#CE2161` border (1px), 12px padding all sides
- **Layout**: Horizontal row containing:
  - Channel emoji (24px font size)
  - 10px gap
  - Channel name (16px, w500 weight, `#1C1C1C` color, ellipsis overflow)
  - 10px gap
  - "Channel" badge (gray pill: `#DADDD8` background, 4px border radius, 8px horizontal / 2px vertical padding, 11px w500 `#666666` text)
- **Restore button** (restore.svg, 24x24px) positioned 12px to the right of the container
- Restore button tooltip: "Restore channel"
- **Cancel button** (cancel.svg, 24x24px) positioned 8px to the right of the restore button
- Cancel button tooltip: "Delete channel"
- Cancel button opens confirmation dialog (does NOT immediately delete)
- **Context menu** (right-click / long-press): Restore, Delete
- **Outer padding**: 12px horizontal, 4px vertical
- Max width constraint: 600px

### Delete Channel Confirmation Dialog

Shown when permanently deleting a channel from the Archive Crate.

- **Style**: Dark background (`#00171F`), sharp corners (zero border radius)
- **Title**: "Delete Channel" (white text)
- **Content**: "Delete [emoji] [name] and X note(s) permanently?" (white text)
- Note count fetched via `getArchivedChannelNoteCount()` endpoint
- **Cancel button**: White background, dark text, zero border radius
- **Delete button**: Red background, white text, zero border radius

## Styling

### Color Palette

| Token          | Value     | Usage                                      |
|----------------|-----------|--------------------------------------------|
| Border color   | `#CE2161` | Note and channel item borders              |
| Text color     | `#1C1C1C` | Channel name, note content                 |
| Badge bg       | `#DADDD8` | "Channel" badge background                 |
| Badge text     | `#666666` | "Channel" badge text                       |
| Dialog bg      | `#00171F` | Confirmation dialog background             |
| Delete button  | Red       | Permanent delete confirmation button       |

### Typography

| Element           | Font   | Size | Weight | Color               |
|-------------------|--------|------|--------|---------------------|
| Channel emoji     | System | 24px | Normal | N/A                 |
| Channel name      | System | 16px | w500   | `#1C1C1C`           |
| Channel badge     | System | 11px | w500   | `#666666`           |
| Dialog title      | System | —    | —      | White               |
| Dialog content    | System | —    | —      | White               |

### Dimensions

| Element                   | Value          | Usage                          |
|---------------------------|----------------|--------------------------------|
| Item horizontal padding   | 12px           | Left/right padding of items    |
| Item vertical padding     | 4px            | Top/bottom padding of items    |
| Container padding         | 12px all sides | Inner padding of item boxes    |
| Emoji to name gap         | 10px           | Space between emoji and name   |
| Name to badge gap         | 10px           | Space between name and badge   |
| Cancel button gap         | 12px           | Space between container and X  |
| Cancel button size        | 24x24px        | Cancel SVG dimensions          |
| Max item width            | 600px          | ConstrainedBox maxWidth        |
| Badge padding             | H: 8px, V: 2px| "Channel" badge inner padding  |
| Badge border radius       | 4px            | Badge corner rounding          |

## Interactions

### Channel Archiving (from Sidebar)

- Right-click or long-press a channel in the sidebar to open context menu
- Select "Archive" to soft-delete the channel
- Channel disappears from sidebar, appears in Archive Crate
- If the archived channel was currently selected, auto-switches to the first remaining channel
- Success toast: "Channel archived"
- Error toast if attempting to archive the last remaining channel

### Note Archiving (from Channel)

- Right-click/long-press a note and select "Archive", or click the recycle.svg button to the right of the note
- Note moves to Archive Crate (channelId set to `-1`, originalChannelId preserved)

### Restoring Items

- **Notes**: Click restore.svg button, or right-click and select "Restore". Note returns to its original channel. Success toast: "Note restored". Error if original channel no longer exists.
- **Channels**: Click restore.svg button, or right-click and select "Restore". Channel returns to sidebar with all notes intact. Pin state reset to unpinned. If a channel with the same name already exists, restored channel is renamed to "[Name] (Restored)". Success toast: "Channel restored".

### Permanent Deletion

- **Notes**: Click cancel.svg button or right-click, select "Delete". Immediately deletes note, its media attachments, and files from disk.
- **Channels**: Click cancel.svg button or right-click, select "Delete". Opens confirmation dialog showing note count. On confirm, cascade-deletes channel, all its notes, and all media files.

### Last Channel Protection

- Cannot archive the last remaining active (non-archived, non-system) channel
- Server validates and returns error; client shows error toast

## Server Endpoints

| Endpoint                        | Method   | Description                                    |
|---------------------------------|----------|------------------------------------------------|
| `archiveChannel(id)`           | `Future<void>` | Sets archived=true, archivedAt=now, pinned=false. Broadcasts `channelArchived` event. |
| `restoreChannel(id)`           | `Future<Channel>` | Sets archived=false, archivedAt=null. Appends "(Restored)" on name conflict. Broadcasts `channelRestored` event. |
| `getArchiveItems(limit)`       | `Future<List<ArchiveItem>>` | Returns mixed list of archived notes (channelId=-1) and archived channels (archived=true), sorted by archivedAt desc. |
| `getArchivedChannelNoteCount(channelId)` | `Future<int>` | Returns count of notes in an archived channel (for confirmation dialog). |
| `getChannels()`                | Modified | Now filters `where: archived == false` to exclude archived channels from sidebar. |
| `deleteChannel(id)`            | Modified | Counts only active (non-archived, non-system) channels for "last channel" check. Archived channels skip this check. |

### WebSocket Events

| Event Type         | Payload Fields  | Description                           |
|--------------------|-----------------|---------------------------------------|
| `channelArchived`  | `channelId`     | Channel was archived (removed from sidebar) |
| `channelRestored`  | `channel`       | Channel was restored (full object for sidebar re-addition) |

## State Management

### Providers Watched (reactive)

| Provider               | Type                            | Purpose                          |
|------------------------|---------------------------------|----------------------------------|
| `archiveItemsProvider` | `AsyncValue<List<ArchiveItem>>` | Mixed archive list for rendering |

### Providers Read (on interaction)

| Provider                            | Usage                                    |
|-------------------------------------|------------------------------------------|
| `archiveItemsProvider.notifier`     | Restore/delete notes and channels        |
| `channelsProvider.notifier`         | Archive channel from sidebar             |
| `currentChannelProvider.notifier`   | Auto-switch after archiving current channel |

### Real-time Updates

The `archiveItemsProvider` listens to `chatStreamProvider` and invalidates itself on any of these events:
- `noteArchived`, `noteRestored`, `noteDeleted`
- `channelArchived`, `channelRestored`, `channelDeleted`

The `channelsProvider` also listens for `channelArchived` and `channelRestored` to refetch the sidebar channel list.

## Integration

The Archive Crate is accessed via the sidebar button (channelId `-1`). When selected, `ChatView` detects `channelId == -1` and renders `_buildArchiveView()` instead of the normal notes list. The input bar is hidden when viewing the Archive Crate. The Archive Crate communicates with the server through `archiveItemsProvider` and directly via `client.chat` for the note count endpoint.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/chat_view.dart` | Hosts archive view rendering (`_buildArchiveView`, `_buildArchivedChannelItem`, context menus, confirmation dialog) |
| `lib/providers/archive_items_provider.dart` | Data provider for mixed archive list |
| `lib/providers/channels_provider.dart` | Channel archiving method and event handling |
| `lib/widgets/sidebar.dart` | Archive button and channel context menu (Archive action) |
| `lib/providers/current_channel_provider.dart` | Channel switching after archive |
| `lib/utils/toast_utils.dart` | Success/error toast display |
| `lib/widgets/styled_tooltip.dart` | Tooltip on cancel buttons |
| `memoka_server/lib/src/chat/chat_endpoint.dart` | Server endpoints for archive operations |
| `memoka_server/lib/src/chat/archive_item.spy.yaml` | ArchiveItem protocol model definition |
| `memoka_server/lib/src/chat/channel.spy.yaml` | Channel model with archived/archivedAt fields |
