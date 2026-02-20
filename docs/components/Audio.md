# Audio Attachment Player

Inline audio playback for audio file attachments within note cards.

---

## Scope

- **Platforms**: Web + Android
- **Trigger**: Explicit play only (no auto-play)
- **Concurrency**: Exclusive — playing one track pauses any other
- **Scrubber**: Flutter `Slider` progress bar
- **On complete**: Reset to start, show play button
- **Lifecycle**: Stop on navigation (player disposes with the widget)

---

## Visual Design

Renders inline inside the existing note card, sharing the same layout pattern as `DocumentAttachmentWidget`.

```
[🎵]  filename.mp3
      [▶] [━━━━●━━━━━━━━━━━━━] 1:23 / 3:45  [👁] [↓]
```

| Element | Detail |
|---|---|
| File icon | `PhosphorIcons.fileAudio()` — 32px, `#00171F`, left-aligned |
| Filename | Bold, `14px`, `#00171F`, above controls row |
| Play/pause | `IconButtonStyled` — `PhosphorIcons.play()` / `PhosphorIcons.pause()`, 22px |
| Scrubber | Flutter `Slider`, `#CE2161` active track + thumb |
| Time display | `elapsed / duration`, `11px`, `#00171F` @ 50% opacity; `--:-- / --:--` before duration loads |
| Preview button | `IconButtonStyled(handEye)` — opens file URL in browser/external app, 20px |
| Download button | `IconButtonStyled(downloadSimple)` — triggers actual file download, 20px |

Layout:

```
Row:
  [fileAudio 32px]  12px  Expanded:
                            Column:
                              [filename bold 14px]
                              8px
                              Row: [▶/⏸] [Slider Expanded] 6px [time] 16px [👁] 4px [↓]
```

Spacing: 8px between filename and controls row, 16px between time and preview button, 4px between preview and download.

### States

| State | Play icon | Scrubber | Time |
|---|---|---|---|
| Idle / not yet played | `play` | inactive | `--:-- / --:--` |
| Ready (duration loaded) | `play` | at 0 | `0:00 / 3:45` |
| Playing | `pause` | advancing | `1:23 / 3:45` |
| Paused | `play` | at position | `1:23 / 3:45` |
| Completed | `play` | reset to 0 | `0:00 / 3:45` |
| Error | `play` | inactive | red error text above filename |

---

## Implementation

### Platform split

`audioplayers` does not register a web plugin channel on this project's setup. The widget uses a platform-conditional implementation:

| Platform | Backend | API |
|---|---|---|
| Web (`kIsWeb`) | `universal_html` `AudioElement` | Native browser HTML Audio API |
| Android | `audioplayers` + ExoPlayer | `AudioPlayer.play(UrlSource(...))` / `resume()` / `pause()` |

```dart
if (kIsWeb) {
  _webAudio = html.AudioElement()
    ..src = _audioUrl
    ..preload = 'metadata';   // loads duration without full download
} else {
  _mobilePlayer = AudioPlayer();
}
```

### Web listeners

| Event | Action |
|---|---|
| `onPlay` | `_isPlaying = true` |
| `onPause` | `_isPlaying = false` |
| `onTimeUpdate` | update `_position` (skipped while `_seeking`) |
| `onDurationChange` | update `_duration` |
| `onEnded` | `_isPlaying = false`, reset `currentTime = 0`, `_position = zero` |

### Android listeners

| Stream | Action |
|---|---|
| `onPlayerStateChanged` | update `_isPlaying`; on `completed` → seek to zero |
| `onPositionChanged` | update `_position` (skipped while `_seeking`) |
| `onDurationChanged` | update `_duration` |

### Preview vs Download

- **Preview** (`handEye`): `launchUrl(uri, mode: LaunchMode.externalApplication)` — opens in browser/OS viewer
- **Download** (`downloadSimple`):
  - Web: `html.AnchorElement()..href = url..setAttribute('download', filename)..click()` — browser native download
  - Mobile: `launchUrl(uri, mode: LaunchMode.externalApplication)`

### Exclusive playback

```dart
// On play:
ref.read(activeAudioIdProvider.notifier).state = _audioId;  // _audioId = attachment.filePath

// In build:
ref.listen<String?>(activeAudioIdProvider, (prev, next) {
  if (next != _audioId && _isPlaying) _pause();
});
```

### Error handling

`_togglePlay` is wrapped in `try/catch`. Any exception sets `_error` which renders as a small red text above the filename, replacing silent failure.

### CORS (server-side)

The Serverpod media server (`port 8082`) needs `Access-Control-Allow-Origin: *` so browsers loading audio cross-origin (Flutter dev server port ≠ 8082) can decode it. See `memoka_server/lib/src/web/routes/cors_media_route.dart`.

---

## Files

| File | Purpose |
|---|---|
| `memoka_flutter/lib/widgets/audio_attachment_widget.dart` | Player widget |
| `memoka_flutter/lib/providers/audio_player_provider.dart` | `activeAudioIdProvider` — exclusive playback coordination |
| `memoka_flutter/lib/widgets/media_attachment_widget.dart` | Routes audio MIME types / extensions to this widget |
| `memoka_flutter/lib/utils/file_utils.dart` | `isAudio()` helper |
| `memoka_server/lib/src/web/routes/cors_media_route.dart` | CORS wrapper for `/media` static route |

---

## Out of Scope

- Waveform visualisation
- iOS / desktop support (can be added later)
- Background playback across channel navigation
- Playback speed control
