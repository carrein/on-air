# Page Watch

## Overview

URL change monitoring for single-URL notes. A bell icon appears in the note footer for any note whose content resolves to exactly one URL. Tapping the bell creates a server-side watch that periodically polls the URL, hashes the visible text content, and sends a push notification when the page changes.

**Files**:
- `memoka_server/lib/src/page_watch/page_watch_setup.dart` (DB infrastructure: table, indexes)
- `memoka_server/lib/src/page_watch/page_watch_endpoint.dart` (CRUD + acknowledge endpoints)
- `memoka_server/lib/src/page_watch/page_watch_poller.dart` (periodic polling loop)
- `memoka_server/lib/src/page_watch/page_watch.spy.yaml` (PageWatch protocol model, non-table)
- `memoka_server/lib/server.dart` (startup call to `PageWatchSetup.ensurePageWatchInfrastructure`)
- `memoka_flutter/lib/providers/page_watch_provider.dart` (watch state per note)
- `memoka_flutter/lib/widgets/note_item.dart` (bell icon rendering in note footer)

---

## How It Works

1. User taps bell icon on a single-URL note
2. Client calls `createWatch(noteId)` -- server extracts URL from the note, fetches the page, stores baseline hash
3. Server polls all enabled watches every 5 minutes
4. For each watch: fetch URL, strip `<script>`, `<style>`, `<noscript>` tags, extract body text, compute SHA-256 hash
5. Compare hash to stored `contentHash` -- if different, mark `hasUnacknowledgedChange = true`, broadcast `pageChanged` WebSocket event, send push notification
6. First check after creation stores the baseline hash only (no notification)
7. User taps the pink-dot bell to acknowledge -- client calls `acknowledgeChange(noteId)`, clears the flag

---

## Conditional Requests

The poller uses HTTP conditional requests to avoid redundant downloads:

- Stores `etag` and `lastModified` from response headers on each successful fetch
- Sends `If-None-Match` (ETag) and `If-Modified-Since` headers on subsequent requests
- On HTTP 304 Not Modified: updates `lastCheckedAt`, skips hash comparison
- On HTTP 200: proceeds with normal hash comparison

These fields are server-internal and not exposed in the `PageWatch` protocol model sent to clients.

---

## Failure Handling

- Each fetch failure increments `consecutiveFailures` and stores the error in `lastError`
- On success, `consecutiveFailures` resets to 0
- After 5 consecutive failures, the watch is auto-disabled (`enabled = false`)
- A `pageWatchDisabled` WebSocket event is broadcast so the client can update the bell icon to the error state
- User can re-enable by tapping the bell icon again (calls `createWatch`, which re-enables an existing disabled watch)

---

## Auto-Disable on Archive/Delete

- Archiving or deleting a note sets `enabled = false` on its watch (server-side, in the archive/delete endpoint logic)
- Hard deletes (permanent deletion from Archive view) cascade via FK constraint -- the `page_watches` row is deleted automatically
- Restoring an archived note does NOT re-enable the watch -- user must manually tap the bell again

---

## Data Model

### PageWatch (protocol model, non-table)

Used for API transport between server and client. Does not include server-internal fields (`etag`, `lastModified`).

| Field                      | Type        | Description                                            |
|----------------------------|-------------|--------------------------------------------------------|
| `noteId`                   | `int`       | FK to the watched note                                 |
| `channelId`                | `int`       | FK to the note's channel                               |
| `url`                      | `String`    | The monitored URL                                      |
| `contentHash`              | `String?`   | SHA-256 of last fetched body text (null before first check) |
| `lastCheckedAt`            | `DateTime?` | When the URL was last polled (null before first check) |
| `enabled`                  | `bool`      | Whether polling is active                              |
| `consecutiveFailures`      | `int`       | Number of sequential fetch failures (0-5)              |
| `lastError`                | `String?`   | Error message from most recent failure                 |
| `hasUnacknowledgedChange`  | `bool`      | True if a change was detected but not yet acknowledged |
| `createdAt`                | `DateTime`  | When the watch was created                             |
| `updatedAt`                | `DateTime`  | When the watch was last modified                       |

### page_watches (database table, untracked)

Created at server startup by `PageWatchSetup.ensurePageWatchInfrastructure()`. Not in any `.spy.yaml` with `table:` -- invisible to Serverpod's schema validator (same pattern as `note_search`).

| Column                       | Type          | Description                                            |
|------------------------------|---------------|--------------------------------------------------------|
| `id`                         | `bigserial`   | PK                                                     |
| `note_id`                    | `bigint`      | FK -> `notes(id)` ON DELETE CASCADE                    |
| `channel_id`                 | `bigint`      | FK -> `channels(id)` ON DELETE CASCADE                 |
| `url`                        | `text`        | The monitored URL                                      |
| `content_hash`               | `text`        | SHA-256 hex digest of body text                        |
| `last_checked_at`            | `timestamptz` | When the URL was last polled                           |
| `enabled`                    | `boolean`     | Whether polling is active (default `true`)             |
| `consecutive_failures`       | `int`         | Sequential fetch failure count (default `0`)           |
| `last_error`                 | `text`        | Error message from most recent failure                 |
| `has_unacknowledged_change`  | `boolean`     | Change detected but not acknowledged (default `false`) |
| `etag`                       | `text`        | ETag header from last successful response              |
| `last_modified`              | `text`        | Last-Modified header from last successful response     |
| `created_at`                 | `timestamptz` | Row creation timestamp                                 |
| `updated_at`                 | `timestamptz` | Row last-update timestamp                              |

**Indexes**:
- `page_watches_note_id_idx`: UNIQUE index on `note_id` (one watch per note)
- `page_watches_enabled_idx`: Partial index on `enabled = true` (poller queries only active watches)

