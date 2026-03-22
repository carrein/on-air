u/docs/Deployment.md
u/docs/Android.md
u/docs/Emulator.md
u/docs/Channel.md
u/docs/Media.md
u/docs/ImageGrid.md
u/docs/Overview.md
u/docs/Security.md
u/docs/DesignSystem.md
u/docs/Settings.md
u/docs/components/ChannelList.md
u/docs/components/Input.md
u/docs/components/Navbar.md
u/docs/components/Archive.md
u/docs/components/NewChannelModal.md
u/docs/components/Icon.md
u/docs/components/MediaPanel.md
u/docs/components/Note.md
u/docs/components/Preview.md
u/docs/components/Audio.md
u/docs/Sync.md
u/docs/GIF.md
u/docs/ArchiveRetention.md
u/docs/Search.md
u/docs/Shortcuts.md
u/docs/Notification.md
u/docs/PageWatch.md
u/docs/Reminder.md
u/docs/Seed.md

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Memoka is a real-time chat-style notes application for organizing thoughts in topical channels. Built with Serverpod (v3.3.1), consisting of three main packages:

- **memoka_server**: Serverpod backend server (Dart)
- **memoka_client**: Generated client library (Dart)
- **memoka_flutter**: Flutter mobile/web application

Serverpod is a backend framework for Dart/Flutter that handles database connections, endpoints, and code generation.

## Features

- **Channels**: Create, update, delete, pin/unpin, emoji identifiers, drag-to-reorder, archive/restore
- **Notes**: Create, update, delete with cursor-based pagination, archive/restore
- **Real-time**: WebSocket streaming via MessageCentral for live updates
- **Link Previews**: Automatic URL detection with OpenGraph/Twitter Card metadata
- **Media Uploads**: Image/document upload with drag-and-drop, paste, multi-file batch upload, thumbnail generation; any `image/*` format accepted (non-web-safe formats converted to PNG); no compression applied; fire-and-forget async upload with ghost notes, real-time progress, cancel, and retry
- **Media Display**: Shimmer placeholders with correct dimensions, full-screen image lightbox with gallery navigation, video lightbox with player controls, animated GIF support
- **Audio Playback**: Inline audio player for audio attachments — HTML Audio API on web, ExoPlayer on Android; scrubber, preview + download buttons
- **Media Panel**: Right sidebar with 5 tabs (Images/Videos/Documents/Links/Reminders), responsive layout
- **Archive System**: Archive for soft-deleted notes, channel archiving with restore, configurable retention auto-purge (Never/30/60/90 days)
- **Selection Mode**: Long-press (mobile) or right-click → Select (desktop) to multi-select notes; Navbar transforms to show count + bulk archive action; Escape key cancels
- **Settings/Archive as detail pages**: Fade-animated (220ms) full-width view with back button; sidebar and media panel hidden in this mode
- **Offline Mode**: Local-first reads from SQLite cache (Drift), dirty-flag tracking replaces mutation queue, pull-then-push sync on reconnect, navbar sync indicator; persistent on all platforms — native uses file SQLite, web uses WASM SQLite + IndexedDB (see `docs/Sync.md`)
- **GIF Search**: Klipy API integration for GIF search and send; bottom sheet picker with trending, search, pagination; GIFs downloaded from CDN and uploaded to server as self-hosted media (see `docs/GIF.md`)
- **Search**: Hybrid FTS + trigram search across all notes; ranked results with highlighted snippets, jump-to-context; untracked `note_search` table pattern to work around Serverpod schema validator (see `docs/Search.md`)
- **Notifications**: Test notification harness in Settings — platform-conditional (Web Notifications API / flutter_local_notifications), lazy-initialized, 10s delay for backgrounding verification (see `docs/Notification.md`)
- **Page Watch**: Bell icon on single-URL notes to monitor for content changes; server polls periodically, hashes visible text, push notification on change; auto-disable after 5 failures; ETag/conditional request optimization (see `docs/PageWatch.md`)
- **Reminders**: Schedule notifications on individual notes; one-shot or recurring (Daily/Weekly/Monthly) via RRULE; siren icon indicator, context menu + selection bar creation, zero-polling per-reminder timers on server (priority queue) and client (Web Worker / Android zonedSchedule), three-layer delivery with deduplication, auto-reschedule for recurring, fired-but-unacknowledged delivery on reconnect, MediaPanel Remind tab with repeat indicator (see `docs/Reminder.md`)
- **UI/UX**: Toast notifications, context menus, multi-select, date separators, per-channel drafts, custom PWA icons

## Architecture

### Three-Tier Structure

1. **Server Layer** (`memoka_server/`)
   - Endpoints define the server API in `lib/src/*_endpoint.dart`
   - Protocol models are defined in `.spy.yaml` files (e.g., `lib/src/chat/channel.spy.yaml`)
   - Generated code lives in `lib/src/generated/` and should NEVER be manually edited
   - Server entry point: `lib/server.dart` initializes Serverpod and web routes

