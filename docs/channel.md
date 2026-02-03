# Channel

## Overview
Channels are topical containers for notes. Each channel contains multiple notes and serves as a focused conversation space.

## Properties

### Display
- **Name**: Text identifier for the channel
- **Emoji**: Display picture using emoji characters (no image upload needed)
  - Rendered in a circular container with transparent background
  - 1px solid border for visual definition
  - 40x40px size
- **Latest Message Preview**: Shows the most recent note content below the channel name in the sidebar
  - Displayed in smaller, gray text
  - Single line with ellipsis overflow
  - Updates in real-time as new notes are posted

### Behavior
- **Sorting**: Channels are sorted by `updatedAt` timestamp (most recently modified first)
  - A new note posted to a channel updates its `updatedAt` time
  - Pinned channels appear first, then unpinned channels
  - Within each group (pinned/unpinned), sorted by most recent activity
- **Pinning**: Channels can be pinned to keep them at the top
  - Pin icon displayed at the end (right side) of the channel item
  - Small blue pin icon (16px)
  - Divider line separates pinned from unpinned channels
- **Editing**: Channel name and emoji can be modified via context menu
- **Deletion**: Channels can be deleted (with cascade delete of all notes)
  - Cannot delete the last remaining channel

## Interactions
- **Selection**: Click/tap to switch to a channel
- **Context Menu**:
  - Desktop: Right-click to open menu
  - Mobile: Long-press to open menu
  - Menu options: Edit, Pin/Unpin, Delete
- **Creation**: "New Channel" button at bottom of channel list

## Implementation Details

### Smart Channel Selection
**File**: `on_air_flutter/lib/providers/current_channel_provider.dart`

Channel selection logic on app startup:
1. Attempts to load last opened channel from SharedPreferences
2. Validates that saved channel still exists in current channel list
3. Falls back to first available channel if saved channel doesn't exist
4. Throws error if no channels available (prompts user to create one)

This ensures users return to their last active channel across app restarts while gracefully handling deleted channels.
