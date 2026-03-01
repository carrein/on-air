# Archive Retention / Auto-Purge

## Overview

Server-side retention policy that auto-purges expired archived items. Configurable to Never (default), 30, 60, or 90 days. When enabled, archived notes and channels older than the retention period are permanently tombstoned — media files deleted from disk, DB rows set to `deletedAt`, and WebSocket events broadcast so all clients stay in sync.

Default is **0** (Never), preserving current behavior for existing deployments.

**Files**:
- `memoka_server/lib/src/settings/archive_purge_service.dart` (purge logic)
- `memoka_server/lib/src/settings/settings_endpoint.dart` (get/update settings)
- `memoka_server/lib/src/settings/app_settings.spy.yaml` (protocol model)
- `memoka_server/lib/src/shared/purge_helper.dart` (shared tombstone logic)
- `memoka_flutter/lib/providers/archive_retention_provider.dart` (client state)
- `memoka_flutter/lib/widgets/navbar.dart` (retention dropdown in Archive mode)

---

## Data Model

### AppSettings (protocol model, non-table)

Transport class for the settings API. The actual table is a manually-managed singleton (same pattern as `sync_state`).

| Field                  | Type  | Default | Description                                      |
|------------------------|-------|---------|--------------------------------------------------|
| `archiveRetentionDays` | `int` | `0`     | Days to retain archived items. 0 = never purge.  |

### app_settings (database table)

Singleton table with `CHECK (id = 1)` constraint. Created at server startup via `_ensureAppSettings()` in `server.dart` (not via Serverpod migration, since the schema validator can't model singleton tables with CHECK constraints).

```sql
CREATE TABLE IF NOT EXISTS "app_settings" (
    "id" bigint PRIMARY KEY DEFAULT 1,
    "archiveRetentionDays" bigint NOT NULL DEFAULT 0,
    CONSTRAINT "app_settings_singleton" CHECK ("id" = 1)
);
```

---

## Server: Purge Logic

### ArchivePurgeService

Static service class with a single entry point: `runPurge(Serverpod pod)`.

**Algorithm**:
1. Read `archiveRetentionDays` from `app_settings`. If 0, return immediately.
2. Compute cutoff = `now - retentionDays`.
3. **Purge expired notes**: query notes where `archived = true AND deletedAt IS NULL AND archivedAt < cutoff`. For each: call `PurgeHelper.tombstoneNote()`.
4. **Purge expired channels**: query channels where `archived = true AND deletedAt IS NULL AND archivedAt < cutoff`. For each: call `PurgeHelper.tombstoneChannel(skipLastChannelCheck: true)`.
5. Each item processed individually (consistent with existing per-entity transaction pattern).

**Re-entrance guard**: `_purgeInProgress` bool prevents overlapping runs if the hourly timer fires while a previous purge is still running.

**Error handling**: Per-item try/catch — a single failed item doesn't abort the entire purge cycle. Errors logged at `LogLevel.error`.

### Scheduling

In `server.dart`, after `_ensureDefaultChannel(pod)`:

```dart
await ArchivePurgeService.runPurge(pod);
Timer.periodic(const Duration(hours: 1), (_) => ArchivePurgeService.runPurge(pod));
```

Runs once on startup (catches items that expired while server was down) then every hour.

---

## Server: PurgeHelper

Shared static methods extracted from `ChatEndpoint` so both user-initiated deletes and auto-purge use the same tombstone logic.

### PurgeHelper.tombstoneNote(session, note)

1. Find all `MediaAttachment` rows for the note
2. Delete media files + thumbnails from disk
3. Set `deletedAt` and `updatedAt` on the note
4. Increment `globalVersion` in a transaction, stamp `note.version`
5. Broadcast `noteDeleted` event

### PurgeHelper.tombstoneChannel(session, channelId, {skipLastChannelCheck})

1. Optionally check "last active channel" guard (skipped for auto-purge)
2. Delete `data/media/channels/{id}/` directory recursively
3. Set `deletedAt` on the channel + bulk-update all its notes with `deletedAt` and `version`
4. Increment `globalVersion` in a transaction
5. Broadcast `channelDeleted` event

### ChatEndpoint Integration

`ChatEndpoint.deleteNote()` now calls `PurgeHelper.tombstoneNote()` for permanent deletes.
`ChatEndpoint.deleteChannel()` now delegates entirely to `PurgeHelper.tombstoneChannel()`.

---

## Server: Settings Endpoint

| Method                        | Return Type           | Description                          |
|-------------------------------|-----------------------|--------------------------------------|
| `getSettings(session)`        | `Future<AppSettings>` | Reads from `app_settings` singleton  |
| `updateSettings(session, s)`  | `Future<AppSettings>` | Updates `app_settings` singleton     |

Client access: `client.settings.getSettings()` / `client.settings.updateSettings(settings)`.

---

## Flutter: Retention Provider

### archiveRetentionProvider

Riverpod `@riverpod` async notifier (`ArchiveRetention extends _$ArchiveRetention`).

| Method                  | Description                                           |
|-------------------------|-------------------------------------------------------|
| `build()`               | Fetches current retention days from server. Returns 0 on error. |
| `updateRetention(days)` | Optimistically sets state, calls server. Reverts on failure. |

---

## Flutter: Navbar Dropdown

When `isArchive == true` (Archive detail mode), a `DropdownButton<int>` appears on the right side of the navbar between the title and the edge.

**Options**:

| Value | Label        |
|-------|--------------|
| `0`   | Keep Forever |
| `30`  | 30 Days      |
| `60`  | 60 Days      |
| `90`  | 90 Days      |

**Styling**:
- `isDense: true`
- Font: Space Grotesk 13px, w500, `_textColor` (`#00171F`) — must use `GoogleFonts.spaceGrotesk()` explicitly since `DropdownButton.style` replaces the theme's `DefaultTextStyle`
- Dropdown icon: `Icons.arrow_drop_down`, 18px, `#00171F`
- Dropdown background: `_backgroundColor` (`#F6F0ED`)
- No underline (`DropdownButtonHideUnderline`)

**Behavior**: watches `archiveRetentionProvider`, calls `updateRetention(value)` on change. Hidden when not in Archive view.

---

## State Management

### Providers

| Provider                    | Type               | Purpose                                 |
|-----------------------------|--------------------|-----------------------------------------|
| `archiveRetentionProvider`  | `AsyncValue<int>`  | Current retention setting (days)        |

### Server State

| Table          | Field                  | Purpose                     |
|----------------|------------------------|-----------------------------|
| `app_settings` | `archiveRetentionDays` | Persisted retention policy  |

---

## Related Files

| File | Purpose |
|------|---------|
| `memoka_server/lib/src/settings/archive_purge_service.dart` | Purge logic and scheduling |
| `memoka_server/lib/src/settings/settings_endpoint.dart` | Settings API endpoint |
| `memoka_server/lib/src/settings/app_settings.spy.yaml` | AppSettings protocol model |
| `memoka_server/lib/src/shared/purge_helper.dart` | Shared tombstone logic |
| `memoka_server/lib/server.dart` | Purge scheduling (startup + timer) |
| `memoka_server/lib/src/chat/chat_endpoint.dart` | Uses PurgeHelper for deletes |
| `memoka_server/lib/server.dart` (`_ensureAppSettings`) | Table + index creation at startup |
| `memoka_flutter/lib/providers/archive_retention_provider.dart` | Client-side retention state |
| `memoka_flutter/lib/widgets/navbar.dart` | Retention dropdown UI |
| `docs/components/Archive.md` | Archive feature documentation |
| `docs/components/Navbar.md` | Navbar component documentation |
