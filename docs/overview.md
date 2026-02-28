**Overview**
Single-user real-time chat-style notes. Responsive layout with left sidebar (60-250px), chat view, and right media panel (250-400px). Serverpod backend, Flutter frontend, Riverpod state management.

**Tech Stack**

- Backend: Serverpod (Dart)
- Frontend: Flutter (Android + Web)
- Database: PostgreSQL (with pgvector)
- Cache: Redis
- State: Riverpod
- Local: shared_preferences

**Data Models** (`spy.yaml`)

```yaml
class: Channel
table: channels
fields:
  name: String
  emoji: String, default='💬'
  pinned: bool, default=false
  isSystemChannel: bool, default=false
  createdAt: DateTime, default=now
  updatedAt: DateTime, default=now
  sortOrder: int, default=0    # legacy, kept for compat
  position: double, default=0  # primary ordering field (fractional)
  archived: bool, default=false
  archivedAt: DateTime?
  version: int, default=0
  deletedAt: DateTime?
  clientMutationId: String?

class: Note
table: notes
fields:
  channelId: int, relation(parent=channels, onDelete=Cascade)
  content: String
  linkPreview: LinkPreview?
  attachments: List<MediaAttachment>?
  archived: bool, default=false
  archivedAt: DateTime?
  createdAt: DateTime, default=now
  updatedAt: DateTime, default=now
  version: int, default=0
  deletedAt: DateTime?
  clientMutationId: String?
indexes:
  channel_created_idx: fields: channelId, createdAt
  archived_updated_idx: fields: archived, updatedAt

class: ChatEvent
fields:
  type: String
  note: Note?
  noteId: int?
  channelId: int?
  channel: Channel?

class: LinkPreview
fields:
  url: String
  title: String?
  description: String?
  imageUrl: String?
  faviconUrl: String?
  fetchedAt: DateTime, default=now

class: MediaAttachment
table: media_attachments
fields:
  noteId: int, relation(parent=notes, onDelete=Cascade)
  channelId: int, relation(parent=channels, onDelete=Cascade)
  filePath: String
  originalFilename: String
  mimeType: String
  fileSize: int
  width: int?
  height: int?
  duration: double?
  thumbnailPath: String?
  compressed: bool, default=false
  animated: bool, default=false
  contentHash: String?
  uploadedAt: DateTime, default=now
indexes:
  note_idx: fields: noteId
  channel_idx: fields: channelId, uploadedAt

class: ArchiveItem
fields:
  type: String
  note: Note?
  channel: Channel?
  archivedAt: DateTime
```

**Database Setup**

- `serverpod create-migration` then `serverpod generate`
- Server auto-creates "General" channel if `channels` table empty on startup

**REST Endpoints** (Chat)

- `getChannels()` → `List<Channel>` (pinned first, then by position, excludes archived)
- `reorderChannels(channelIds)` → void (persist drag-to-reorder position)
- `getNotes(channelId, {beforeId?, limit=50})` → `List<Note>` (cursor pagination, LEFT JOIN attachments)
- `createChannel(name, {emoji?})` → `Channel` (reject empty)
- `updateChannel(id, name, {emoji?, pinned?})` → `Channel`
- `deleteChannel(id)` → void (reject if last active channel, cascade delete notes + media files)
- `createNote(channelId, content)` → `Note` (reject empty, async link preview fetch)
- `updateNote(id, content)` → `Note` (last-write-wins)
- `deleteNote(id)` → void (archives to Archive, or permanently deletes if already in Archive)
- `restoreNote(id)` → void (restore from Archive to original channel)
- `archiveChannel(id)` → void (soft delete, notes stay with channel)
- `restoreChannel(id)` → `Channel` (unarchive)
- `getArchiveItems({beforeTimestamp?, limit=50})` → `List<ArchiveItem>` (mixed notes + channels)
- `getArchivedChannelNoteCount(channelId)` → `int`

**HTTP Routes** (Media)

- `POST /media/upload` → streams multipart body directly to disk (zero in-memory buffering), processes image/video server-side, creates DB record, broadcasts WebSocket event. Not a Serverpod RPC endpoint.

**WebSocket Protocol** (Streaming endpoint: `chat`)
Client subscribes to global stream. Server broadcasts:

```json
{"type": "noteCreated", "note": {...}}
{"type": "noteUpdated", "note": {...}}
{"type": "noteDeleted", "noteId": 123, "channelId": 1}
{"type": "noteArchived", "noteId": 123, "channelId": 1}
{"type": "noteRestored", "note": {...}, "channelId": 1}
{"type": "noteLinkPreviewReady", "note": {...}}
{"type": "channelCreated", "channel": {...}}
{"type": "channelUpdated", "channel": {...}}
{"type": "channelDeleted", "channelId": 1}
{"type": "channelArchived", "channelId": 1}
{"type": "channelRestored", "channel": {...}}
```