2. **Client Layer** (`memoka_client/`)
   - Auto-generated from server code via `serverpod generate`
   - Provides type-safe API to call server endpoints
   - Code in this package is mostly generated; manual edits are rare

3. **Flutter App** (`memoka_flutter/`)
   - Uses `memoka_client` to communicate with the server
   - Client instance initialized in `lib/main.dart` with server URL from `assets/config.json`
   - Riverpod for state management

### Code Generation Workflow

Serverpod uses code generation extensively. When you modify:

- Endpoint methods in `*_endpoint.dart`
- Protocol models in `*.spy.yaml`
- Database table definitions

You MUST run `serverpod generate` from the `memoka_server/` directory to regenerate:

- Protocol classes (`lib/src/generated/protocol.dart`)
- Endpoint dispatchers (`lib/src/generated/endpoints.dart`)
- Client code in `memoka_client/`
- Test helpers

**Never manually edit files in `lib/src/generated/` directories.**

### Database & Services

- PostgreSQL (with pgvector extension) on port 8090 (dev) / 9090 (test)
- Redis on port 8091 (dev) / 9091 (test)
- Managed via Docker Compose (`memoka_server/docker-compose.yaml`)
- Separate containers for development and testing
- Migrations stored in `memoka_server/migrations/` with registry in `migration_registry.txt`

### Data Models

**Channel** (`channels` table): name, emoji, pinned, isSystemChannel, createdAt, updatedAt, sortOrder (kept for compat), position (double, fractional order), archived, archivedAt, version (sync version), deletedAt (tombstone), clientMutationId (offline idempotency)

**Note** (`notes` table): channelId (FK → channels, cascade), content, linkPreview (LinkPreview?), attachments (List\<MediaAttachment\>?), archived, archivedAt, createdAt, updatedAt, version (sync version), deletedAt (tombstone), clientMutationId (offline idempotency)

**MediaAttachment** (`media_attachments` table): noteId (FK → notes, cascade), channelId (FK → channels, cascade), filePath, originalFilename, mimeType, fileSize, width, height, duration, thumbnailPath, compressed, animated, contentHash, uploadedAt

**LinkPreview** (non-table): url, title, description, imageUrl, faviconUrl, fetchedAt

**ChatEvent** (non-table): type, note, noteId, channelId, channel

**ArchiveItem** (non-table): type, note, channel, archivedAt

**Sync protocol models** (non-table): SyncChange, SyncPullResponse, SyncPushResponse, SyncResult — see `docs/Sync.md`

**sync_state** (server-only singleton table): globalVersion (monotonic counter, incremented on every mutation)

**app_settings** (server-only singleton table): archiveRetentionDays (0 = never purge, 30/60/90 = days before auto-purge of archived items)

**note_search** (server-only untracked table): note_id (PK, FK → notes, cascade), search_vector (tsvector). Created at startup by `SearchSetup`, not in any `.spy.yaml` — invisible to Serverpod's schema validator. GIN index on search_vector, trigger-maintained from `notes.content`. See `docs/Search.md`.

**page_watches** (server-only untracked table): noteId (FK → notes, cascade), channelId (FK → channels, cascade), url, contentHash, lastCheckedAt, enabled, consecutiveFailures, lastError, hasUnacknowledgedChange, etag, lastModified, timestamps. Created at startup by `PageWatchSetup`, not in any `.spy.yaml`. See `docs/PageWatch.md`.

**PageWatch** (non-table): noteId, channelId, url, contentHash?, lastCheckedAt?, enabled, consecutiveFailures, lastError?, hasUnacknowledgedChange, createdAt, updatedAt

**reminders** (server-only untracked table): noteId (FK → notes, cascade, UNIQUE), channelId (FK → channels, cascade), scheduledAt, noteContent, fired, createdAt, recurrenceRule, recurrenceEndAt. Created at startup by `ReminderSetup`, not in any `.spy.yaml`. Indexes on scheduledAt (unfired) and fired. See `docs/Reminder.md`.

**Reminder** (non-table): noteId, channelId, scheduledAt, noteContent?, fired, createdAt, recurrenceRule?, recurrenceEndAt?

## Common Commands

### Server Development

From `memoka_server/`:

```bash
# Start database services (REQUIRED before running server)
docker compose up --build --detach

# Install dependencies
dart pub get

# Install Serverpod CLI (one-time setup)
dart pub global activate serverpod_cli 3.3.1

# Regenerate code after changing endpoints or models
serverpod generate

# Run server (starts on default port 8080)
dart bin/main.dart

# Run server with migrations applied
dart bin/main.dart --apply-migrations

# Stop services when done
docker compose stop

# Run tests
dart test

# Stop and remove test containers/volumes
docker compose down -v
```

