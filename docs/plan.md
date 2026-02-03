# On Air Implementation Plan

> **Project**: Real-time chat-style notes application with Serverpod backend and Flutter frontend
>
> **Key Architecture Decisions**:
> - WebSocket streaming via Serverpod's built-in streaming methods + MessageCentral for broadcasting
> - Riverpod for Flutter state management (not currently installed)
> - Cursor-based pagination for notes
> - Auto-create "General" channel on server startup
>
> **Security**: See [docs/security.md](./security.md) for security considerations and incident history

---

## Phase 1: Server Data Models & Database Migration

### 1.1 Create Protocol Models

Create feature directory and `.spy.yaml` model definitions following existing pattern (`lib/src/greetings/greeting.spy.yaml`).

- [ ] Create directory: `on_air_server/lib/src/chat/`

- [ ] Create `on_air_server/lib/src/chat/channel.spy.yaml`:
```yaml
class: Channel
table: channels
fields:
  name: String
  createdAt: DateTime, defaultValue=now
  updatedAt: DateTime, defaultValue=now
```

- [ ] Create `on_air_server/lib/src/chat/note.spy.yaml`:
```yaml
class: Note
table: notes
fields:
  channelId: int, parent=channel
  content: String
  createdAt: DateTime, defaultValue=now
  updatedAt: DateTime, defaultValue=now
indexes:
  channel_created_idx:
    fields: channelId, createdAt
```

- [ ] Create `on_air_server/lib/src/chat/chat_event.spy.yaml`:
```yaml
class: ChatEvent
fields:
  type: String
  note: Note?
  noteId: int?
  channelId: int?
  channel: Channel?
```

### 1.2 Generate Code & Create Migration

**Commands from project root:**

- [ ] `cd on_air_server && serverpod generate`
  - Generates protocol classes in `lib/src/generated/`
  - Updates client code in `on_air_client/`

- [ ] `serverpod create-migration`
  - Creates timestamped migration in `migrations/`

- [ ] Verify migration SQL includes:
  - `channels` table (id, name, createdAt, updatedAt)
  - `notes` table (id, channelId, content, createdAt, updatedAt)
  - Foreign key: `notes.channelId` → `channels.id` with CASCADE delete
  - Index: `channel_created_idx` on (channelId, createdAt)

### 1.3 Apply Migration

- [ ] `docker compose up --build --detach` (start database services)
- [ ] `dart bin/main.dart --apply-migrations` (apply migration)
- [ ] Verify: `docker exec -it on_air_server-postgres-1 psql -U postgres -d on_air -c "\dt"`

---

## Phase 2: Server Endpoints Implementation

### 2.1 Create Chat Endpoint

**File**: `on_air_server/lib/src/chat/chat_endpoint.dart`

- [ ] Implement `ChatEndpoint` class extending `Endpoint` with methods:
  - `Future<List<Channel>> getChannels(Session session)`
  - `Future<List<Note>> getNotes(Session session, int channelId, {int? beforeId, int limit = 50})`
  - `Future<Channel> createChannel(Session session, String name)`
  - `Future<void> deleteChannel(Session session, int id)`
  - `Future<Note> createNote(Session session, int channelId, String content)`
  - `Future<Note> updateNote(Session session, int id, String content)`
  - `Future<void> deleteNote(Session session, int id)`
  - `Stream<ChatEvent> chat(Session session)`

### 2.2 Key Implementation Details

**getChannels** - Query database, sort by createdAt ASC:
```dart
return await Channel.db.find(session, orderBy: (t) => t.createdAt);
```

**getNotes** - Cursor pagination with beforeId:
```dart
Expression? where = Channel.t.channelId.equals(channelId);
if (beforeId != null) {
  where = where & Channel.t.id.lessThan(beforeId);
}
return await Note.db.find(session, where: where, orderBy: (t) => t.createdAt, orderDescending: true, limit: limit);
```

**createChannel** - Validate + broadcast:
```dart
if (name.trim().isEmpty) throw Exception('Name cannot be empty');
final saved = await Channel.db.insertRow(session, Channel(name: name));
session.messages.postMessage('chat_events', ChatEvent(type: 'channelCreated', channel: saved), global: true);
return saved;
```

