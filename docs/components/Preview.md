# Link Preview Feature

The link preview feature automatically detects URLs in messages and generates rich preview cards with metadata (title, description, image, favicon).

## Architecture

### Hybrid Approach
- **Server-side fetching**: Prevents CORS issues, ensures consistent data across clients
- **Self-hosted images**: OG images and favicons are downloaded to `data/media/previews/` during fetch, served via `/media` with CORS headers — eliminates CanvasKit crashes on web
- **Async processing**: Link previews are fetched after note creation to avoid blocking
- **Real-time updates**: Previews broadcast via WebSocket when ready
- **Client-side indication**: Simple "Link detected" banner while typing

## Data Models

### LinkPreview
Defined in `memoka_server/lib/src/chat/link_preview.spy.yaml`:

```yaml
class: LinkPreview
fields:
  url: String              # The fully qualified URL
  title: String?           # Page title (from OG or <title> tag)
  description: String?     # Description (from OG or meta description)
  imageUrl: String?        # Relative path to self-hosted OG image (e.g. "previews/abc123.jpg")
  faviconUrl: String?      # Relative path to self-hosted favicon (e.g. "previews/favicons/abc123.ico")
  fetchedAt: DateTime      # When the preview was fetched
```

### Note Model Extension
The `Note` model includes an optional `linkPreview` field.

## Server-Side Implementation

### LinkPreviewService
Location: `memoka_server/lib/src/chat/link_preview_service.dart`

**Key methods:**
- `extractFirstUrl(String content)` - Extracts the first fully qualified URL using regex
- `fetchPreview(String url)` - Fetches and parses link metadata via HTTP, downloads OG image and favicon to local disk
- `downloadPreviewImage(url, subDir)` - Public entry point for downloading an external image (used by startup migration)
- `_downloadImage(url, subDir)` - Streams image to `data/media/{subDir}/{urlHash}.{ext}`, 5MB max, SHA-256 URL hash for dedup
- `_extractMeta()` - Extracts OpenGraph and meta tags
- `_makeAbsoluteUrl()` - Converts relative URLs to absolute URLs
- `_extractFavicon()` - Extracts and resolves favicon URL

**Metadata extraction order:**
1. OpenGraph tags (`og:title`, `og:description`, `og:image`)
2. Twitter Card tags (`twitter:title`, `twitter:description`, `twitter:image`)
3. Standard HTML meta tags and `<title>`

### ChatEndpoint Integration
Location: `memoka_server/lib/src/chat/chat_endpoint.dart`

**Flow:**
1. User sends note with URL
2. `createNote()` saves note immediately and broadcasts `noteCreated` event
3. `_fetchLinkPreviewAsync()` runs in background (10-second timeout)
4. Broadcasts `noteLinkPreviewReady` event when ready
5. All connected clients receive update and display preview

## Client-Side Implementation

### Link Preview Card
Location: `memoka_flutter/lib/widgets/link_preview_card.dart`

Displays preview as a Material card with image, title, description, and domain.

### NoteInput Preview
Location: `memoka_flutter/lib/widgets/input_link_preview.dart`

Shows a simple "Link detected" banner above the NoteInput.

### Clickable Links
Links in markdown are made clickable via `MarkdownBody` with `url_launcher`.

## Dependencies

### Server
- `http: ^1.2.2` - HTTP requests for fetching URLs
- `html: ^0.15.4` - HTML parsing for metadata extraction

### Flutter
- `url_launcher: ^6.3.1` - Opening links in external browser
- `cached_network_image: ^3.4.1` - Efficient image loading and caching

## Image Storage

Preview images are downloaded server-side and stored locally:

```
data/media/
└── previews/
    ├── {urlHash}.{ext}        # OG images (SHA-256 hash of source URL, first 16 chars)
    └── favicons/
        └── {urlHash}.{ext}    # Favicons
```

- **Deduplication**: Same source URL always maps to the same file (hash-based naming)
- **Size limit**: 5MB max per image; larger images are skipped (stored as null)
- **Backward compatibility**: Legacy external URLs (starting with `http`) are passed through by `FileUtils.resolvePreviewUrl()` on the client; new previews store relative paths
- **Startup migration**: `_migrateExternalPreviewImages()` in `server.dart` runs once on first startup after deploy, re-downloads existing external preview images to local storage. Marker file (`previews/.migrated`) prevents re-runs.

## Edge Cases

- **Multiple links**: Only first URL is previewed (others remain clickable)
- **Invalid URLs**: Gracefully ignored, note creation succeeds
- **Image failures**: Shows broken image icon
- **CORS**: OG images and favicons are self-hosted via `/media` — no cross-origin issues on web

## Related Files

### Server
- `lib/src/chat/link_preview.spy.yaml`
- `lib/src/chat/note.spy.yaml`
- `lib/src/chat/chat_event.spy.yaml`
- `lib/src/chat/link_preview_service.dart`
- `lib/src/chat/chat_endpoint.dart`

### Flutter
- `lib/widgets/link_preview_card.dart`
- `lib/widgets/input_link_preview.dart`
- `lib/widgets/chat_view.dart`
- `lib/widgets/note_input.dart`
- `lib/providers/notes_provider.dart`
