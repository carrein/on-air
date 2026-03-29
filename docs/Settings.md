# Settings

Settings is a detail-mode page accessible from the Navbar. It displays in the main content area while the sidebar and media panel are hidden.

**Source**: `memoka_flutter/lib/widgets/settings_view.dart`

---

## Overview

`SettingsView` is a `ConsumerStatefulWidget` that renders the settings content area. It is shown when `settingsViewProvider` is active. The Navbar shows a back button + "Settings" title in this mode (see `docs/components/Navbar.md`).

---

## Sections

### Server

Displayed on all platforms. Allows viewing and editing the server URL inline.

- **Server URL**: `StyledTextField` (300px wide) showing the current server URL, editable inline
- **Save button**: `AppTextButton` (secondary variant), enabled only when URL has changed; shows loading state during connection test
- **Connection test**: On save, normalizes URL (adds `http://` prefix and `/` suffix if missing), calls `setServerUrl()`, then tests with `getChannels().timeout(10s)`. Shows success/error toast.

### Notifications

- **Test Notification**: `AppTextButton` (secondary variant) fires a test notification after 10 seconds (see `docs/Notification.md`)

### Jobs

Background maintenance tasks with live progress tracking.

- **Regenerate Thumbnails**: Triggers server-side background job to regenerate thumbnails for all image/video attachments
  - **Idle**: Shows "Run" `AppTextButton` (secondary variant)
  - **Running**: Shows "X / Y" progress text (brand blue `#3450A3`, 13px, w600) in place of button
  - **Completion**: Toast notification on transition from running to done — success toast with count, error toast if all failed, info toast if no eligible items
  - SVG files (`image/svg+xml`) are excluded from regeneration
  - Only one job runs at a time; starting while running is a no-op

### About

- **Version**: Compile-time `--dart-define=APP_VERSION` value, defaults to "DEV". Displayed as trailing text (brand blue `#3450A3`, 13px, w600).

---

## Components

### SettingItem

Reusable settings row component extracted from repeated ListTile patterns.

**Source**: `memoka_flutter/lib/widgets/setting_item.dart`

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `title` | `String` | Yes | Setting name |
| `icon` | `IconData?` | No | Phosphor icon for leading position |
| `subtitle` | `String?` | No | Secondary text below title |
| `trailing` | `Widget?` | No | Action widget (button, text, input) |

**Styling:**
| Element | Value |
|---------|-------|
| Content padding | H: 16px, V: 8px |
| Icon | PhosphorIcon, 24px, `#00171F` |
| Title font | 15px |
| Subtitle font | 12px, `#00171F` at 60% opacity |

### StyledTextField

Base text field component with consistent Memoka styling, shared between search and settings.

**Source**: `memoka_flutter/lib/widgets/styled_text_field.dart`

| Feature | Value |
|---------|-------|
| Font | Space Grotesk, 14px |
| Background | `#FFFDF6` (cream) |
| Border | 1px `#3450A3` (accent blue), zero radius |
| Border animation | MouseRegion + AnimatedContainer (200ms ease-in-out); border fades between 30% and 100% opacity on hover/focus |
| `borderless` mode | Removes all borders (for use inside a custom border container like `StyledSearchField`) |
| `contentPadding` | Defaults to `EdgeInsets.symmetric(vertical: 10)` |

---

## State

| Provider | Type | Usage |
|----------|------|-------|
| `settingsViewProvider` | `bool` | Whether settings is shown (controls detail mode) |
| `thumbnailRegenProvider` | `ThumbnailRegenProgress?` | Thumbnail regen job state (keepAlive) |

### ThumbnailRegenProvider

`@Riverpod(keepAlive: true)` notifier that tracks the thumbnail regeneration job.

- **On build**: Checks if a job is already running on the server (handles app restarts mid-job)
- **`start()`**: Calls `startThumbnailRegen` RPC, begins 1-second polling via `Timer.periodic`
- **Polling**: Calls `getRegenProgress` RPC, updates state, stops timer when `!isRunning`
- **Error handling**: Network errors during polling are silently ignored (keeps polling)

---

## Detail Mode Behavior

When settings is open, the app is in **detail mode**:

- Sidebar (`ChannelList`) is hidden
- Media panel (`MediaPanel`) is hidden
- NoteInput is hidden
- Content area expands to full width
- Navbar shows back button + "Settings" title
- Transition uses 220ms `FadeTransition` with key `'settings'`

Closing settings (back button tap) sets `settingsViewProvider` to false, restoring the normal channel view.

---

## Styling

| Element | Value |
|---------|-------|
| Background | Solid `#FFFDF6` |
| Section header font size | 12px bold, `#00171F` |
| Setting item title font size | 15px |
| Subtitle / muted text | `#00171F` at 60% opacity |
| Action text (version, progress) | 13px, `#3450A3`, w600 |
| Server URL field width | 300px |

---

## Server-Side

### ThumbnailRegenService

**Source**: `memoka_server/lib/src/media/thumbnail_regen_service.dart`

Background service for regenerating thumbnails. Tracks state in `ThumbnailRegenJob` singleton (static fields, no locking needed — Dart is single-threaded).

- **`startBackground(session)`**: Creates independent background session via `session.serverpod.createSession()`, runs in `unawaited` future
- **`countEligible(session)`**: Counts eligible attachments (excludes SVGs and deleted notes)
- **`regenerateAll(session)`**: Foreground variant for CLI usage
- **ffmpeg**: Generates 1200px lossless WebP thumbnails; skips missing source files

### CLI Script

**Source**: `memoka_server/bin/regenerate_thumbnails.dart`

Standalone CLI for thumbnail regeneration. Does not require the server to be running (only database).

```bash
cd memoka_server
dart run bin/regenerate_thumbnails.dart
```

### Settings Endpoint

| Method | Returns | Description |
|--------|---------|-------------|
| `startThumbnailRegen` | `int` (total count) | Starts background job, returns immediately |
| `getRegenProgress` | `ThumbnailRegenProgress` | Returns current job state |

---

## Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/settings_view.dart` | Widget implementation |
| `lib/widgets/setting_item.dart` | Reusable settings row component |
| `lib/widgets/styled_text_field.dart` | Base text field component |
| `lib/providers/thumbnail_regen_provider.dart` | Client-side regen job state |
| `lib/providers/settings_view_provider.dart` | Settings visibility state |
| `memoka_server/lib/src/settings/settings_endpoint.dart` | Server endpoint |
| `memoka_server/lib/src/media/thumbnail_regen_service.dart` | Background regen service |
| `memoka_server/bin/regenerate_thumbnails.dart` | CLI regen script |
| `docs/components/Navbar.md` | Navbar detail mode (back button, title) |
| `docs/DesignSystem.md` | Color tokens |
