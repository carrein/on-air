**Overview**
Single-user real-time chat-style notes. Static 250px left sidebar (non-responsive). Serverpod backend, Flutter frontend, Riverpod state management.

**Tech Stack**

- Backend: Serverpod (Dart)
- Frontend: Flutter (Android + Web)
- Database: PostgreSQL
- Cache: Redis
- State: Riverpod
- Local: shared_preferences

**Data Models** (`spy.yaml`)

```yaml
class: Channel
table: channels
fields:
  name: String
  createdAt: DateTime, defaultValue=now
  updatedAt: DateTime, defaultValue=now

class: Note
table: notes
fields:
  channelId: int, parent=channel
  content: String
  createdAt: DateTime, defaultValue=now
  updatedAt: DateTime, defaultValue=now
indexes:
  channel_created_idx: fields: channelId, createdAt
```

**Database Setup**

- `serverpod create-migration` then `serverpod generate`
- Server auto-creates "General" channel if `channels` table empty on startup

**REST Endpoints**

- `getChannels()` → `List<Channel>` sorted `createdAt ASC`
- `getNotes(channelId, {beforeId?, limit=50})` → `List<Note>` (cursor pagination, `id < beforeId`)
- `createChannel(name)` → `Channel` (reject empty)
- `deleteChannel(id)` → void (reject if last remaining channel, cascade delete notes)
- `createNote(channelId, content)` → `Note` (reject empty)
- `updateNote(id, content)` → `Note` (last-write-wins)
- `deleteNote(id)` → void (hard delete)

**WebSocket Protocol** (Streaming endpoint: `chat`)
Client subscribes to global stream. Server broadcasts JSON:

```json
{"type": "noteCreated", "note": {...}}
{"type": "noteUpdated", "note": {...}}
{"type": "noteDeleted", "noteId": 123, "channelId": 1}
{"type": "channelCreated", "channel": {...}}
{"type": "channelDeleted", "channelId": 1}
```

**Resilience**

- Exponential backoff reconnect: 1s, 2s, 4s... max 30s
- "Offline" banner after 3s disconnected
- Reconnect on app resume (mobile) or page visibility change (web)

**UI Specifications**

_Layout_

- Fixed 250px left sidebar (always visible, non-responsive)
- Remaining width: chat view (inverted list: newest at bottom)
- Static bottom input bar

_Sidebar_

- Channels listed by `createdAt ASC` (oldest top)
- Tap channel to switch
- Bottom item: Fixed "+" button → dialog (text field + Create/Cancel)
- Context menu per channel: Delete only (blocked if last channel)
- **Channel switch behavior**: If editing note, discard changes and clear input field immediately

_Chat View_

- Inverted `ListView` (newest bottom)
- Load initial 50 notes, scroll up triggers load next 50 (cursor `beforeId`)
- Auto-scroll to bottom on new note unless user scrolling history
- Long-press note → populate input field for edit

_Input Bar_

- Multiline `TextField`, Enter to submit, Shift+Enter for newline
- Create mode: Send button (enabled if non-empty)
- Edit mode: Shows Cancel (X) button, Send becomes Save icon
- Cancel returns to empty create mode

_Delete Behavior_

- Immediate hard delete, no confirmation
- Channel delete cascades to notes

**Local Storage** (`shared_preferences`)

- `lastOpenedChannelId`: int? (restore on launch, fallback to first channel)
- `deviceUuid`: String (generated once)

**Validation Rules**

- Channel name: non-empty
- Note content: non-empty
- Cannot delete last remaining channel

**State Management (Riverpod)**

- `channelsProvider`: AsyncNotifier managing channel list
- `notesProvider(channelId)`: AsyncNotifier managing paginated notes
- `currentChannelIdProvider`: StateProvider<int>
- `editingNoteIdProvider`: StateProvider<int?> (null = create mode)
- `connectionStateProvider`: StreamProvider<ConnectionState>