### Flutter Development

From `memoka_flutter/`:

```bash
# Install dependencies
flutter pub get

# Run the app (ensure server is running first)
flutter run

# Build web app and copy to server's web directory
# (Run from memoka_server directory)
# Note: --wasm flag is not compatible with dart:html usage
cd ../memoka_flutter
flutter build web --dart-define=APP_VERSION=$(git describe --tags --abbrev=0) --base-href /app/ --output ../memoka_server/web/app
perl -0777 -pi -e 's/serviceWorkerSettings:\s*\{[^}]*\}//' ../memoka_server/web/app/flutter_bootstrap.js
```

### Database Seeding

From `memoka_server/`:

```bash
# Seed — 6 channels, 50+ notes each (dogfood testing)
dart run bin/seed.dart
```

Creates 6 purpose-specific channels: General (text), Images, Videos, Documents, Links, Reminders. Each gets 50+ notes (except Reminders which is deferred). No confirmation prompt — runs directly.

Media channels require fixture files in `fixtures/seed/{images,videos,docs}/`. If fewer than 50 files exist, the seed cycles through available files. Links channel fetches live link previews in batches.

**Directory layout:**
- `bin/seed.dart` — dogfood seed (executable)
- `fixtures/seed/images/` — image files for Images channel
- `fixtures/seed/videos/` — video files for Videos channel
- `fixtures/seed/docs/` — document files for Documents channel

### Testing

Integration tests use `withServerpod` test helper from `serverpod_test` package. Tests automatically:

- Start Serverpod in test mode
- Use test database/redis containers (ports 9090/9091)
- Roll back database after each test
- Apply migrations before test suite runs

Example test structure:

```dart
withServerpod('Given Chat endpoint', (sessionBuilder, endpoints) {
  test('when calling `getChannels` then should return channels', () async {
    final channels = await endpoints.chat.getChannels(sessionBuilder);
    expect(channels, isA<List<Channel>>());
  });
});
```

## Development Workflow

1. **Adding a new endpoint**:
   - Create `*_endpoint.dart` file in `memoka_server/lib/src/`
   - Define class extending `Endpoint` with methods
   - Run `serverpod generate` to update generated code
   - Access via `client.<endpointName>.<method>()` in Flutter

2. **Adding a data model**:
   - Create `*.spy.yaml` file defining the class and fields
   - Add `table: <name>` if it represents a database table
   - Run `serverpod generate` to create model classes
   - Create database migration if needed

3. **Creating a migration**:
   - Modify table definitions in `.spy.yaml` files
   - Run `serverpod create-migration` to generate migration files
   - Migrations are stored in timestamped directories under `migrations/`
   - Apply with `--apply-migrations` flag or manually

## Project-Specific Details

### Environment Variables

CI/CD uses these environment variables (see `.github/workflows/tests.yml`):

- `SERVERPOD_PASSWORD_database`: PostgreSQL password for tests
- `SERVERPOD_PASSWORD_redis`: Redis password for tests

### Web Routes

Server serves:

- Static files from `web/static/` at root
- Flutter web app from `web/app/` at `/app` (if built)
- App config at `/app/assets/assets/config.json` (dynamically generated from server config)
- Media files at `/media` via `CorsMediaRoute` (adds `Access-Control-Allow-Origin: *` so Flutter web dev server can load audio/media cross-origin)
- File uploads at `POST /media/upload` via `MediaUploadRoute` — streams multipart body directly to disk (no in-memory buffering), processes image/video, creates DB record, broadcasts WebSocket event
- Healthcheck at `/healthcheck` via `HealthcheckRoute` — returns 200 OK with CORS headers, used by Flutter connectivity probe

### Current Endpoints

- `chat`: Channel and note management with real-time WebSocket updates
  - Channels: create, update, delete, list, pin/unpin, archive/restore
  - Notes: create, update, delete, list with pagination, archive/restore
  - Archive: getArchiveItems, getArchivedChannelNoteCount
  - Link previews: automatic URL detection and metadata fetching (see `docs/components/Preview.md`)
  - Real-time streaming: WebSocket events for live updates
- `sync`: State-based reconciliation sync
  - `syncPull(sinceVersion)` — returns all entities changed since version N
  - `syncPush(changes)` — applies dirty local entities with version checks (partial apply)
- `settings`: Application settings management
  - `getSettings()` — returns current AppSettings (archiveRetentionDays)
  - `updateSettings(settings)` — updates AppSettings singleton
- `search`: Full-text and trigram search across notes
  - `searchNotes(query, {limit})` — hybrid FTS + trigram, returns ranked `SearchResult` list with snippets
  - `getNotesAroundId(channelId, noteId, {limit})` — loads notes surrounding a target for jump-to-context
