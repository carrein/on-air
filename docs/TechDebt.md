# Technical Debt

Tracked items from the 2026-03-24 codebase audit. Priority order: C7 > C1 > M3.

---

## C7 — Test Coverage

**Priority:** High
**Impact:** Regression safety, refactor confidence

### Current State

**Server tests** (`memoka_server/test/`):
- `integration/chat_endpoint_test.dart` — channels, notes, archive (partial)
- `integration/sync_endpoint_test.dart` — pull/push (partial — note update/delete via push untested)
- `integration/search_endpoint_test.dart` — hybrid FTS + trigram

**Flutter tests** (`memoka_flutter/test/`):
- `local_db/database_test.dart` — Drift schema
- `widgets/sync_indicator_test.dart` — widget test

### Gaps

**Server — zero test coverage:**
- `SettingsEndpoint` (getSettings, updateSettings)
- `PageWatchEndpoint` (createWatch, deleteWatch, getWatch, acknowledgeChange)
- `ReminderEndpoint` (createReminder, deleteReminder, updateReminder, getReminder, getReminders, getFiredReminders, getActiveReminders, acknowledgeReminder)
- `ArchivePurgeService.runPurge`
- `PageWatchService.runCheck`
- `ReminderService` (timer scheduling, firing, recurrence)
- `MediaUploadRoute` (HTTP route — harder to test but critical)

**Server — partial coverage (missing scenarios):**
- `ChatEndpoint`: archiveChannel, restoreChannel, updateChannel, reorderChannels, link preview fetch
- `SyncEndpoint`: note update/delete via push, channel delete via push

**Flutter — near-zero coverage:**
- `channels_provider.dart` — offline mutation flow, dirty tracking, provisional ID replacement
- `notes_provider.dart` — same offline mutation flow
- `sync_engine_provider.dart` — pull/push reconciliation, conflict resolution, tombstone handling
- `pending_uploads_provider.dart` — upload queue, retry, cancel, ghost note lifecycle
- `connection_provider.dart` / `debounced_connection_provider.dart` — state transitions
- `database.dart` — migration paths, dirty query correctness
- All archive operations (restore, permanent delete, optimistic updates)

### Approach

Server integration tests use `withServerpod` from `serverpod_test`. Tests auto-start Serverpod in test mode, use separate DB/Redis containers (ports 9090/9091), and roll back after each test.

Suggested order:
1. `SettingsEndpoint` — simplest, builds test infrastructure confidence
2. `ReminderEndpoint` — complex logic (recurrence, firing, one-shot vs recurring)
3. `PageWatchEndpoint` — depends on external HTTP (may need mocking)
4. `SyncEndpoint` gaps — note update/delete push, channel delete push
5. `ChatEndpoint` gaps — archive/restore, reorder
6. Flutter providers — requires Riverpod testing setup with mocked client

---

## C1 — SQL Parameterization

**Priority:** Medium
**Impact:** Security hardening, bug prevention (special characters in content)

### Current State

All raw SQL uses `session.db.unsafeQuery()` with Dart string interpolation. No parameterized queries anywhere. 15 `unsafeQuery` callsites across the server.

Serverpod's `unsafeQuery` does NOT support positional parameters (`$1`, `$2`) natively. The alternative is to use the Serverpod ORM where possible, or to sanitize inputs manually.

### Affected Files

| File | Interpolated Values | Risk |
|------|-------------------|------|
| `chat_endpoint.dart` | `channelId`, `beforeId`, `note.id`, `channelIds.join(",")` | Medium — all integers |
| `sync_endpoint.dart` | `sinceVersion`, `serverId`, timestamps | Medium — integers + timestamps |
| `search_endpoint.dart` | User search query words (escaped via `escapeSql`) | **High** — arbitrary user text into tsquery/ILIKE |
| `page_watch_endpoint.dart` | `noteId`, URL (escaped via `escapeSql`) | Medium — URL is user-provided |
| `page_watch_service.dart` | `watchId`, `newHash`, timestamps | Low — all server-derived |
| `reminder_endpoint.dart` | `noteId`, `channelId`, timestamps, `recurrenceRule` | Medium — recurrenceRule is user-provided |
| `settings_endpoint.dart` | `archiveRetentionDays` | Low — integer |
| `purge_helper.dart` | `channelId`, timestamps | Low — server-derived |
| `shared/constants.dart` | Channel name for version increment | Low — validated before use |

### Approach

Since Serverpod doesn't support positional params in `unsafeQuery`, options:
1. **Replace with ORM calls** where possible (getChannels, findById patterns)
2. **Use `DatabasePoolManager.query` with parameters** if available in Serverpod 3.3.1 (needs investigation)
3. **Strengthen `escapeSql`** to handle null bytes, semicolons, and tsquery-specific chars
4. **Prioritize `search_endpoint.dart`** — only callsite with truly arbitrary user input

---

## M3 — Shared Offline Mutation Helper

**Priority:** Low
**Impact:** Developer velocity, consistency

### Current State

The try-RPC/catch-network/dirty-cache pattern is duplicated ~16 times across two providers.

**`channels_provider.dart` methods:**
- `createChannel`, `updateChannel`, `pinChannel`, `unpinChannel`, `archiveChannel`, `restoreChannel`, `reorderChannels`, `deleteChannel`

**`notes_provider.dart` methods:**
- `createNote`, `updateNote`, `deleteNote`, `archiveNote`, `restoreNote`, `loadMore`

All follow:
```dart
try {
  final result = await client.<endpoint>.<method>(...);
  // update state + cache
  return result;
} catch (e) {
  if (_isNetworkError(e)) {
    // write dirty flag to local DB
    // return optimistic value
  }
  rethrow;
}
```

### Approach

Extract a generic helper:
```dart
Future<T> offlineMutation<T>({
  required Future<T> Function() rpc,
  required Future<T> Function() offlineFallback,
  required Future<void> Function(T) onSuccess,
}) async {
  try {
    final result = await rpc();
    await onSuccess(result);
    return result;
  } catch (e) {
    if (_isNetworkError(e)) {
      return offlineFallback();
    }
    rethrow;
  }
}
```

Considerations:
- Each mutation has slightly different cache-write logic (create vs update vs delete)
- Some mutations update local state optimistically before RPC (reorder)
- The helper should be flexible enough to handle these variations without becoming more complex than the duplication it replaces
- Test the helper in isolation before migrating all callsites
