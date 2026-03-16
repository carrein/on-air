# Reminder

## Overview

Reminders allow users to schedule notifications on individual notes. When the scheduled time arrives, the server broadcasts a WebSocket event and the client shows a local notification. Tapping the notification navigates to the note's channel and scrolls to it.

## Recurring Reminders

Reminders support optional recurrence: Daily, Weekly, or Monthly. Uses RRULE pattern — single `reminders` table with `recurrenceRule` (text) and `recurrenceEndAt` (timestamptz) columns.

**Supported RRULE values:**
- `FREQ=DAILY` — every day at the same time
- `FREQ=WEEKLY;BYDAY=MO` — every week on the specified day (derived from selected date)
- `FREQ=MONTHLY;BYMONTHDAY=15` — every month on the specified day (derived from selected date)

**Lifecycle (recurring):**
1. User sets recurring reminder via picker (Repeat dropdown + optional End date)
2. Server stores `recurrenceRule` and `recurrenceEndAt` alongside `scheduledAt`
3. When `scheduledAt` is due, server broadcasts `reminderDue`, then computes next occurrence
4. If next occurrence <= `recurrenceEndAt` (or no end): UPDATE `scheduledAt` to next, keep `fired=false`
5. If series complete (past end date): DELETE the row, broadcast `reminderDeleted`
6. Client shows notification but skips `acknowledgeReminder` for recurring (checks via `getReminder`)
7. Missed fires while offline: server skips to next future occurrence (no backlog)

**Picker UX:** Two-step dialog — first date/time picker (OmniDateTimePicker), then recurrence dialog with Repeat (None/Daily/Weekly/Monthly) and End (Never/On date...) dropdowns.

**MediaPanel:** One row per reminder with repeat icon (`arrowsClockwise`) + label (e.g., "Daily", "Weekly (Mon)", "Monthly (15th)").

## UX Flow

### Setting a Reminder

**Web (context menu):**
1. Right-click a note → context menu shows "Set Reminder" option
2. Combined date/time picker dialog appears
3. User selects date and time → reminder is created on the server

**Mobile (selection mode):**
1. Long-press a note to enter selection mode (can multi-select)
2. Navbar selection bar shows a reminder icon (siren) next to the archive icon
3. Tap reminder icon → combined date/time picker dialog appears
4. All selected notes receive the same reminder time

**Web context menu also available on web** — "Set Reminder" appears alongside Copy, Edit, Archive, Select.

### Visual Indicator

Notes with an active reminder display a **siren PhosphorIcon in pink** (`#CE2161`) next to the note's timestamp in `_NoteFooter`.

### Reminder Lifecycle (Zero-Polling Architecture)

**Three-layer delivery** — per-reminder timers on both server and client, zero polling:

1. User sets reminder → server creates `reminders` row, inserts into in-memory priority queue, schedules a per-reminder `Timer` for the exact `scheduledAt` time
2. Client independently schedules its own timer:
   - **Web**: Web Worker (`reminder_worker.js`) — timers NOT throttled in background tabs
   - **Android**: `zonedSchedule` via OS alarm system — survives app kill, background, phone reboot
3. When `scheduledAt` arrives:
   - **Server** fires its timer → broadcasts `reminderDue` WebSocket event, handles one-shot (set `fired=true`) or recurring (reschedule)
   - **Client** fires its timer independently → shows local notification, acknowledges one-shot
4. **Deduplication**: Client tracks `_firedLocally` set. When WebSocket `reminderDue` arrives for an already-fired noteId, it skips notification (prevents double-fire)
5. **If client is offline/killed**: reminder stays on server with `fired = true`
6. **On reconnect**: client calls `getFiredReminders()` → shows notifications for all missed reminders
7. **Server restart**: `ReminderService.init()` reloads queue from DB, schedules timers for all unfired reminders

**Key guarantees**:
- **Precise delivery**: Fires at the exact scheduled second, not within a 60s window
- **No polling**: Zero `Timer.periodic` on both server and client
- **Never lost**: Three independent delivery paths (client timer, server timer + WebSocket, reconnect pull)

### Notification Content

- **Title**: "Reminder"
- **Body**: Note content (truncated). For media/image notes, use placeholder text like "Media note in #channelName"
- **On tap**: Navigate to the note's channel and scroll to the note (uses existing `scrollToNoteProvider` + channel switching pattern)

### MediaPanel — Reminders Tab

A 5th tab added to MediaPanel: **Images | Videos | Docs | Links | Reminders**

Each reminder item shows:
- Note content snippet (truncated)
- Channel name (with emoji)
- Scheduled date/time
- Actions:
  - **Tap**: Scroll to the note in its channel
  - **Edit**: Change the scheduled time (opens date/time picker)
  - **Cancel**: Delete the reminder

Items sorted by `scheduledAt` ascending (soonest first).

Empty state: centered clock icon + "No reminders"

## Architecture

