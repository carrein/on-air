# Audio Attachment Player

Inline audio playback for audio file attachments within note cards.

---

## Scope

- **Platforms**: Web + Android
- **Trigger**: Explicit play only (no auto-play)
- **Concurrency**: Exclusive — playing one track pauses any other
- **Scrubber**: Plain progress bar (Slider)
- **On complete**: Reset to start, show play button
- **Lifecycle**: Stop on navigation (player disposes with the widget)

---

## Visual Design

Replaces the `DocumentAttachmentWidget` row for audio files. Renders inline inside the existing note card.

```
[▶]  ━━━━●━━━━━━━━━━━━━━━  1:23 / 3:45   [↓]
```

| Element | Detail |
|---|---|
| Play/pause button | `IconButtonStyled` — `PhosphorIcons.play()` / `PhosphorIcons.pause()` |
| Filename | Bold, `14px`, `#00171F`, same as document widget |
| Scrubber | Flutter `Slider`, `#CE2161` active track, thumb, no label |
| Time display | `elapsed / duration`, `12px`, `#00171F` @ 50% opacity |
| Download button | `IconButtonStyled(downloadSimple)` — same as document widget |

Layout (single row):
```
[▶/⏸]  [filename + scrubber + time]  [↓]
```

The filename sits above the scrubber row, file size replaced by `elapsed / duration` once loaded, showing `--:-- / --:--` before duration is known.

### States

| State | Play icon | Scrubber | Time |
|---|---|---|---|
| Idle (not loaded) | `play` (dimmed) | inactive | `--:-- / --:--` |
| Ready | `play` | at 0 | `0:00 / 3:45` |
| Playing | `pause` | advancing | `1:23 / 3:45` |
| Paused | `play` | at position | `1:23 / 3:45` |
| Completed | `play` | reset to 0 | `0:00 / 3:45` |
| Error | `play` (disabled) | inactive | error text |

---

## Package

**`audioplayers: ^6.x`** — chosen over `just_audio` for:
- Single package covers web + Android with no platform-specific extras
- Simpler API for URL streaming
- Smaller setup overhead

---

## Implementation Plan

### 1. `pubspec.yaml`
Add `audioplayers: ^6.x` dependency.

### 2. Global audio coordinator — `providers/audio_player_provider.dart`
```dart
// Tracks the currently playing widget's ID so we can pause it
// when a new one starts.
final activeAudioIdProvider = StateProvider<String?>((ref) => null);
```
- Each `AudioAttachmentWidget` has a unique ID (its `attachment.filePath`)
- When play is tapped, widget sets itself as active; any widget watching sees it's no longer active and pauses

### 3. `widgets/audio_attachment_widget.dart` (new)
`StatefulWidget` + `ConsumerStatefulWidget`.

**State:**
```dart
late AudioPlayer _player;
PlayerState _playerState = PlayerState.stopped;
Duration _position = Duration.zero;
Duration _duration = Duration.zero;
bool _loading = false;
```

**Lifecycle:**
- `initState`: create `AudioPlayer`, attach listeners for position/duration/state
- `dispose`: `_player.dispose()`
- Watch `activeAudioIdProvider` — if active ID changes away from self, call `_player.pause()`

**Play/pause logic:**
```dart
void _togglePlay() async {
  if (_playerState == PlayerState.playing) {
    await _player.pause();
  } else {
    ref.read(activeAudioIdProvider.notifier).state = attachment.filePath;
    if (_playerState == PlayerState.completed || _position == Duration.zero) {
      await _player.play(UrlSource(audioUrl));
    } else {
      await _player.resume();
    }
  }
}
```

**On complete:** listen for `PlayerState.completed` → `_player.seek(Duration.zero)`, reset state to stopped.

### 4. `utils/file_utils.dart`
Add `isAudio(String ext)` helper:
```dart
static bool isAudio(String ext) =>
    ['mp3', 'wav', 'flac', 'ogg', 'aac', 'm4a', 'opus'].contains(ext.toLowerCase());
```

### 5. `widgets/media_attachment_widget.dart`
In the attachment routing logic, add audio check before falling through to `DocumentAttachmentWidget`:
```dart
if (FileUtils.isAudio(extension)) {
  return AudioAttachmentWidget(attachment: attachment, serverUrl: serverUrl);
}
```

### 6. `widgets/document_attachment_widget.dart`
No changes needed — audio files are intercepted before reaching it.

---

## File Changes Summary

| File | Change |
|---|---|
| `pubspec.yaml` | Add `audioplayers` |
| `providers/audio_player_provider.dart` | New — active audio ID state |
| `widgets/audio_attachment_widget.dart` | New — player widget |
| `utils/file_utils.dart` | Add `isAudio()` helper |
| `widgets/media_attachment_widget.dart` | Route audio to new widget |

---

## Out of Scope

- Waveform visualisation
- iOS / desktop support (can be added later — `audioplayers` already supports both)
- Background playback across channel navigation
- Playback speed control
- Sleep timer