**deleteChannel** - Validate last channel + cascade:
```dart
final count = await Channel.db.count(session);
if (count <= 1) throw Exception('Cannot delete last channel');
await Channel.db.deleteRow(session, id);
session.messages.postMessage('chat_events', ChatEvent(type: 'channelDeleted', channelId: id), global: true);
```

**createNote/updateNote/deleteNote** - Similar pattern: validate, mutate DB, broadcast event

**chat** - Subscribe to MessageCentral:
```dart
Stream<ChatEvent> chat(Session session) async* {
  final stream = session.messages.createStream<ChatEvent>('chat_events');
  await for (final event in stream) {
    yield event;
  }
}
```

- [ ] Implement all 8 methods following patterns above
- [ ] Run `serverpod generate` to update generated code

### 2.3 Auto-Create Default Channel

**File**: `on_air_server/lib/server.dart`

- [ ] Add after `await pod.start();` (line 77):
```dart
await _ensureDefaultChannel(pod);
```

- [ ] Add helper function before main `run()` function:
```dart
Future<void> _ensureDefaultChannel(Serverpod pod) async {
  final session = await pod.createSession();
  try {
    final count = await Channel.db.count(session);
    if (count == 0) {
      await Channel.db.insertRow(session, Channel(name: 'General'));
      session.log('Created default "General" channel');
    }
  } finally {
    await session.close();
  }
}
```

---

## Phase 3: Backend Testing

### 3.1 Integration Tests

**File**: `on_air_server/test/integration/chat_endpoint_test.dart`

- [ ] Create test file following pattern from `greeting_endpoint_test.dart`
- [ ] Test scenarios:
  - `getChannels()` returns sorted list
  - `createChannel()` validates non-empty name
  - `deleteChannel()` rejects if last channel
  - `getNotes()` cursor pagination works
  - `createNote()` validates non-empty content
  - `updateNote()` updates content
  - `deleteNote()` removes note

- [ ] Run: `cd on_air_server && dart test`

### 3.2 Manual API Testing

- [ ] Test with curl:
```bash
curl http://localhost:8080/api/chat/getChannels
curl -X POST http://localhost:8080/api/chat/createChannel -H "Content-Type: application/json" -d '{"name":"Test"}'
curl -X POST http://localhost:8080/api/chat/createNote -H "Content-Type: application/json" -d '{"channelId":1,"content":"Hello"}'
curl http://localhost:8080/api/chat/getNotes?channelId=1
```

**Checkpoint**: Backend fully functional and tested before starting Flutter

---

## Phase 4: Flutter Dependencies & Riverpod Setup

### 4.1 Add Dependencies

**File**: `on_air_flutter/pubspec.yaml`

- [ ] Add to `dependencies:`:
```yaml
flutter_riverpod: ^2.6.1
riverpod_annotation: ^2.6.1
shared_preferences: ^2.3.4
uuid: ^4.5.1
```

- [ ] Add to `dev_dependencies:`:
```yaml
riverpod_generator: ^2.6.2
build_runner: ^2.4.13
```

- [ ] Run: `cd on_air_flutter && flutter pub get`

### 4.2 Wrap App with ProviderScope

**File**: `on_air_flutter/lib/main.dart`

- [ ] Add import: `import 'package:flutter_riverpod/flutter_riverpod.dart';`
- [ ] Modify line 39: `runApp(const ProviderScope(child: MyApp()));`

---

## Phase 5: Flutter Providers (State Management)

**Directory**: `on_air_flutter/lib/providers/`

### 5.1 Create Provider Files

- [ ] `connection_provider.dart` - Monitors connectivity state (StreamProvider)
- [ ] `channels_provider.dart` - Manages channel list (AsyncNotifier)
- [ ] `notes_provider.dart` - Manages notes per channel with pagination (AsyncNotifier family)
- [ ] `chat_stream_provider.dart` - WebSocket subscription (StreamProvider)
- [ ] `current_channel_provider.dart` - Active channel ID (AsyncNotifier)
- [ ] `editing_note_provider.dart` - Edit mode state (StateNotifier)
- [ ] `device_uuid_provider.dart` - Device UUID from shared_preferences (FutureProvider)

### 5.2 Key Provider Patterns