### Database — `reminders` Table (Untracked)

Follows the untracked table pattern used by `note_search` and `page_watches`. Created at server startup by `ReminderSetup.ensureReminderTable()`. Not in any `.spy.yaml`.

```sql
CREATE TABLE IF NOT EXISTS "reminders" (
  "id" bigserial PRIMARY KEY,
  "noteId" bigint NOT NULL REFERENCES "notes"("id") ON DELETE CASCADE,
  "channelId" bigint NOT NULL REFERENCES "channels"("id") ON DELETE CASCADE,
  "scheduledAt" timestamptz NOT NULL,
  "noteContent" text,
  "fired" boolean NOT NULL DEFAULT false,
  "createdAt" timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT "reminders_note_unique" UNIQUE ("noteId")
);

CREATE INDEX IF NOT EXISTS "reminders_scheduled_idx"
  ON "reminders" ("scheduledAt") WHERE "fired" = false;

CREATE INDEX IF NOT EXISTS "reminders_fired_idx"
  ON "reminders" ("fired") WHERE "fired" = true;
```

- One reminder per note (UNIQUE on `noteId`)
- CASCADE delete when note or channel is deleted
- `noteContent` cached at creation time for notification body (avoids JOIN at fire time)
- Index on `scheduledAt` for efficient queue loading and queries

### Server Components

**`ReminderSetup`** (`memoka_server/lib/src/reminder/reminder_setup.dart`)
- `ensureReminderTable(Session)` — creates table + index if not exists
- Called from `server.dart` after `pod.start()`

**`ReminderEndpoint`** (`memoka_server/lib/src/reminder/reminder_endpoint.dart`)
- `createReminder(Session, int noteId, DateTime scheduledAt, {String? recurrenceRule, DateTime? recurrenceEndAt})` — creates/upserts reminder
- `deleteReminder(Session, int noteId)` — deletes reminder
- `getReminder(Session, int noteId)` — returns reminder or null
- `updateReminder(Session, int noteId, DateTime scheduledAt, {String? recurrenceRule, DateTime? recurrenceEndAt})` — updates scheduled time + recurrence
- `getReminders(Session, int channelId)` — returns all reminders for a channel (for MediaPanel)
- `getFiredReminders(Session)` — returns all reminders where `fired = true` (for reconnect delivery)
- `getActiveReminders(Session)` — returns all unfired reminders (for client-side timer seeding on init)
- `acknowledgeReminder(Session, int noteId)` — deletes fired one-shot reminders only (recurring have no fired=true)

**`ReminderService`** (`memoka_server/lib/src/reminder/reminder_service.dart`)
- Priority queue + per-reminder `Timer` (replaces 60s batch poll)
- `init(Serverpod)` — loads all unfired reminders from DB, populates sorted queue, schedules first timer
- `_scheduleNext()` — cancels existing timer, sets new `Timer(duration, _fire)` for queue head
- `_fire(entry)` — removes from queue, broadcasts `reminderDue`, handles one-shot (`fired=true`) vs recurring (compute next, re-insert into queue), then calls `_scheduleNext()`
- `onReminderCreated(...)` — called by endpoint after create; inserts into queue, re-schedules if soonest
- `onReminderUpdated(noteId, scheduledAt, ...)` — called by endpoint after update; removes old, inserts new
- `onReminderDeleted(noteId)` — called by endpoint after delete; removes from queue
- Registered in `server.dart` as `ReminderService.init(pod)` (single call, no Timer.periodic)

### Protocol Model

**`Reminder`** (non-table, defined in `.spy.yaml` for serialization):
```yaml
class: Reminder
fields:
  noteId: int
  channelId: int
  scheduledAt: DateTime
  noteContent: String?
  fired: bool
  createdAt: DateTime
  recurrenceRule: String?
  recurrenceEndAt: DateTime?
```

### Client Components

**`reminder_provider.dart`** — Riverpod notifier keyed by `noteId`
- `createReminder(DateTime scheduledAt)` — calls endpoint
- `deleteReminder()` — calls endpoint
- `updateReminder(DateTime scheduledAt)` — calls endpoint
- `hasReminder` getter

**`channel_reminders_provider.dart`** — Riverpod provider keyed by `channelId`
- Returns `List<Reminder>` for the channel (for MediaPanel tab)
- Watches `notesProvider(channelId)` to invalidate when notes change

**`reminder_scheduler_provider.dart`** — Client-side timer orchestration (`@Riverpod(keepAlive: true)`)
- On init: fetches `getActiveReminders()` from server, schedules all future reminders
- **Web**: creates Web Worker (`reminder_worker.js`) via conditional import; on `fired` message → show notification, acknowledge/reschedule
- **Android**: calls `scheduleReminderNotification()` (OS `zonedSchedule`) for each future reminder
- Tracks `Set<int> _firedLocally` to deduplicate with WebSocket backup
- Exposes `schedule(Reminder)` and `cancel(int noteId)`

