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

Uses `connectivity_plus` to detect network changes, then probes the server's `/healthcheck` endpoint (4s timeout) to confirm actual reachability. The `OfflineBanner` widget already listens to this provider.

### Server Healthcheck

`memoka_server/lib/src/web/routes/healthcheck_route.dart`

Returns `200 OK` with CORS headers. Registered at `/healthcheck` on the web server.

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

1. Provisional note with negative ID prepended to Riverpod state → appears instantly
2. `db.enqueueMutation('createNote', channelId, {content})` → persisted to SQLite
3. `pendingMutationCount` stream increments → navbar sync indicator appears

### Network Restored

1. `connectionStreamProvider` emits `connected`
2. `SyncEngine._drain()` reads all `PendingMutations` ordered by ID
3. Each mutation executed sequentially against the server API
4. On success: `db.deleteMutation(id)`, continue to next
5. On failure: stop drain (retry on next reconnect)
6. After drain: `channelsProvider` and affected `notesProvider(channelId)` invalidated → fresh server data loaded + cached
7. `pendingMutationCount` → 0 → sync indicator disappears

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

Last-write-wins. When the queue drains, server state wins via WebSocket events that trigger a full refetch + cache update. Provisional items (negative IDs) are replaced by server-assigned IDs.

## Web vs Native

| Feature | Native (Android) | Web |
|---------|------------------|-----|
| Cache persistence | SQLite on disk (survives restart) | WASM SQLite + IndexedDB (survives reload) |
| Mutation queue | SQLite (survives force-kill) | WASM SQLite + IndexedDB (survives reload) |
| Connectivity detection | connectivity_plus + healthcheck | connectivity_plus + healthcheck |

## Key Files

| File | Purpose |
|------|---------|
| `memoka_server/lib/src/web/routes/healthcheck_route.dart` | Server healthcheck endpoint |
| `memoka_flutter/lib/local_db/database.dart` | Drift database, tables, helpers |
| `memoka_flutter/lib/providers/connection_provider.dart` | Real connectivity detection |
| `memoka_flutter/lib/providers/channels_provider.dart` | Local-first channel loading + offline mutations |
| `memoka_flutter/lib/providers/notes_provider.dart` | Local-first note loading + offline mutations |
| `memoka_flutter/lib/providers/sync_engine_provider.dart` | Drains pending mutations on reconnect |
| `memoka_flutter/lib/providers/pending_mutation_count_provider.dart` | Pending count stream for UI |
| `memoka_flutter/lib/widgets/sync_indicator.dart` | Navbar sync badge widget |
| `memoka_flutter/web/sqlite3.wasm` | WASM SQLite binary (match sqlite3 pubspec.lock version) |
| `memoka_flutter/web/drift_worker.js` | Drift web worker (match drift pubspec.lock version) |