**chat_stream_provider** - Core WebSocket connection:
```dart
@riverpod
class ChatStream extends _$ChatStream {
  @override
  Stream<ChatEvent> build() => client.chat.chat();
}
```

**channels_provider** - Listen to chat stream for updates:
```dart
@override
Future<List<Channel>> build() async {
  ref.listen(chatStreamProvider, (_, event) {
    event.whenData((chatEvent) {
      if (chatEvent.type == 'channelCreated' || chatEvent.type == 'channelDeleted') {
        ref.invalidateSelf();
      }
    });
  });
  return client.chat.getChannels();
}
```

**notes_provider** - Handle real-time note events + pagination:
```dart
void _handleChatEvent(ChatEvent event, int channelId) {
  switch (event.type) {
    case 'noteCreated':
      if (event.note?.channelId == channelId) {
        state = AsyncValue.data([...state.value ?? [], event.note!]);
      }
    case 'noteUpdated': /* update matching note */
    case 'noteDeleted': /* filter out deleted note */
  }
}
```

- [ ] Create all 7 provider files
- [ ] Run: `dart run build_runner build --delete-conflicting-outputs` (generates `*.g.dart`)

---

## Phase 6: Flutter UI Components

**Directory**: `on_air_flutter/lib/`

### 6.1 Main Screen

**File**: `screens/chat_screen.dart`

- [ ] Create `ChatScreen` widget with Row layout:
  - Fixed 250px width `Sidebar`
  - Expanded `ChatView` + `InputBar` column
  - `OfflineBanner` at top

### 6.2 Sidebar Widget

**File**: `widgets/sidebar.dart`

- [ ] Display channels from `channelsProvider`
- [ ] Highlight current channel from `currentChannelProvider`
- [ ] Channel tap switches channel + clears edit state
- [ ] PopupMenuButton per channel with "Delete" option
- [ ] Bottom ListTile with "+" button shows create dialog

### 6.3 Chat View Widget

**File**: `widgets/chat_view.dart`

- [ ] Inverted ListView (reverse: true) for newest-at-bottom layout
- [ ] Watch `notesProvider(currentChannelId)` for notes
- [ ] ScrollController detects scroll near top → trigger `loadMore()`
- [ ] Long-press note → call `editingNoteProvider.notifier.startEditing(noteId)`
- [ ] Delete button per note → `notesProvider.notifier.deleteNote(id)`

### 6.4 Input Bar Widget

**File**: `widgets/input_bar.dart`

- [ ] TextEditingController for multiline input
- [ ] Watch `editingNoteProvider` to populate field when editing
- [ ] Show Cancel (X) button in edit mode
- [ ] Send/Save button enabled only if text non-empty
- [ ] Enter key submits (default TextField behavior allows Shift+Enter for newline)

### 6.5 Offline Banner Widget

**File**: `widgets/offline_banner.dart`

- [ ] Listen to `connectionProvider`
- [ ] Show orange banner after 3s delay when disconnected
- [ ] Hide when reconnected

### 6.6 Update Main

**File**: `main.dart`

- [ ] Replace `MyHomePage` body (line 64) with `const ChatScreen()`
- [ ] Add import: `import 'screens/chat_screen.dart';`
- [ ] Remove AppBar (ChatScreen provides own layout)

---

## Phase 7: Integration & Verification

### 7.1 Backend Verification

- [ ] Start server with migration: `cd on_air_server && dart bin/main.dart --apply-migrations`
- [ ] Verify "General" channel auto-created (check logs)
- [ ] Test REST endpoints with curl (see Phase 3.2)
- [ ] Run integration tests: `dart test`

### 7.2 Flutter Verification

- [ ] Generate providers: `cd on_air_flutter && dart run build_runner build`
- [ ] Run app: `flutter run` (or `flutter run -d chrome` for web)
- [ ] Test channel creation/deletion
- [ ] Test note creation/editing/deletion
- [ ] Test real-time updates: Open 2 browser tabs, create note in one, verify appears in other
- [ ] Test pagination: Create 60+ notes, scroll up in chat view
- [ ] Test offline banner: Stop server, wait 3s, verify banner appears
- [ ] Test channel switch during edit: Start editing note, switch channel, verify input cleared

