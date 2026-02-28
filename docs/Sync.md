# Sync Architecture

Memoka uses a **state-based reconciliation** sync model. When connectivity is restored after an offline period, the client pulls all server changes since its last known version, then pushes any locally dirty entities. This replaces the previous mutation-replay queue (which caused flicker, provisional-ID 404s, and order-dependent fragility).

---

## Core Concepts

### Server-Authoritative Versioning

Every entity (channel, note) has a monotonically increasing `version` field. A singleton `sync_state` table holds a global version counter. Every server-side mutation increments this counter and stamps the entity's `version` with the new value.

This means:
- `version` tells you the relative order of all mutations across all entity types.
- `syncPull(sinceVersion)` returns every entity mutated after a given point, regardless of type.

### Dirty Tracking

Instead of a separate mutations table, the local Drift cache uses a `dirty: bool` flag on each cached entity. When the user mutates an entity offline, the cache entry is written with `dirty = true`. On reconnect, the sync engine pushes all dirty entities in a single `syncPush` call.

### Tombstones

Permanent deletes do **not** remove rows from the database. Instead they set `deletedAt: DateTime`. This allows `syncPull` to inform clients about deletions. Clients filter `deletedAt IS NOT NULL` entities out of the UI.

**`archived` / `archivedAt`** = user-visible soft delete (recoverable archive feature).
**`deletedAt`** = protocol-level permanent delete tombstone (sync mechanism). These are separate concepts.

### Offline Creates (Temp IDs)

Offline-created entities get negative integer IDs locally (timestamp-based for uniqueness across restarts). Each offline create stores a `clientMutationId` (UUID). When the push phase applies the create on the server, the server returns a `serverId` mapping. The client replaces the temp ID in its cache.

---

## Data Model Changes

### Channels

New fields added to the `channels` table:
- `version: int` — entity version, set to globalVersion on each mutation
- `deletedAt: DateTime?` — permanent delete tombstone (null = not deleted)
- `position: double` — fractional ordering, replaces integer `sortOrder` (kept for backward compat)
- `clientMutationId: String?` — idempotency key for offline-created channels

New indexes: `channels_version_idx` on `version`, unique `client_mutation_ch_idx` on `clientMutationId`.

### Notes

New fields added to the `notes` table:
- `version: int` — entity version
- `deletedAt: DateTime?` — permanent delete tombstone

New index: `notes_version_idx` on `version`.

### Global Version Counter

Manual table (not a spy.yaml model — Serverpod ORM not used):

```sql
CREATE TABLE "sync_state" (
    "id" bigint PRIMARY KEY DEFAULT 1,
    "globalVersion" bigint NOT NULL DEFAULT 0,
    CONSTRAINT "sync_state_singleton" CHECK ("id" = 1)
);
```

---

## Sync Flow

### Trigger

`SyncEngine` listens to `connectionProvider`. When it transitions to `connected`, `_sync()` runs. A **2-second cooldown** prevents redundant syncs when multiple reconnect triggers fire in quick succession (e.g., Android lifecycle resume AND `connectivity_plus` both fire on wake).

```
_sync():
  0. If syncing or last sync < 2s ago → skip
  1. _pullPhase()
  2. _pushPhase()
  3. Refresh UI providers (see below)
```

### Post-Sync UI Refresh

Each data provider refreshes via a different mechanism — all avoid `AsyncLoading` flicker:

- **channelsProvider**: sync engine calls `refreshFromCache()` directly after pull+push
- **notesProvider**: listens to `syncEngineProvider` state (true→false) and calls `_refreshFromCache()` — reloads from Drift cache using `max(currentListSize, 50)` as limit to preserve scroll position
- **archiveItemsProvider**: listens to `connectionProvider` independently and re-fetches on reconnect
- **channelMediaDataProvider**: synchronous functional provider — auto-derives from `notesProvider`

### Pull Phase

```
_pullPhase():
  1. Read SyncMeta.globalVersion (lastSyncGlobalVersion)
  2. Call client.sync.syncPull(sinceVersion: lastSyncGlobalVersion)
  3. For each returned channel/note:
     a. If deletedAt != null AND not locally dirty → remove from cache
     b. If locally dirty → update stored baseVersion to server's version
        (preserves local changes; updated baseVersion is used in push)
     c. Else → upsert from server with dirty = false
  4. Write response.globalVersion → SyncMeta.globalVersion
```