- `pageWatch`: URL change monitoring
  - `createWatch(noteId)` — creates/re-enables a watch for a single-URL note
  - `deleteWatch(noteId)` — removes a watch
  - `getWatch(noteId)` — returns watch state or null
  - `acknowledgeChange(noteId)` — clears unacknowledged change flag
- `reminder`: Note reminder scheduling and delivery
  - `createReminder(noteId, scheduledAt, {recurrenceRule?, recurrenceEndAt?})` — creates/upserts a reminder (one-shot or recurring)
  - `deleteReminder(noteId)` — deletes a reminder
  - `getReminder(noteId)` — returns reminder or null
  - `updateReminder(noteId, scheduledAt, {recurrenceRule?, recurrenceEndAt?})` — updates scheduled time + recurrence
  - `getReminders(channelId)` — returns all reminders for a channel (MediaPanel)
  - `getFiredReminders()` — returns all fired reminders (reconnect delivery)
  - `getActiveReminders()` — returns all unfired reminders (client-side timer seeding)
  - `acknowledgeReminder(noteId)` — deletes the fired reminder row
- File uploads: HTTP route `POST /media/upload` (not RPC) — streams multipart body directly to disk, no in-memory buffering

## Git Workflow Policy

**CRITICAL: Git commit and push behavior**

- **NEVER commit or push changes unless explicitly requested** in the current instruction
- If a user instruction includes "commit" or "push", only perform git operations for that specific instruction
- **Permission does NOT carry over** to subsequent instructions - each new instruction requires explicit permission
- Always make changes and let the user review before committing
- When git operations are requested, follow the standard commit message format with Co-Authored-By tag

Examples:
- "Fix the bug and commit the changes" → Commit and push allowed for this instruction only
- "Update the config" → Make changes but DO NOT commit/push
- "Add feature X" (next instruction after previous commit request) → Make changes but DO NOT commit/push
- Never assume commit permission from previous instructions

## Important Conventions

- Endpoint class names must end with `Endpoint` (e.g., `ChatEndpoint`)
- When accessed from client, the `Endpoint` suffix is removed (e.g., `client.chat`)
- All server-side code generation is triggered by `serverpod generate`
- Docker services MUST be running before starting the server
- Test environment uses separate database/redis instances to avoid conflicts

## Components

Component specifications document individual Flutter widgets with their styling,
interactions, state management, and integration details.

- **ChannelList**: `docs/components/ChannelList.md`
- **Input** (NoteInput): `docs/components/Input.md`
- **Navbar**: `docs/components/Navbar.md`
- **Archive**: `docs/components/Archive.md`
- **NewChannelModal**: `docs/components/NewChannelModal.md`
- **Icon**: `docs/components/Icon.md`
- **MediaPanel**: `docs/components/MediaPanel.md`
- **Note** (NoteItem): `docs/components/Note.md`
- **Preview** (link previews): `docs/components/Preview.md`
- **Audio** (audio player): `docs/components/Audio.md`
- **Button** (AppTextButton): `docs/components/Button.md`
- **Search** (search bar, results, jump-to): `docs/components/Search.md`
- **UploadDialog** (upload confirmation): `docs/components/UploadDialog.md`

## Architecture Guides

- **Sync Architecture**: `docs/Sync.md` — State-based reconciliation, versioned entities, pull-then-push sync, dirty tracking, tombstones, connectivity detection, 2s sync cooldown, per-provider cache refresh
- **GIF Integration**: `docs/GIF.md` — Klipy API search/featured, download-then-upload flow, build-time API key configuration
- **Archive Retention**: `docs/ArchiveRetention.md` — Configurable auto-purge (Never/30/60/90 days), PurgeHelper shared tombstone logic, hourly purge scheduling
- **Search**: `docs/Search.md` — Hybrid FTS + trigram search, untracked `note_search` table pattern, Serverpod schema validator constraints and workarounds
- **Shortcuts**: `docs/Shortcuts.md` — Keyboard shortcuts (Ctrl+F, Ctrl+K, Escape, arrow keys)
- **Notifications**: `docs/Notification.md` — Test notification harness, platform-conditional, lazy init
- **Page Watch**: `docs/PageWatch.md` — URL change monitoring, untracked `page_watches` table, periodic polling with ETag optimization, bell icon states, notification integration
- **Reminders**: `docs/Reminder.md` — Note reminder scheduling, untracked `reminders` table, zero-polling per-reminder timers (server priority queue + client Web Worker/zonedSchedule), three-layer delivery with deduplication, fired-on-reconnect delivery, siren icon, MediaPanel tab
- **Seed**: `docs/Seed.md` — Dogfood seed script, 6 channels (text/media/links/reminders), fixture directories, media cycling, batch link preview fetching

## Platform Guides

- **Android**: `docs/Android.md` — Build, signing, server setup, share intent, camera