### 7.3 Database State Verification

- [ ] Connect: `docker exec -it on_air_server-postgres-1 psql -U postgres -d on_air`
- [ ] `SELECT * FROM channels;` - Verify channels exist
- [ ] `SELECT * FROM notes;` - Verify notes exist
- [ ] Test cascade delete: Delete channel via UI, verify notes removed from DB
- [ ] `\d notes` - Verify `channel_created_idx` index exists

---

## Critical Files Summary

**Server** (new files):
- `on_air_server/lib/src/chat/channel.spy.yaml`
- `on_air_server/lib/src/chat/note.spy.yaml`
- `on_air_server/lib/src/chat/chat_event.spy.yaml`
- `on_air_server/lib/src/chat/chat_endpoint.dart` (core business logic)
- `on_air_server/lib/server.dart` (modify - add default channel)
- `on_air_server/test/integration/chat_endpoint_test.dart`

**Flutter** (new files):
- `on_air_flutter/lib/providers/` (7 provider files)
- `on_air_flutter/lib/screens/chat_screen.dart`
- `on_air_flutter/lib/widgets/` (4 widget files)
- `on_air_flutter/lib/main.dart` (modify)
- `on_air_flutter/pubspec.yaml` (modify)

---

## Potential Issues & Resolutions

### Issue: Serverpod Streaming API
**Spec says**: "WebSocket endpoint named 'chat'"
**Serverpod v3.2.3**: Uses `Stream<T>` methods + MessageCentral for broadcasting
**Resolution**: Implement `Stream<ChatEvent> chat(Session)` that subscribes to MessageCentral channel "chat_events"

### Issue: Event Payload Format
**Spec format**: `{"type": "noteCreated", "note": {...}}`
**Resolution**: Use strongly-typed `ChatEvent` class with type field + optional data fields (note, noteId, channelId, channel)

### Issue: MessageCentral Requires Redis
**Requirement**: `session.messages.postMessage(..., global: true)` requires Redis for cross-session broadcasting
**Status**: Redis already configured in docker-compose.yaml (port 8091)
**Verification**: Ensure Redis container running before testing WebSocket

---

## Testing Checklist

### Backend
- [ ] REST endpoints return correct data
- [ ] Validation rules enforced (non-empty name/content, last channel)
- [ ] Cascade delete works (channel deletion removes notes)
- [ ] Cursor pagination works (beforeId parameter)
- [ ] WebSocket broadcasts events to all connected clients
- [ ] Default "General" channel created on first startup

### Frontend
- [ ] Channels display sorted by createdAt
- [ ] Channel switching clears edit state
- [ ] Real-time updates appear without refresh
- [ ] Long-press note populates input for editing
- [ ] Edit mode shows Cancel button
- [ ] Pagination loads older notes on scroll up
- [ ] Auto-scroll to bottom on new note (unless user scrolling history)
- [ ] Offline banner appears after 3s disconnection
- [ ] Reconnection restores real-time updates

### Integration
- [ ] Multiple browser tabs receive same events simultaneously
- [ ] Page refresh restores last opened channel (shared_preferences)
- [ ] Device UUID persists across app restarts
- [ ] All CRUD operations trigger WebSocket events
- [ ] Network interruption handled gracefully with auto-reconnect

---

## Implementation Order

1. **Phase 1-3**: Build and test backend completely (models → endpoints → tests)
2. **Phase 4**: Add Riverpod dependencies
3. **Phase 5**: Create all providers (generate with build_runner)
4. **Phase 6**: Build UI incrementally (screen → sidebar → chat view → input → banner)
5. **Phase 7**: End-to-end integration testing

**Estimated Complexity**: Medium-High
- Backend: Straightforward CRUD + streaming (Serverpod handles WebSocket complexity)
- Frontend: Moderate complexity with Riverpod providers and real-time updates
- Most complex parts: Notes provider with pagination + real-time events, inverted ListView with scroll detection

---

## References

- Serverpod Docs: https://docs.serverpod.dev/
- Serverpod Streaming: https://docs.serverpod.dev/concepts/streams
- MessageCentral (Server Events): https://docs.serverpod.dev/concepts/server-events
- Riverpod Docs: https://riverpod.dev/