The first pull (`sinceVersion = 0`) returns all entities — effectively a full sync.

### Push Phase

```
_pushPhase():
  1. Load dirty channels + dirty notes from cache
  2. If none → return
  3. Build List<SyncChange> from dirty entities
     - creates: entityJson with temp ID, baseVersion = 0, clientMutationId set, tempId set
     - updates: entityJson with server ID, baseVersion = server version stored in cache
     - deletes: deleted = true, serverId, baseVersion
  4. Call client.sync.syncPush(changes)
  5. For each SyncResult:
     - applied:
         clear dirty flag
         clear isNew flag
         store server version
         if create: replaceTemporaryId(tempId → serverId)
     - rejected:
         clear dirty + deletedLocally + isNew flags
         accept server entity JSON (overwrite local)
         if entity missing from server: remove local entry
     - already_applied (idempotent create duplicate):
         treat as applied
  6. Write response.globalVersion → SyncMeta.globalVersion
```

### Version Mismatch (Conflict)

When push sends `baseVersion` but the server entity has a different version (another device mutated it), the server returns `rejected` with the current server state. The client discards its local change and accepts the server version. **Last-write-wins**. No CRDTs or OT.

---

## SyncEndpoint (Server)

### `syncPull(Session, int sinceVersion)` → `SyncPullResponse`

- Queries `channels WHERE version > sinceVersion` (includes archived channels, tombstoned entities)
- Queries `notes WHERE version > sinceVersion` with LEFT JOIN on `media_attachments`
- Reads `sync_state.globalVersion`
- Returns `SyncPullResponse { globalVersion, channels, notes }`

### `syncPush(Session, List<SyncChange> changes)` → `SyncPushResponse`

Processes each change independently in its own DB transaction (partial apply):

1. Open transaction
2. Read entity from DB + validate `baseVersion` matches
3. If valid: `incrementGlobalVersion()` → apply change with `entity.version = newGv`
4. Commit → return `applied`

If version mismatch: return `rejected` with current server entity JSON.

**Defensive ordering**: incoming changes sorted by `(entityType, serverId ?? tempId)` for deterministic application.

**Business rules enforced**: can't archive last channel, content length limits, etc.

**WebSocket broadcast**: each applied change broadcasts the appropriate `ChatEvent`.

### Idempotency

Creates carry a `clientMutationId`. If a create is received with a `clientMutationId` already in the DB, the server returns `already_applied` with the existing entity — no duplicate created.

---

## Client Drift Schema (v3)

### CachedChannels — added columns

| Column | Type | Default |
|--------|------|---------|
| `version` | int | 0 |
| `dirty` | bool | false |
| `deletedLocally` | bool | false |
| `isNew` | bool | false — offline-created, needs temp→real ID map |
| `clientMutationId` | text? | null |

### CachedNotes — added same columns

### SyncMeta (new singleton table)

| Column | Type | Default |
|--------|------|---------|
| `id` | int PK | 1 |
| `globalVersion` | int | 0 |

### PendingMutations — dropped

Migration v2→v3 drops the `PendingMutations` table. Any queued mutations at upgrade time are lost (acceptable — user should be online before upgrading).

---

## Offline Operations (Client Providers)

### channels_provider.dart

| Operation | Offline behaviour |
|-----------|------------------|
| createChannel | `db.insertOfflineChannel(tempId, json, clientMutationId)` — dirty=true, isNew=true |
| updateChannel | `db.upsertChannelDirty(channel)` — dirty=true |
| deleteChannel | `db.markChannelDeletedLocally(id)` — dirty=true, deletedLocally=true |
| archiveChannel | Update cached channel `archived=true`, dirty=true |
| reorderChannels | Update cached positions, mark dirty |

### notes_provider.dart

| Operation | Offline behaviour |
|-----------|------------------|
| createNote | `db.insertOfflineNote(tempId, channelId, json, clientMutationId)` |
| updateNote (id < 0) | Update cached JSON directly (no mutation queue) |
| updateNote (id > 0) | `db.upsertNoteDirty(note)` — dirty=true |
| deleteNote (id < 0) | `db.deleteCachedNote(id)` — never existed on server |
| deleteNote (id > 0) | `db.markNoteDeletedLocally(id)` — dirty=true, deletedLocally=true |

