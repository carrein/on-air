# Seed Script

Dogfood seed for testing all features. Replaces the old demo/load-test seed.

## Usage

From `memoka_server/`:

```bash
dart run bin/seed.dart
```

No confirmation prompt. Wipes all data (channels, notes, media, sync state) and recreates from scratch.

## Channels

| # | Channel | Emoji | Content |
|---|---------|-------|---------|
| 1 | General | `chatCircle` | 55 text-only notes with varied markdown |
| 2 | Images | `image` | 50 notes with image attachments |
| 3 | Videos | `videoCamera` | 50 notes with video attachments |
| 4 | Documents | `file` | 50 notes with document attachments |
| 5 | Links | `link` | 55 notes with curated URLs + fetched link previews |
| 6 | Reminders | `bellRinging` | Empty (deferred) |

## Media Fixtures

Media channels read files from fixture directories:

- `memoka_server/fixtures/seed/images/` -- image files (jpg, png, gif, webp, tiff)
- `memoka_server/fixtures/seed/videos/` -- video files (mp4, mov, webm, avi, wmv, ogg)
- `memoka_server/fixtures/seed/docs/` -- documents, audio, and misc files (pdf, docx, ppt, xlsx, csv, json, xml, html, wav, mp3, ogg, zip, odt, rtf, odp, ods, svg, ico)

Files follow a `{format}_{size}.{ext}` naming convention (e.g., `jpg_2500kb.jpg`, `mp4_18mb.mp4`).

The seed iterates all files in each directory. No hardcoded filenames -- any file placed there becomes a note. If fewer than 50 files exist, the seed cycles through available files (e.g., 5 images each attached to 10 notes). If the directory is empty or missing, that channel is skipped.

## Implementation Details

### Cleanup

1. Delete all files in `data/media/`
2. `TRUNCATE TABLE channels CASCADE` (cascades to notes, media_attachments, note_search, page_watches, reminders)
3. Reset `sync_state.globalVersion` to 0

### Channel Creation

All 6 channels created via direct DB insert inside transactions with `incrementGlobalVersion`. Each gets a `position: double` (0.0 through 5.0) for fractional ordering.

### General Channel (Text)

55 inline text constants covering: short notes, bold/italic, headers, bullet lists, numbered lists, code blocks (Dart, SQL, Python, JavaScript, YAML), inline code, blockquotes, multi-paragraph, mixed formatting, task lists, long technical notes.

### Media Channels (Images/Videos/Documents)

Same pattern for all three:

1. Read all files from the fixture directory, sorted by path
2. For each note (cycling if < 50 files):
   - Read file bytes
   - Determine MIME type via `lookupMimeType()` (from `mime` package)
   - Compute content hash (SHA-256, 8-char prefix)
   - Parse dimensions (PNG IHDR, JPEG SOF0/SOF2, WebP VP8/VP8L, GIF header, TIFF IFD tags; null for others)
   - Copy file to `data/media/channels/{channelId}/{uuid}{ext}`
   - Create Note + MediaAttachment rows in a single transaction with version increment

No thumbnail generation in the seed (thumbnails are a server-side processing concern at upload time). Empty string for note content.

### Links Channel

1. Create all 55 notes with direct DB insert (each a single URL as content)
2. Batch-fetch link previews using `LinkPreviewService.fetchPreview()` -- 5 concurrent fetches via `Future.wait`
3. Update each note with the fetched `LinkPreview` in a versioned transaction
4. Progress printed to stdout during fetch

Uses curated stable URLs: Wikipedia articles, GitHub repos, MDN docs, Dart/Flutter docs, infrastructure docs, language homepages, specs/standards, dev tools. All HTTPS with good OpenGraph metadata.

### Reminders Channel

Created empty. Content deferred for separate implementation.

### Timestamps

Notes within each channel are spaced 6 hours apart (`minutesAgo = (count - i) * 360`), spanning roughly 2 weeks of simulated history.

## Verification

1. Run seed: `dart run bin/seed.dart` from `memoka_server/`
2. Start server: `dart bin/main.dart --apply-migrations`
3. Open app and verify:
   - 6 channels exist in sidebar
   - General: scroll through 55 text notes with varied formatting
   - Images/Videos/Documents: media attachments render (requires fixture files)
   - Links: link previews displayed
   - Reminders: empty channel present
