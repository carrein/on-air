# Offline Mode

Memoka supports local-first reads and offline writes on all platforms. Notes and channels are cached in a local SQLite database via Drift, and mutations made while offline are queued and synced when connectivity is restored.

## Architecture

### Local Database (Drift)

`memoka_flutter/lib/local_db/database.dart`

Three SQLite tables:
- **CachedChannels** — full serialised Channel JSON, keyed by server ID
- **CachedNotes** — full serialised Note JSON, keyed by server ID + channelId index
- **PendingMutations** — queued offline operations (autoIncrement ID, type, channelId, payload JSON, createdAt)

On native, Drift uses `sqlite3_flutter_libs` (file-based SQLite). On web, Drift uses WASM SQLite backed by IndexedDB — the same schema, same code paths, full persistence across page reloads.

### WASM SQLite (Web)

Two files must be present in `memoka_flutter/web/`:
- **`sqlite3.wasm`** — compiled SQLite module (from [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases), must match the `sqlite3` version in `pubspec.lock`)
- **`drift_worker.js`** — web worker for shared database access across tabs (from [drift releases](https://github.com/simolus3/drift/releases), must match the `drift` version in `pubspec.lock`)

These are configured via `DriftWebOptions` in the `appDatabaseProvider`:

```dart
driftDatabase(
  name: 'memoka',
  web: DriftWebOptions(
    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
    driftWorker: Uri.parse('drift_worker.js'),
  ),
)
```

When upgrading drift or sqlite3, download matching WASM/worker files from the release pages above.

### Connectivity Detection

`memoka_flutter/lib/providers/connection_provider.dart`

`connectionProvider` is a `Notifier<ConnectionState>` (keepAlive). It starts as `disconnected` and transitions via two mechanisms:

1. **OS-level events** (`connectivity_plus`): When the OS reports no network interfaces, the notifier immediately sets `disconnected`. When any interface returns, it invalidates `chatStreamProvider` to kick an immediate reconnect attempt — bypassing the exponential backoff timer.

2. **WebSocket lifecycle** (`chatStreamProvider`): Before opening the WebSocket each reconnect attempt, `chatStreamProvider` calls `client.health.ping()` (4s timeout). On success → `setConnected()`. If the ping fails or the WebSocket drops → `setDisconnected()`. This is one HTTP call per reconnect attempt, not a poll.

**Lifecycle handling** (`ChatScreen`): Implements `WidgetsBindingObserver` to detect app foreground (Android via `didChangeAppLifecycleState`) and web tab focus (via `document.visibilitychange`). Both call `_kickReconnectIfNeeded()`, which invalidates `chatStreamProvider` only when already `disconnected`, forcing an immediate reconnect rather than waiting for the next backoff tick.

### Health Endpoint

`memoka_server/lib/src/health_endpoint.dart`

Lightweight Serverpod RPC endpoint. `ping()` returns `true`. Called by `chatStreamProvider` via `client.health.ping()` to confirm server reachability before opening the WebSocket stream. Unlike the old HTTP healthcheck route, this lives on the API server (port 8080) and is reachable regardless of reverse-proxy configuration.

## Data Flow

### App Launch (online)

1. `channelsProvider.build()` loads `db.getCachedChannels()` → emits immediately from cache
2. Then fetches from server → updates state + cache
3. `notesProvider.build(channelId)` follows the same pattern

### App Launch (offline)

1. `channelsProvider.build()` loads `db.getCachedChannels()` → emits immediately
2. Server fetch fails → caught, returns cache
3. `notesProvider.build(channelId)` follows the same pattern

### User Creates Note (offline)

1. A UUID `clientMutationId` is generated and stored in both the queued payload and the provisional note
2. Provisional note with negative ID prepended to Riverpod state → appears instantly
3. `db.enqueueMutation('createNote', channelId, {content, clientMutationId})` → persisted to SQLite
4. `pendingMutationCount` stream increments → navbar sync indicator appears

### Network Restored

1. `connectionProvider` transitions to `connected`
2. `SyncEngine._drain()` reads all `PendingMutations` ordered by ID
3. Each mutation executed sequentially against the server API
   - `createNote` passes its `clientMutationId` — the server returns the existing note if it was already applied (idempotent replay)
4. On success: `db.deleteMutation(id)`, continue to next
5. On failure: stop drain (retry on next reconnect)
6. After drain: `channelsProvider` and affected `notesProvider(channelId)` invalidated → fresh server data loaded + cached
7. `pendingMutationCount` → 0 → sync indicator disappears

### Failed Online Mutation

If `_isOnline` is `true` at the moment of a mutation but the server becomes unreachable milliseconds later (race condition), the call throws a `ServerpodClientException` with `statusCode == -1`. Both `notes_provider.dart` and `channels_provider.dart` catch this via `_isNetworkError()` and fall through to the offline queue rather than propagating the error. Server-side business errors (e.g., "last remaining channel") are re-thrown as normal.

### WebSocket Events (online)

Existing chat stream listeners update Riverpod state AND write to cache, so the next offline launch has fresh data.

## Supported Offline Operations

| Operation | Behavior |
|-----------|----------|
| Read channels | Served from SQLite cache |
| Read notes | Served from SQLite cache (first page, ~50 notes) |
| Create note | Provisional note shown, mutation queued |
| Delete note | Removed from UI, mutation queued |
| Create channel | Provisional channel shown, mutation queued |
| Update channel | Optimistic UI update, mutation queued |
| Archive channel | Removed from UI, mutation queued |

## Sync Indicator

`memoka_flutter/lib/widgets/sync_indicator.dart`

Shown in the navbar action row:
- **Hidden** when connected with zero pending mutations
- **Amber cloud-slash icon** with count badge when offline
- **Spinning arrows icon** when online and draining the queue

## Conflict Resolution

Last-write-wins. When the queue drains, server state wins via WebSocket events that trigger a full refetch + cache update.

**Provisional note replacement**: When the server broadcasts `noteCreated` for an offline-created note, `notesProvider` matches the incoming event by `clientMutationId` and replaces the provisional note in-place — preserving its position in the list with no flash or duplication. Online-created notes (no `clientMutationId`) fall back to dedup-by-server-ID as before.

**Idempotent `createNote`**: The server stores `clientMutationId` in the `notes` table (unique nullable column). If the drain replays a mutation that was already applied (e.g., the client crashed between the server insert and the local `deleteMutation` call), the server returns the existing note rather than creating a duplicate.

## Web vs Native

| Feature | Native (Android) | Web |
|---------|------------------|-----|
| Cache persistence | SQLite on disk (survives restart) | WASM SQLite + IndexedDB (survives reload) |
| Mutation queue | SQLite (survives force-kill) | WASM SQLite + IndexedDB (survives reload) |
| Connectivity detection | connectivity_plus + WebSocket ping | connectivity_plus + WebSocket ping |

## Key Files

| File | Purpose |
|------|---------|
| `memoka_server/lib/src/health_endpoint.dart` | `ping()` RPC endpoint — called once per reconnect attempt |
| `memoka_flutter/lib/local_db/database.dart` | Drift database, tables, helpers |
| `memoka_flutter/lib/providers/connection_provider.dart` | `connectionProvider` Notifier — source of truth for online/offline |
| `memoka_flutter/lib/providers/chat_stream_provider.dart` | WebSocket stream — drives connectivity state, exponential backoff |
| `memoka_flutter/lib/screens/chat_screen.dart` | `WidgetsBindingObserver` + web `visibilitychange` for lifecycle reconnect |
| `memoka_flutter/lib/providers/channels_provider.dart` | Local-first channel loading + offline mutations |
| `memoka_flutter/lib/providers/notes_provider.dart` | Local-first note loading + offline mutations |
| `memoka_flutter/lib/providers/sync_engine_provider.dart` | Drains pending mutations on reconnect |
| `memoka_flutter/lib/providers/pending_mutation_count_provider.dart` | Pending count stream for UI |
| `memoka_flutter/lib/widgets/sync_indicator.dart` | Navbar sync badge widget |
| `memoka_flutter/web/sqlite3.wasm` | WASM SQLite binary (match sqlite3 pubspec.lock version) |
| `memoka_flutter/web/drift_worker.js` | Drift web worker (match drift pubspec.lock version) |