---

## Sync Indicator

`memoka_flutter/lib/widgets/sync_indicator.dart`

Shown in the navbar action row (leftmost position):
- **Hidden** when connected with zero dirty entities, or during initial `connecting` phase
- **Rounded-square badge** with dirty count when offline (white text on `#CE2161`, 2px border radius)
- **Spinning `spinnerGap` icon** (`#CE2161`) when online and syncing

Count driven by `dirtySyncCountProvider` which watches `db.watchDirtyCount()` — a reactive Drift stream.

---

## WebSocket Events (Online)

WebSocket events still drive real-time updates when online. Each event handler in `channels_provider` and `notes_provider` stores the incoming entity's `version` in the local cache with `dirty = false`, so the next pull phase knows the client is up-to-date.

---

## Media Uploads

Media uploads remain a separate HTTP pipeline via `POST /media/upload`. They are not part of the sync model. The upload route creates a note + attachment in a DB transaction that also calls `incrementGlobalVersion()`, so the created note has a proper `version` and will appear in `syncPull` results.

---

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Offline create + update + delete same note | Cache entry created, updated, then `deleteCachedNote` removes it entirely. Nothing pushed. |
| Two devices edit same note offline | First to sync wins. Second's push is rejected; client accepts server version. |
| Server link preview fetch bumps version | Pull phase brings new version. If client has dirty local edit, push uses updated baseVersion. |
| Offline archive channel | Cached channel `archived=true, dirty=true`. Push sends as update. |
| Offline permanent delete | `deletedLocally=true, dirty=true`. Push sends `deleted=true`. Server tombstones. |
| Float position precision | 52 bisections before exhaustion. `reorderChannels` normalises all positions to 1.0, 2.0, 3.0… when two adjacent positions differ by less than 1e-10. |
| syncPull sinceVersion=0 | Returns all entities (first sync / upgrade). |
| Upgrade with pending mutations | Lost (PendingMutations dropped). |

---

## Connectivity Detection

`memoka_flutter/lib/providers/connection_provider.dart`

Unchanged from previous architecture — `connectionProvider` is a keepAlive `Notifier<ConnectionState>` driven by `chatStreamProvider` (WebSocket lifecycle + `client.health.ping()`) and OS-level `connectivity_plus` events.

---

## WASM SQLite (Web)

Two files must be present in `memoka_flutter/web/`:
- **`sqlite3.wasm`** — compiled SQLite module (from [sqlite3.dart releases](https://github.com/simolus3/sqlite3.dart/releases), match `sqlite3` version in `pubspec.lock`)
- **`drift_worker.js`** — web worker for shared database access across tabs (from [drift releases](https://github.com/simolus3/drift/releases), match `drift` version in `pubspec.lock`)

---

## Key Files

| File | Purpose |
|------|---------|
| `memoka_server/lib/src/sync/sync_endpoint.dart` | `syncPull` and `syncPush` RPC methods |
| `memoka_server/lib/src/sync/version_helper.dart` | `incrementGlobalVersion()` helper |
| `memoka_server/lib/src/chat/chat_endpoint.dart` | All mutations wrap `incrementGlobalVersion()` in transaction |
| `memoka_server/lib/src/web/routes/media_upload_route.dart` | Upload transaction calls `incrementGlobalVersion()` |
| `memoka_flutter/lib/local_db/database.dart` | Drift schema v3, dirty tracking helpers |
| `memoka_flutter/lib/providers/sync_engine_provider.dart` | Pull-then-push sync cycle on reconnect |
| `memoka_flutter/lib/providers/dirty_sync_count_provider.dart` | Dirty entity count stream for UI |
| `memoka_flutter/lib/providers/channels_provider.dart` | Dirty flag writes replace mutation queue |
| `memoka_flutter/lib/providers/notes_provider.dart` | Dirty flag writes replace mutation queue |
| `memoka_flutter/lib/providers/connection_provider.dart` | Online/offline state |
| `memoka_flutter/lib/providers/chat_stream_provider.dart` | WebSocket + exponential backoff |
| `memoka_flutter/lib/widgets/sync_indicator.dart` | Navbar dirty-count badge |
| `memoka_flutter/web/sqlite3.wasm` | WASM SQLite binary |
| `memoka_flutter/web/drift_worker.js` | Drift web worker |