**Resilience**

- Connectivity derived from WebSocket stream — `chatStreamProvider` pings `client.health.ping()` once per reconnect attempt, then opens the WebSocket; state transitions via `connectionProvider` Notifier
- Exponential backoff reconnect: 1s, 2s, 4s... max 10s
- "Offline" banner shown when `connectionProvider` is `disconnected`
- Immediate reconnect on app foreground (Android `WidgetsBindingObserver`) or tab focus (web `visibilitychange`), bypassing the backoff timer
- OS network restore (`connectivity_plus`) also kicks immediate reconnect
- Failed online mutations (server dies mid-call) fall through to the offline queue via `_isNetworkError()` check

**UI Specifications**

_Layout_

- Responsive three-panel layout:
  - Left sidebar: 60-250px (channels, collapsible)
  - Center: chat view (inverted list: newest at bottom)
  - Right sidebar: 250-400px media panel (4 tabs: Images/Videos/Documents/Links)
  - Desktop (>=1200px): Both sidebars always visible
  - Tablet (768-1199px): Right sidebar hidden, toggle via button
  - Mobile (<768px): Right sidebar as bottom sheet
- Static bottom NoteInput

_Sidebar_

- Channels listed pinned first, then by position within each group
- Drag-to-reorder channels (long-press to drag, constrained within pinned/unpinned groups)
- Emoji display per channel
- Tap channel to switch
- Bottom: "New Channel" button → modal with name + emoji picker
- Context menu per channel: Edit, Pin/Unpin, Archive, Delete
- Account/Settings button below channel list
- Archive: system channel showing archived notes and channels

_Chat View_

- Inverted `ListView` (newest bottom)
- Load initial 50 notes, scroll up triggers load next 50 (cursor `beforeId`)
- Auto-scroll to bottom on new note unless user scrolling history
- Date separators (Today, Yesterday, or formatted date)
- Absolute timestamps (e.g., "Feb 6, 2:30 PM")
- Chat bubbles with 4px border radius
- Image-only notes render without bubble wrapper
- Compressed badge indicator on media attachments
- Right-click/long-press context menu: Copy, Edit, Delete
- Multi-select via long-press with bulk delete action bar
- Media attachments displayed inline with pre-sized shimmer placeholders (no layout jump)
- Full-screen image lightbox with gallery navigation (arrows, keyboard, swipe, counter)
- Video lightbox dialog with player controls (play/pause, progress bar, keyboard shortcuts)
- Link preview cards
- Selectable chat background patterns (via Settings → Background Picker)

_NoteInput_

- Multiline `TextField`, Enter to submit (via `Shortcuts`/`Actions`), Shift+Enter for newline
- Supported file types: images (jpg, png, gif, webp, heic), videos (mp4, mov, webm, avi, mkv), documents (pdf, txt, md, doc, docx, xls, xlsx), archives (zip)
- Create mode: Send button (enabled if non-empty)
- Edit mode: Shows Cancel (X) button, Send becomes Save icon
- Drag-and-drop + paste file upload support
- Multi-file batch upload with progress dialog
- Per-channel draft text preservation
- Link detection banner

_Media Panel_

- 4 tabs: Images, Videos, Documents, Links
- Grid layout for media (3 columns), list layout for links
- Click to open lightbox (images/videos) or download (documents) or navigate (links)
- Resizable width (250-400px)
- Real-time updates via WebSocket

_Delete Behavior_

- Notes: Soft delete to Archive (permanent delete from within Archive)
- Channels: Soft archive (can be restored)
- Channel permanent delete cascades to notes + media files

**Local Storage** (`shared_preferences`)

- `lastOpenedChannelId`: int? (restore on launch, fallback to first channel)
- `deviceUuid`: String (generated once)
- Channel draft text: per-channel input preservation

**Validation Rules**

- Channel name: non-empty, max 100 chars
- Channel emoji: max 10 chars
- Note content: non-empty, max 200,000 chars
- File size: max 1 GB
- Cannot delete last remaining active channel

**State Management (Riverpod)**

- `channelsProvider`: AsyncNotifier managing channel list (optimistic reorder on drag-to-reorder)
- `notesProvider(channelId)`: AsyncNotifier managing paginated notes
- `currentChannelIdProvider`: StateProvider<int>
- `editingNoteIdProvider`: StateProvider<int?> (null = create mode)
- `connectionProvider`: Notifier<ConnectionState> (keepAlive) — set by `chatStreamProvider` ping + WebSocket lifecycle
- `channelMediaDataProvider(channelId)`: Synchronous family provider deriving media panel data from `notesProvider`
- `mediaPanelVisibleProvider`: Global state for media panel visibility on mobile/tablet