**`reminder_listener_provider.dart`** — WebSocket event listener + reconnect handler
- Listens for `reminderDue` events from `chatStreamProvider`
- Deduplicates with `_firedLocally` from scheduler — skips notification if already fired locally
- On `reminderCreated`/`reminderDeleted` events: fetches reminder, calls scheduler `schedule()`/`cancel()`
- **On reconnect**: calls `getFiredReminders()` to catch any reminders fired while offline
- **No polling**: 30s Timer.periodic removed

**Notification service additions:**
- `showReminderNotification(noteId, channelId, body)` in both web and Android implementations
- `scheduleReminderNotification(noteId, channelId, scheduledAt, body)` — Android: `zonedSchedule` with exact alarm; Web: no-op (Worker handles it)
- `cancelScheduledReminder(noteId)` — Android: cancel scheduled notification; Web: no-op

**Reminder timer service** (conditional import: `reminder_timer.dart`)
- `reminder_timer_web.dart` — Web Worker lifecycle: `initWorker`, `scheduleWorkerTimer`, `cancelWorkerTimer`, `disposeWorker`
- `reminder_timer_stub.dart` — Native no-ops (Android uses `zonedSchedule` instead)

### UI Changes

**`note_item.dart` — `_NoteFooter`:**
- After timestamp Text widget, add conditional siren icon:
  ```dart
  if (hasReminder)
    Padding(
      padding: EdgeInsets.only(left: 4),
      child: PhosphorIcon(PhosphorIcons.siren(PhosphorIconsStyle.fill), size: 14, color: Color(0xFFCE2161)),
    )
  ```
- `hasReminder` determined by watching `reminderProvider(note.id)`

**`note_item.dart` — `_showContextMenu()`:**
- Add "Set Reminder" option with siren icon
- If reminder already exists, show "Edit Reminder" / "Cancel Reminder" instead

**`navbar.dart` — `_buildSelectionBar()`:**
- Add siren icon button next to archive button
- On tap: show combined date/time picker, create reminders for all selected notes

**`media_panel.dart`:**
- Add 5th tab "Reminders"
- New `ReminderList` widget showing sorted reminder items
- New `ReminderListItem` widget with snippet, time, channel, edit/cancel actions

**Date/time picker:**
- Add `omni_datetime_picker` package (or similar) for combined date+time selection
- Minimum selectable time: now + 1 minute
- Shared picker function used by both context menu and selection bar

## File Manifest

### New Files (Server)
- `memoka_server/lib/src/reminder/reminder_setup.dart`
- `memoka_server/lib/src/reminder/reminder_endpoint.dart`
- `memoka_server/lib/src/reminder/reminder_service.dart`
- `memoka_server/lib/src/protocol/reminder.spy.yaml`

### New Files (Client)
- `memoka_flutter/lib/providers/reminder_provider.dart`
- `memoka_flutter/lib/providers/channel_reminders_provider.dart`
- `memoka_flutter/lib/providers/reminder_listener_provider.dart`
- `memoka_flutter/lib/providers/reminder_scheduler_provider.dart` — client-side timer orchestration
- `memoka_flutter/lib/widgets/reminder_list.dart`
- `memoka_flutter/lib/widgets/reminder_list_item.dart`
- `memoka_flutter/lib/services/reminder_timer.dart` — conditional export for Worker
- `memoka_flutter/lib/services/reminder_timer_stub.dart` — native no-ops
- `memoka_flutter/lib/services/reminder_timer_web.dart` — Web Worker lifecycle
- `memoka_flutter/web/reminder_worker.js` — Web Worker for precise timer scheduling

### Modified Files
- `memoka_server/lib/server.dart` — `ReminderService.init(pod)` (replaces Timer.periodic)
- `memoka_server/lib/src/reminder/reminder_service.dart` — priority queue + per-reminder Timer
- `memoka_server/lib/src/reminder/reminder_endpoint.dart` — `getActiveReminders()` + scheduler notifications
- `memoka_flutter/lib/main.dart` — `tz.initializeTimeZones()`
- `memoka_flutter/lib/widgets/note_item.dart` — siren icon in footer + context menu option
- `memoka_flutter/lib/widgets/navbar.dart` — reminder icon in selection bar
- `memoka_flutter/lib/widgets/media_panel.dart` — 5th tab
- `memoka_flutter/lib/services/notification_service_web.dart` — showReminderNotification + no-op stubs
- `memoka_flutter/lib/services/notification_service_stub.dart` — showReminderNotification + scheduleReminderNotification + cancelScheduledReminder
- `memoka_flutter/lib/services/notification_service.dart` — re-export new functions
- `memoka_flutter/pubspec.yaml` — add timezone + omni_datetime_picker dependency

### Code Generation Required
- `serverpod generate` (new endpoint)
- `dart run build_runner build --delete-conflicting-outputs` (new Riverpod providers)
