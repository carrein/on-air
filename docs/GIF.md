# GIF Support — Klipy Integration

Covers GIF search and send functionality via the Klipy API (Tenor-compatible).

## Overview

Users tap a GIF icon in the note input bar, search or browse trending GIFs from the Klipy API, tap a result, and the GIF is downloaded from Klipy CDN then uploaded to the Memoka server via the existing media pipeline. After upload, the GIF is a self-hosted `MediaAttachment` with no external CDN dependency.

## Architecture

### Data Flow

```
User taps GIF icon
  → GifPickerSheet opens (modal bottom sheet)
  → Trending GIFs loaded from Klipy featured endpoint
  → User types search query (debounced 300ms)
  → Search results from Klipy search endpoint
  → User taps a GIF thumbnail
  → Sheet closes, returns KlipyGif
  → NoteInput downloads GIF bytes from gif.url (Klipy CDN)
  → Enqueues upload via PendingUploads (compress: false)
  → Ghost note appears in chat (existing PendingNoteWidget)
  → Upload completes via POST /media/upload
  → Server detects animated GIF → preserves original, generates static thumbnail
  → MediaAttachment created with mimeType: image/gif, animated: true
  → Note appears in chat via WebSocket event
```

### Files

| File | Purpose |
|------|---------|
| `lib/services/klipy_service.dart` | HTTP client for Klipy search/featured API |
| `lib/widgets/gif_picker_sheet.dart` | Bottom sheet UI with search, grid, pagination |
| `lib/widgets/note_input.dart` | GIF button + `_pickGif()` download-and-upload flow |

### API

Klipy is a Tenor drop-in replacement. Two endpoints used:

- `GET /v2/search?key=...&q=...&limit=20&media_filter=gif,tinygif&pos=...` — search by query
- `GET /v2/featured?key=...&limit=20&media_filter=gif,tinygif&pos=...` — trending GIFs

Response shape: `{ results: [{ id, title, media_formats: { gif: { url, dims: [w, h] }, tinygif: { url, dims } } }], next: "..." }`

`gif` format is used for the full-size download. `tinygif` is used for grid preview thumbnails (smaller, loads faster).

Pagination uses the `next` token from the response as the `pos` query parameter.

## Configuration

The Klipy API key is provided at build time via `--dart-define`:

```bash
# Web
flutter build web \
  --dart-define=APP_VERSION=$(git describe --tags --abbrev=0) \
  --dart-define=KLIPY_API_KEY=<your-key> \
  --base-href /app/ --output ../memoka_server/web/app

# Android
flutter build apk --dart-define=KLIPY_API_KEY=<your-key>
```

If no `KLIPY_API_KEY` is provided, `KlipyService.isAvailable` returns `false` and the GIF button is hidden. The feature degrades gracefully.

## GIF Display

The existing pipeline handles animated GIFs:

- `MediaAttachmentWidget` routes `image/gif` to `_ImageAttachmentWidget`
- GIFs use `Image.network` (not `CachedNetworkImage`) to preserve animation
- Lightbox gallery includes GIFs in `allImageUrls`
- Server preserves original animation, generates static JPEG thumbnail from frame 1
- `animated: true` set on `MediaAttachment`

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Send flow | Tap GIF → sends immediately | No confirmation needed for GIFs — lightweight content |
| Storage | Download from CDN → upload to server | Self-hosted, no external dependency after upload |
| API key | `--dart-define` at build time | Not committed to repo, graceful degradation |
| Compression | Always `false` | Server already preserves animated GIF originals |
| Grid previews | `tinygif` format for grid, full `gif` for send | Smaller previews load faster in the picker grid |
| Image eviction | `_EvictableNetworkImage` evicts on dispose | Prevents `DomException: AbortError` on web when sheet closes |
