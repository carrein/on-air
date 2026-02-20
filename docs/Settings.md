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

### Chat Background

Horizontal scrolling grid of background thumbnails (120px wide cards, 180px tall row).

- 14 themed patterns: flower, food, gift, leaves, light, memphis, morocco, pentagon, sakura, sun, terrazzo, tree, wheat, wormz
- Selected background has a `#CE2161` checkmark overlay in the top-right corner
- Tapping a card calls `backgroundPreferenceProvider.notifier.setBackground(background)`
- Background is applied immediately to the chat view and persisted via `BackgroundProvider`

---

## State

| Provider | Type | Usage |
|----------|------|-------|
| `backgroundPreferenceProvider` | `BackgroundType` | Currently selected chat background |
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
| Background | Current chat background pattern (tiled via `ImageRepeat.repeat`) |
| Section header font size | 12px bold, `#00171F` |
| List tile font size | 14px |
| Subtitle / muted text | `#00171F` at 50% opacity |
| Change button text | `#CE2161` |
| Background card size | 120px wide × 180px tall |
| Selected indicator | `#CE2161` checkmark (PhosphorIcons) |

---

## Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/settings_view.dart` | Widget implementation |
| `lib/screens/server_setup_screen.dart` | Server URL editing screen |
| `lib/providers/background_provider.dart` | Background preference state |
| `lib/providers/settings_view_provider.dart` | Settings visibility state |
| `docs/components/Navbar.md` | Navbar detail mode (back button, title) |
| `docs/DesignSystem.md` | Color tokens |
