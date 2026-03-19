# Settings

Settings is a detail-mode page accessible from the Navbar. It displays in the main content area while the sidebar and media panel are hidden.

**Source**: `memoka_flutter/lib/widgets/settings_view.dart`

---

## Overview

`SettingsView` is a `ConsumerWidget` that renders the settings content area. It is shown when `settingsViewProvider` is active. The Navbar shows a back button + "Settings" title in this mode (see `docs/components/Navbar.md`).

---

## Sections

### Server (native only)

Displayed only on non-web platforms (`!kIsWeb`).

- **Server URL**: Shows the current server URL from `serverUrl` global
- **Change button**: Opens `ServerSetupScreen` (editing mode) via `Navigator.push`

### About

- **Version**: Three-tier resolution: (1) build-time `--dart-define=APP_VERSION=x.y.z` override, (2) `PackageInfo.fromPlatform()` on native, (3) fallback `—`. On web, use `--dart-define` at build time. On Android, `PackageInfo` reads the version from pubspec.yaml baked into the APK. Read-only, no interaction.

---

## State

| Provider | Type | Usage |
|----------|------|-------|
| `settingsViewProvider` | `bool` | Whether settings is shown (controls detail mode) |

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
| List tile font size | 14px |
| Subtitle / muted text | `#00171F` at 50% opacity |
| Change button text | `#CE2161` |

---

## Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/settings_view.dart` | Widget implementation |
| `lib/screens/server_setup_screen.dart` | Server URL editing screen |
| `lib/providers/settings_view_provider.dart` | Settings visibility state |
| `docs/components/Navbar.md` | Navbar detail mode (back button, title) |
| `docs/DesignSystem.md` | Color tokens |