---

## Server: Page Watch Setup

`PageWatchSetup.ensurePageWatchInfrastructure(Session session)` -- called once at server startup from `server.dart`. Idempotent: checks if `page_watches` table exists, returns immediately if so.

On first run:
1. Creates `page_watches` table with all columns listed above
2. Creates UNIQUE index on `note_id`
3. Creates partial index on `enabled = true`
4. Adds FK constraints to `notes(id)` and `channels(id)` with ON DELETE CASCADE

---

## Server: Page Watch Endpoint

### createWatch(session, noteId)

Creates a new watch or re-enables an existing disabled watch. Validates the note exists, is not archived/deleted, and contains exactly one URL. Fetches the page immediately to store the baseline hash. Returns `PageWatch`.

### deleteWatch(session, noteId)

Removes the watch. Returns `void`.

### getWatch(session, noteId)

Returns the current watch state, or `null` if no watch exists. Returns `PageWatch?`.

### getWatches(session, channelId)

Returns all page watches for a channel. Used by `channelPageWatchesProvider` to batch-fetch watch state for all notes in a channel (1 RPC instead of N per-note fetches). Returns `List<PageWatch>`.

### acknowledgeChange(session, noteId)

Clears `hasUnacknowledgedChange` flag. Returns `void`.

---

## Server: Poller

`PageWatchPoller` runs a periodic timer (every 5 minutes) that queries all enabled watches and checks each URL.

### Poll cycle per watch:

1. Send GET request with conditional headers (`If-None-Match`, `If-Modified-Since`) if stored
2. On HTTP 304: update `lastCheckedAt`, skip remaining steps
3. On HTTP 200: strip `<script>`, `<style>`, `<noscript>` tags from HTML body, extract visible text, compute SHA-256 hex digest
4. If `contentHash` is null (first check): store hash as baseline, no notification
5. If hash differs from stored: update `contentHash`, set `hasUnacknowledgedChange = true`, broadcast `pageChanged` WebSocket event (includes the note with its `linkPreview`), send push notification
6. If hash matches: update `lastCheckedAt` only
7. Store `etag` and `lastModified` from response headers
8. On fetch error: increment `consecutiveFailures`, store error in `lastError`; if `consecutiveFailures >= 5`, set `enabled = false`, broadcast `pageWatchDisabled` event

---

## WebSocket Events

| Event type          | Payload                         | When                                       |
|---------------------|---------------------------------|--------------------------------------------|
| `pageChanged`       | Note (with linkPreview)         | Content hash changed on a watched URL      |
| `pageWatchDisabled` | noteId, channelId               | Watch auto-disabled after 5 failures       |

Both events are broadcast via MessageCentral to all connected sessions.

---

## Bell Icon States

The bell icon appears in the note footer only for notes with exactly one URL. It is hidden in archive view.

| State | Icon | Color | Condition |
|-------|------|-------|-----------|
| Not watching | `Icons.notifications_none_outlined` | Grey | No watch exists, or watch deleted |
| Watching (no changes) | `Icons.notifications` | Default (filled) | `enabled = true`, `hasUnacknowledgedChange = false` |
| Unacknowledged change | `Icons.notifications` + pink dot | Filled + pink dot overlay | `hasUnacknowledgedChange = true` |
| Error / disabled | `Icons.notifications_active` | Red | `enabled = false` due to consecutive failures |

### Interactions:

- Tap on "Not watching" -> calls `createWatch(noteId)`, transitions to "Watching"
- Tap on "Unacknowledged change" -> calls `acknowledgeChange(noteId)`, transitions to "Watching"
- Tap on "Error / disabled" -> calls `createWatch(noteId)` (re-enables), transitions to "Watching"
- Long-press on any active state -> calls `deleteWatch(noteId)`, transitions to "Not watching"

---

## Notifications

When a watched page changes:

| Field | Value |
|-------|-------|
| Title | Page title from the note's `linkPreview` |
| Body  | "`domain` has new content" (extracted from URL) |
| Icon  | Favicon URL from `linkPreview.faviconUrl` |

### Tap action:

- **Android**: opens URL via `url_launcher`
- **Web**: opens URL via `window.open`

Uses the same platform-conditional notification infrastructure as the test notification harness (see `docs/Notification.md`).

---

## Limitations

- **Static HTML only**: the poller fetches raw HTML and does not execute JavaScript. Pages that render content client-side (SPAs, React apps, etc.) will not be monitored accurately.
- **One URL per note**: the bell icon only appears when the note content contains exactly one URL. Multi-URL notes are not supported.
- **Notification once per change**: only one notification is sent per detected change. The user must acknowledge (tap the pink dot bell) before the next change will trigger a new notification.

---

## Related Files

| File | Purpose |
|------|---------|
| `memoka_server/lib/src/page_watch/page_watch_setup.dart` | DB infrastructure (table, indexes, FK constraints) |
| `memoka_server/lib/src/page_watch/page_watch_endpoint.dart` | CRUD + acknowledge API |
| `memoka_server/lib/src/page_watch/page_watch_poller.dart` | Periodic URL polling loop |
| `memoka_server/lib/src/page_watch/page_watch.spy.yaml` | PageWatch protocol model (non-table) |
| `memoka_server/lib/server.dart` | Startup: `PageWatchSetup` + `PageWatchPoller` init |
| `memoka_flutter/lib/providers/page_watch_provider.dart` | Watch state per note (mutations) |
| `memoka_flutter/lib/providers/channel_page_watches_provider.dart` | Batch watch state per channel (display) |
| `memoka_flutter/lib/widgets/note_item.dart` | Bell icon rendering in note footer (`_PageWatchBell`) |
