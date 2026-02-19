u/docs/Android.md
u/docs/Emulator.md
u/docs/channel.md
u/docs/link.md
u/docs/media.md
u/docs/overview.md
u/docs/plan.md
u/docs/security.md
u/docs/ux.md
u/docs/components/Sidebar.md
u/docs/components/InputBar.md
u/docs/components/TopBar.md
u/docs/components/ArchiveCrate.md
u/docs/components/NewChannelModal.md
u/docs/components/Tooltip.md
u/docs/components/Icon.md
u/docs/components/MediaSidebar.md

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Memoka is a real-time chat-style notes application for organizing thoughts in topical channels. Built with Serverpod (v3.2.3), consisting of three main packages:

- **memoka_server**: Serverpod backend server (Dart)
- **memoka_client**: Generated client library (Dart)
- **memoka_flutter**: Flutter mobile/web application

Serverpod is a backend framework for Dart/Flutter that handles database connections, endpoints, and code generation.

## Features

- **Channels**: Create, update, delete, pin/unpin, emoji identifiers, drag-to-reorder, archive/restore
- **Notes**: Create, update, delete with cursor-based pagination, archive/restore
- **Real-time**: WebSocket streaming via MessageCentral for live updates
- **Link Previews**: Automatic URL detection with OpenGraph/Twitter Card metadata
- **Media Uploads**: Image/document upload with drag-and-drop, paste, multi-file batch upload, compression, thumbnail generation, EXIF stripping
- **Media Display**: Shimmer placeholders with correct dimensions, full-screen image lightbox with gallery navigation, video lightbox with player controls, animated GIF support, compressed badge
- **Media Sidebar**: Right sidebar with 4 tabs (Images/Videos/Documents/Links), responsive layout
- **Archive System**: Archive Crate for soft-deleted notes, channel archiving with restore
- **UI/UX**: Toast notifications, context menus, multi-select, date separators, per-channel drafts, chat background picker, custom PWA icons

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

**Channel** (`channels` table): name, emoji, pinned, isSystemChannel, createdAt, updatedAt, sortOrder, archived, archivedAt

**Note** (`notes` table): channelId (FK → channels, cascade), content, linkPreview (LinkPreview?), attachments (List\<MediaAttachment\>?), archived, archivedAt, createdAt, updatedAt

**MediaAttachment** (`media_attachments` table): noteId (FK → notes, cascade), channelId (FK → channels, cascade), filePath, originalFilename, mimeType, fileSize, width, height, duration, thumbnailPath, compressed, animated, contentHash, uploadedAt

**LinkPreview** (non-table): url, title, description, imageUrl, faviconUrl, fetchedAt

**ChatEvent** (non-table): type, note, noteId, channelId, channel

**ArchiveItem** (non-table): type, note, channel, archivedAt

## Common Commands

### Server Development

From `memoka_server/`:

```bash
# Start database services (REQUIRED before running server)
docker compose up --build --detach

# Install dependencies
dart pub get

# Install Serverpod CLI (one-time setup)
dart pub global activate serverpod_cli 3.2.3

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
flutter build web --base-href /app/ --output ../memoka_server/web/app
```

### Database Seeding

From `memoka_server/`:

```bash
# Demo seed — 3 channels with sample text, links, and images
dart run bin/seed_demo.dart

# Full seed — 26 channels, 500+ notes (load testing)
dart run bin/seed.dart
```

Both scripts prompt for confirmation before wiping all data (channels, notes, media files).

Demo seed assets live in `memoka_server/fixtures/demo/` (6 splash art PNGs). The seed copies them into `data/media/channels/{id}/` with UUID filenames and creates matching `MediaAttachment` records.

**Directory layout:**
- `bin/seed.dart` — load-test seed (executable)
- `bin/seed_demo.dart` — demo seed (executable)
- `fixtures/demo/` — image assets consumed by demo seed

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

### Current Endpoints

- `chat`: Channel and note management with real-time WebSocket updates
  - Channels: create, update, delete, list, pin/unpin, archive/restore
  - Notes: create, update, delete, list with pagination, archive/restore
  - Archive: getArchiveItems, getArchivedChannelNoteCount
  - Link previews: automatic URL detection and metadata fetching (see `docs/link.md`)
  - Real-time streaming: WebSocket events for live updates
- `media`: Media upload and management
  - uploadMediaAndCreateNote, uploadMedia, deleteAttachment

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

- **Sidebar**: `docs/components/Sidebar.md`
- **InputBar**: `docs/components/InputBar.md`
- **TopBar**: `docs/components/TopBar.md`
- **ArchiveCrate**: `docs/components/ArchiveCrate.md`
- **NewChannelModal**: `docs/components/NewChannelModal.md`
- **Tooltip**: `docs/components/Tooltip.md`
- **Icon**: `docs/components/Icon.md`
- **MediaSidebar**: `docs/components/MediaSidebar.md`

## Platform Guides

- **Android**: `docs/Android.md` — Build, signing, server setup, share intent, camera
