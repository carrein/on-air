# Media Upload and Storage

Covers media upload, storage, and display for images, videos, and documents in the chat application.

## Overview

### Phase 1 (Completed): Single File Upload
- Paste images from clipboard (Ctrl+V)
- Drag-drop single file support
- Upload dialog with file preview
- Display inline in chat messages
- No captions required
- 1GB file size limit
- Public access (no authentication required)

### Phase 2 (Completed): Multi-File Upload & Documents & Video
- **Multiple file selection** via file picker (`allowMultiple: true`)
- **Drag-drop multiple files** at once
- **Paste multiple files** from clipboard
- **Upload dialog**: `MultiFileUploadDialog` with progress tracking
- **Per-file removal**: Individual remove button for each file
- **Sequential upload**: Files uploaded one-by-one to avoid overwhelming server
- **Progress indicator**: Shows "Uploading X of Y..." with progress bar
- **Document support**: PDF, Text, Word, Excel, Zip file support
- **Video support**: MP4, MOV, WebM, AVI, MKV with thumbnail generation
- **File picker UI**: `FilePicker` with custom file type extensions

### Phase 3 (Completed): Async Upload (OOM Fix + Optimistic UI)

**Root Cause — OOM crash on Android:**
`FilePicker.pickFiles(withData: true)` loads the entire file as a `Uint8List` into memory on selection. Then `base64.encode(finalBytes)` creates a 33% larger copy. A 23.4MB video caused ~55MB peak heap, crashing Android before the dialog even appeared.

**Fix — path-based streaming:**
- `FilePicker.pickFiles(withData: kIsWeb)` — only loads bytes on web where paths are unavailable
- Camera capture uses `photo.path` instead of `photo.readAsBytes()`
- New HTTP multipart route (`POST /media/upload`) streams file directly to a temp file — zero bytes held in memory on server
- Client constructs a `MultipartRequest`, finalizes it into a `StreamedRequest`, and pipes the body through a progress-tracking stream
- All compression removed — neither client-side nor server-side compression is applied. Images and videos are stored as-is. Web-safe image formats (JPEG, PNG, WebP) are stored with no re-encoding or EXIF stripping
- `ShareIntentDialog` uses `file.path` directly instead of `File(file.path).readAsBytes()` — same OOM fix

**Optimistic UI — `PendingUploads` + `PendingNoteWidget`:**
- On Send: dialog dismisses instantly, file copied to `<docsDir>/pending_uploads/<uuid><ext>`, ghost note appears in chat immediately
- `PendingNoteWidget` matches `NoteItem` card styling (border `#CE2161`, bg `#F6F0ED`, padding 12, maxWidth 600)
- Images: shimmer skeleton sized to actual image dimensions + `LinearProgressIndicator` below; on upload complete, server image loads in-place behind shimmer then footer transitions to timestamp+actions
- Videos/documents: file icon + filename + `LinearProgressIndicator`
- Footer (uploading): "X MB / Y MB" progress text + **Cancel** button
- Footer (error): "Upload failed" + **Retry** / **Dismiss** buttons
- On success: ghost note removed + `ref.invalidate(notesProvider(channelId))` as fallback for missed WebSocket events (e.g. app backgrounded)
- Upload timeout: **1 minute** — network loss triggers error state
- Cancel: closes the active `http.Client`, removes ghost note and deletes local copy
- Sequential queue: multiple ghost notes appear at once, uploads proceed one-by-one
- Orphaned file cleanup: scan `pending_uploads/` on app start, delete files older than 24h
- Web: bytes-based path, `PendingUpload.localBytes` stores bytes for `Image.memory()` preview; browser reload loses all in-progress uploads (expected)

**MIME type — two layers of defence:**
1. Client passes `contentType: MediaType.parse(mimeType)` in `MultipartFile` so server receives the correct type
2. Server falls back to `lookupMimeType(originalFilename)` if content-type is still `application/octet-stream` (Android content URI filenames can lack extensions — client-side `getMimeTypeFromExtension` also accepts `filePath` as fallback)

**Progress tracking:**
Wraps the *outgoing network stream* (via `multipart.finalize() → StreamedRequest`), not the disk-read stream. Disk reads are near-instant and would show 0 → 100% immediately.

### Future Phases

**Enhanced Media**
- Resumable uploads (chunked protocol)
- Image editing (crop, rotate)

**Media Gallery**
- Date range filtering
- Media type filtering

**Advanced Features**
- Storage analytics dashboard
- Content-based image search

---

## Architecture

### Storage Strategy

**File System Layout:**
```
/data/media/
├── channels/
│   ├── {channel_id}/
│   │   ├── {uuid}.jpg           # UUID-based filename
│   │   ├── {uuid}.webp
│   │   └── thumbnails/
│   │       └── {uuid}_thumb.webp
```

**Key Decisions:**
1. **Use UUID for filenames** - Prevents race conditions, no dependency on note ID
2. **Use channel ID (not name)** - Avoids brittleness from channel renames
3. **Store original filename in DB only** - Security: user input never used in paths
4. **Separate thumbnails directory** - Organized, easy to regenerate
5. **Lossless conversion** - Non-web-safe formats (TIFF, BMP, etc.) converted to PNG; web-safe formats kept as-is

**Docker Volume Binding:**
```yaml
services:
  memoka_server:
    volumes:
      - ./data/media:/app/media
```

### Data Models

#### MediaAttachment (.spy.yaml)
```yaml
class: MediaAttachment
table: media_attachments

fields:
  # Foreign key to note
  noteId: int, relation(parent=notes, onDelete=Cascade)
  
  # Redundant channelId for efficient querying
  channelId: int, relation(parent=channels, onDelete=Cascade)
  
  # Storage path (UUID-based, no user input)
  filePath: String  # e.g., "channels/123/a1b2c3d4-e5f6-7890.jpg"
  
  # Original filename from user (display only, never used in paths)
  originalFilename: String
  
  # MIME type
  mimeType: String  # e.g., "image/jpeg", "image/png", "image/gif"
  
  # File metadata
  fileSize: int  # bytes
  width: int?
  height: int?
  
  # Thumbnail path (if generated)
  thumbnailPath: String?
  
  # Legacy compression flag (always false, retained for schema compatibility)
  compressed: bool, default=false
  
  # Is this an animated GIF?
  animated: bool, default=false
  
  # Content hash for cache busting
  contentHash: String?
  
  # Upload timestamp
  uploadedAt: DateTime, default=now

indexes:
  note_idx:
    fields: noteId
  channel_idx:
    fields: channelId, uploadedAt
```

#### Note Model Update
```yaml
# Add to existing note.spy.yaml
fields:
  # ... existing fields
  attachments: List<MediaAttachment>?
```

### Database References

**Query Optimization:**
When fetching notes, use JOIN to avoid N+1 queries:

```sql
SELECT notes.*, 
       json_agg(
         json_build_object(
           'id', ma.id,
           'filePath', ma."filePath",
           'originalFilename', ma."originalFilename",
           'mimeType', ma."mimeType",
           'fileSize', ma."fileSize",
           'width', ma.width,
           'height', ma.height,
           'thumbnailPath', ma."thumbnailPath",
           'compressed', ma.compressed,  -- legacy, always false
           'animated', ma.animated,
           'contentHash', ma."contentHash"
         )
       ) FILTER (WHERE ma.id IS NOT NULL) as attachments
FROM notes 
LEFT JOIN media_attachments ma ON ma."noteId" = notes.id
WHERE notes."channelId" = ?
GROUP BY notes.id
ORDER BY notes."createdAt" DESC
LIMIT 50;
```

**Cascading Deletes:**
- Delete note → cascade deletes attachments → server cleanup deletes files
- Delete channel → cascade deletes notes → cascade deletes attachments → cleanup files

---

## Upload Flow

### 1. Client-Side (Flutter)

**Paste Detection:**
```dart
// In ChatView or NoteInput
onKeyEvent: (event) {
  if (event is KeyDownEvent && 
      event.logicalKey == LogicalKeyboardKey.keyV &&
      HardwareKeyboard.instance.isControlPressed) {
    _handlePaste();
  }
}

Future<void> _handlePaste() async {
  final imageData = await Clipboard.getImage();
  if (imageData != null) {
    _showImageUploadDialog(imageData);
  }
}
```

**Upload Dialog:**
- Preview image (scaled to fit)
- File preview (images shown in justified grid, non-images in list)
- Buttons: "Cancel" | "Send"

**Upload Process (Phase 3 — Async / Optimistic):**
```
1. Dialog dismisses instantly; file copied to <docsDir>/pending_uploads/<uuid><ext>
2. Ghost note (PendingNoteWidget) appears in chat immediately with progress bar
3. PendingUploads notifier queues upload and POSTs multipart to POST /media/upload
4. Progress tracked on outgoing network stream ("X MB / Y MB" in footer)
5. On success: ghost note removed, notesProvider invalidated (WebSocket fallback)
6. On failure: "Upload failed" state with Retry / Dismiss buttons
7. Cancel: closes http.Client, removes ghost note, deletes local copy
```
See `memoka_flutter/lib/providers/pending_uploads_provider.dart` for implementation.

### 2. Server-Side (HTTP Route)

> **Note:** The original `MediaEndpoint` Serverpod RPC class was removed. All uploads go through `MediaUploadRoute` — a plain HTTP multipart route at `POST /media/upload`. See `memoka_server/lib/src/web/routes/media_upload_route.dart` for the actual implementation.

**Image Processing (in Isolate):**

Any `image/*` MIME type is treated as an image. Processing depends on format:

| Input | Output | Conversion? | EXIF stripped? |
|---|---|---|---|
| JPEG (.jpg/.jpeg) | JPEG (as-is) | No | No |
| PNG (.png) | PNG (as-is) | No | No |
| WebP (.webp) | WebP (as-is) | No | No |
| GIF (.gif) | GIF (as-is) | No (preserves animation) | No |
| TIFF, BMP, ICO, PSD, TGA | PNG | Yes | Yes (converted to PNG) |
| Undecodable (e.g. HEIC) | Document fallback | N/A | N/A |

All images get a JPEG thumbnail (300px, quality 80) and content hash.
If `package:image` cannot decode a format, the upload route falls back to the document path (stored as-is with document card display).

See `memoka_server/lib/src/media/image_processor.dart` for implementation.

**Serving Files (Static Route - Public Access):**

```dart
// In server.dart
// NOTE: Public access - no authentication required
// This is intentional for single-user/trusted environment
pod.webServer.addRoute(
  Route.get('/media/channels/<channelId>/<filename>'),
  (request, channelId, filename) async {
    // Sanitize filename (whitelist chars)
    final sanitized = _sanitizeFilename(filename);
    
    final filePath = '/app/media/channels/$channelId/$sanitized';
    final file = File(filePath);
    
    if (!await file.exists()) {
      return Response.notFound('File not found');
    }
    
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(sanitized) ?? 'application/octet-stream';
    
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': mimeType,
        'Cache-Control': 'public, max-age=31536000, immutable',  // 1 year cache
      },
    );
  },
);

String _sanitizeFilename(String filename) {
  // Whitelist: alphanumeric, dots, dashes, underscores
  return filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
}
```

---

## Display in Chat

### ChatView Updates

**Note Item with Media:**
```dart
Widget _buildNoteItem(Note note, int channelId) {
  return ListTile(
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Markdown content
        if (note.content.isNotEmpty)
          MarkdownBody(...),
        
        // Media attachments (loaded via JOIN, no N+1 queries)
        if (note.attachments != null)
          ...note.attachments!.map((attachment) => 
            MediaAttachmentWidget(attachment: attachment)
          ),
        
        // Link preview
        if (note.linkPreview != null)
          LinkPreviewCard(...),
      ],
    ),
    // ... rest of note UI
  );
}
```

**MediaAttachmentWidget:**

Routes to `_ImageAttachmentWidget`, `VideoAttachmentWidget`, or `DocumentAttachmentWidget` based on MIME type.

Key display behavior:
- **Pre-sized placeholders**: Uses `attachment.width` and `attachment.height` metadata from the server to compute display dimensions before the image loads, eliminating layout jumps
- **Shimmer animation**: Placeholder shows an animated gradient sweep (grey[800] → grey[700] → grey[800]) instead of a spinner, sized to exact computed dimensions
- **Fast fade-in**: `fadeInDuration: 150ms` so disk-cached images appear near-instantly (vs default 500ms)
- **Aspect-ratio preservation**: `computeDisplaySize()` helper clamps to max constraints (600x500 for images, 400x300 for videos) while maintaining aspect ratio
- **Fallback sizing**: If `width`/`height` metadata is null, falls back to 300x200
- **Animated GIF handling**: GIFs use `Image.network` (not `CachedNetworkImage`) to preserve animation. Non-GIF images use `CachedNetworkImage` for disk caching. The `attachment.animated` flag is retained for server-side processing logic (preserving original GIF) but does not affect the Flutter rendering path.
- **Image precaching**: When notes load for the displayed channel, `chat_view.dart` fires `precacheImage()` for the 20 most recent image attachments into Flutter's `ImageCache`. On channel revisit, these images are served from memory cache synchronously — `CachedNetworkImage` skips the placeholder entirely and the shimmer does not appear.

**Video Lightbox:**

Videos open in a lightbox dialog (not a route push) via `_VideoLightbox.show()`:
- Triggered by tapping the video thumbnail in chat
- Full-screen dialog with `Colors.black` at 92% opacity backdrop
- Embedded video player with play/pause controls, progress bar, and duration display
- Keyboard support: Space to play/pause, Escape to close
- Implemented in `video_attachment_widget.dart`

```dart
// Shared helper for computing display dimensions
Size computeDisplaySize({
  int? width, int? height,
  required double maxWidth, required double maxHeight,
  Size fallback = const Size(300, 200),
}) {
  if (width == null || height == null) return fallback;
  final scale = min(maxWidth / width, maxHeight / height).clamp(0.0, 1.0);
  return Size(width * scale, height * scale);
}

// ShimmerPlaceholder: StatefulWidget with AnimationController
// - 1200ms repeat cycle
// - LinearGradient with sliding alignment
// - Rounded corners (8px border radius)
// - Sized to computed display dimensions
```

---

## ✅ Confirmed Decisions

### File Size & Storage
- **File size limit:** 1GB per file
- **No storage quotas:** Unlimited storage per channel
- **Monitoring:** Optional disk usage alert at 85%
- **Rationale:** Self-hosted server with sufficient storage capacity

### Image Processing

**No image compression.** Images are stored losslessly in a browser-viewable format:
- **Web-safe formats** (JPEG, PNG, WebP, GIF): kept as-is (no re-encoding, no EXIF stripping)
- **Non-web-safe formats** (TIFF, BMP, ICO, PSD, TGA, etc.): converted to PNG
- **Undecodable formats** (HEIC, etc.): stored as documents (fallback)
- **Thumbnails:** 300px wide, JPEG format, generated in isolate

**Videos:**
- **No compression** — videos are stored as-is
- **Thumbnails:** Generated from the 1-second mark via ffprobe/ffmpeg

### Supported Formats

**All file types are accepted.** The server applies type-specific processing:

- **Images** (any `image/*` MIME type): format conversion if needed (non-web-safe only), thumbnail generation. No compression, resizing, or EXIF stripping for web-safe formats.
- **Videos** (MP4, MOV, WebM, AVI, MKV): thumbnail generation, metadata extraction (no compression)
- **Documents & other files**: stored as-is with a content hash; no image/video processing

Files with unknown or missing MIME types (`application/octet-stream`) are accepted and stored using the original filename's extension.

### Upload Behavior
- **Multi-file support:** Select, drag, or paste multiple files at once
- **Paste priority:** If clipboard has files, ignore text — intercepts even when text field is focused
- **No compression:** Files are uploaded and stored as-is
- **Progress indicator:** Shows upload count and progress for multi-file uploads
- **Error handling:** Toast notifications (success/error) with human-readable messages
- **Streaming:** Upload via stream (memory-safe)
- **Sequential processing:** Files uploaded one-by-one to avoid server overload
- **Dialog routing**:
  - Single file → `MultiFileUploadDialog` (simple preview)
  - Multiple files → `MultiFileUploadDialog` (justified grid + file list)

### Display & Interaction
- **Delete:** Delete entire note to remove images (no individual image delete yet)
- **Full screen:** Click image to open full screen viewer
- **Loading:** Shimmer placeholder sized to actual image dimensions (no layout jump)
- **Scroll-back:** Pre-sized placeholder prevents re-layout when ListView virtualizes and re-creates widgets
- **Cached images:** 150ms fade-in so disk-cached images appear near-instantly
- **Failed load:** Show broken image icon with error message, sized to computed dimensions

### Security & Privacy
- **Public access:** No authentication required (single-user/trusted environment)
- **Channel validation:** Verify channel exists but no user permissions
- **EXIF preserved:** Web-safe formats (JPEG, PNG, WebP) are stored as-is; no EXIF stripping or rotation applied. Dimensions are read from the decoded image but the file is not modified.
- **File validation:** Decode image on server to ensure valid file
- **Path sanitization:** UUID filenames, whitelist chars, ignore user input

### File Naming & Storage
- **UUID-based filenames:** Prevents race conditions, no note ID dependency
- **Content hash:** For cache busting (URL param: ?v={hash})
- **Original filename:** Stored in DB only, never used in file paths
- **Animated GIF detection:** Check frame count, preserve if animated
- **Web media URLs:** Always derived from `serverUrl` config (port 8080 → 8082 for dev; same origin for production behind a reverse proxy). Never uses `Uri.base` (which would point to the Flutter dev server, not the media server).

### Performance
- **Streaming uploads:** Stream to temp file, process from disk
- **Isolate processing:** Thumbnail generation in compute() isolate
- **Two-phase commit:** Write .tmp → DB insert → atomic rename
- **Query optimization:** JOIN to load attachments with notes (no N+1)
- **Thumbnail generation:** Blocking in isolate (consistent UX)

### Real-time Updates
- **WebSocket broadcast:** Yes - broadcast `noteCreated` with attachment
- **Live preview:** Other users see images immediately after thumbnail generation
- **Thumbnail generation:** Completed in isolate before broadcast

---

## Implementation Fixes (from Technical Review)

### 1. Note ID Atomicity ✅
**Problem:** Race condition - using note_id in filename before note exists  
**Solution:** UUID-based filenames independent of note ID  
**Implementation:** Generate UUID first, create note after file processed

### 2. Memory Streaming ✅
**Problem:** Loading entire file into ByteData crashes on large files
**Solution:** Stream<List<int>> with chunked writes to temp file
**Implementation:** Validate 1GB limit while streaming, early abort on overflow

### 3. Atomic File+DB Writes ✅
**Problem:** Crash during upload can orphan files or DB records  
**Solution:** Two-phase commit pattern  
**Implementation:**
```
1. Write to {uuid}.tmp
2. Process image from temp file
3. Insert DB record (transaction)
4. Atomic rename to {uuid}.ext
5. On any error: delete .tmp file
```

### 4. Async Thumbnail Generation ✅
**Problem:** Thumbnail encoding blocks HTTP response (bad UX)  
**Solution:** Generate thumbnail in compute() isolate  
**Implementation:** Parallel image processing in background thread  
**Decision:** Blocking upload (user wants preview to appear immediately)

### 5. Path Sanitization ✅
**Problem:** User-provided filenames can cause path traversal attacks  
**Solution:** UUID storage names, whitelist chars, ignore original filename  
**Implementation:**
```dart
// Storage filename: UUID only (no user input)
final storageFilename = '${uuid}.jpg';

// Original filename: DB only, display purposes
final displayName = 'vacation-photo.jpg';  // Stored in media_attachments table
```

### 6. Query Optimization ✅
**Problem:** N+1 queries loading notes then attachments separately  
**Solution:** Single JOIN query with json_agg  
**Implementation:** LEFT JOIN media_attachments, aggregate as JSON array

### 7. Cache Busting ✅
**Problem:** Browser caches old image on re-upload  
**Solution:** Append content hash to URL  
**Implementation:** `/media/path/file.jpg?v={sha256_prefix}`

### 8. GIF Preservation ✅
**Problem:** Converting animated GIFs to static WebP kills animation  
**Solution:** Detect frame count, preserve original, generate static thumbnail  
**Implementation:**
```dart
final gif = decodeGif(bytes);
if (gif.numFrames > 1) {
  animated = true;
  // Save original GIF file as-is
  // Generate thumbnail from first frame only
}
```

### 9. EXIF Handling ✅
**Previous approach:** Strip EXIF after applying bakeOrientation() — re-encoded the file.
**Current approach:** Web-safe formats (JPEG, PNG, WebP) are passed through as-is with no re-encoding. EXIF metadata (including orientation) is preserved in the original file. Dimensions are read from the decoded image for display sizing, but the file bytes are not modified. Non-web-safe formats are converted to PNG (which inherently discards EXIF).

### 10. Resumable Uploads ⏸️
**Status:** Deferred
**Rationale:** Adds significant complexity; 1GB limit and 1-minute timeout cover most use cases
**Future:** Implement chunked upload protocol if users need it

---

## Future Extensibility

### Media Gallery Tab (Phase 2)

**UI Design:**
- Tab in channel view (beside chat)
- Grid layout of image thumbnails
- Click to open full screen
- Filter by date range
- Sort by newest/oldest

**Backend:**
```dart
Future<List<MediaAttachment>> getChannelMedia(
  Session session,
  int channelId, {
  int offset = 0,
  int limit = 50,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  return await MediaAttachment.db.find(
    session,
    where: (t) => t.channelId.equals(channelId),
    orderBy: (t) => t.uploadedAt,
    orderDescending: true,
    limit: limit,
    offset: offset,
  );
}
```

### Resumable Uploads (Phase 2)

**Chunked Upload Protocol:**
```
POST /api/media/upload-chunk
Headers:
  X-Upload-ID: {uuid}
  X-Chunk-Index: {0-based index}
  X-Total-Chunks: {total}
  X-File-Hash: {sha256}
Body: chunk binary data (5MB)

Server:
1. Store chunk: /tmp/uploads/{upload_id}/chunk_{index}
2. When all chunks received: assemble, validate hash, process
3. On connection drop: client resumes from last successful chunk
```

**Benefits:**
- Resume on connection drop
- Progress persistence
- Better for unstable networks

**Complexity:**
- Chunk assembly logic
- Cleanup of abandoned uploads
- State management

### Search and Filter (Phase 3)

**Backend Indexing:**
```yaml
indexes:
  channel_date_idx:
    fields: channelId, uploadedAt
  channel_type_idx:
    fields: channelId, mimeType, uploadedAt
```

### Storage Monitoring (Optional)

**Health Check Endpoint:**
```dart
Future<StorageHealth> getStorageHealth(Session session) async {
  final mediaDir = Directory('/app/media');
  final stat = await statvfs(mediaDir.path);
  
  final totalBytes = stat.blockSize * stat.blocks;
  final usedBytes = totalBytes - (stat.blockSize * stat.availableBlocks);
  final usedPercent = (usedBytes / totalBytes * 100).round();
  
  return StorageHealth(
    totalBytes: totalBytes,
    usedBytes: usedBytes,
    usedPercent: usedPercent,
    warning: usedPercent >= 85,  // Optional alert threshold
  );
}
```

---

## Security Considerations

### Public Access (No Auth)
**Decision:** Media URLs are publicly accessible without authentication  
**Rationale:**
- Single-user/trusted environment
- No user authentication system implemented
- Simplifies architecture (CDN-friendly, direct links work)
- Security by obscurity (UUID filenames)

**Documented Risk:**
Anyone with a media URL can view the file. This is acceptable because:
1. App is single-user (you only)
2. UUIDs are unguessable (128-bit random)
3. No directory listing exposed
4. Trusted network environment

**Future (if multi-user):**
Add authentication middleware:
```dart
// Check session + channel access before serving
if (!await _hasChannelAccess(session, channelId)) {
  return Response.forbidden();
}
```

### File Upload Validation
- ✅ Accept all file types (no MIME whitelist); unknown types stored as-is
- ✅ Enforce 1GB size limit
- ✅ Decode image to validate format
- ✅ Sanitize all file paths
- ✅ UUID prevents directory traversal
- ✅ EXIF preserved for web-safe formats (no stripping); non-web-safe formats converted to PNG (EXIF discarded)

### Path Traversal Prevention
```dart
// All filenames are UUIDs - no user input in paths
final uuid = Uuid().v4();  // e.g., "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
final filename = '$uuid.jpg';  // Safe - no user input

// Original filename stored in DB only (never used in file system)
final originalFilename = userInput;  // "../../etc/passwd" - stored but ignored
```

---

## Dependencies

### Server
```yaml
dependencies:
  serverpod: 3.3.1
  image: ^4.0.0       # Image processing
  mime: ^1.0.0        # MIME type detection
  path: ^1.8.0        # Path utilities
  uuid: ^4.0.0        # UUID generation
  crypto: ^3.0.0      # SHA-256 hashing
```

### Flutter
```yaml
dependencies:
  image_picker: ^1.0.0              # Camera capture
  cached_network_image: ^3.4.1      # Image caching
  photo_view: ^0.14.0               # Full screen viewer
  http: ^1.3.0                      # Multipart upload streaming
  # NOTE: All compression removed — files stored as-is
```

---

## Migration Strategy

### Database Migration
```sql
CREATE TABLE media_attachments (
  id SERIAL PRIMARY KEY,
  "noteId" INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
  "channelId" INTEGER NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
  "filePath" TEXT NOT NULL,
  "originalFilename" TEXT NOT NULL,
  "mimeType" TEXT NOT NULL,
  "fileSize" INTEGER NOT NULL,
  width INTEGER,
  height INTEGER,
  "thumbnailPath" TEXT,
  compressed BOOLEAN DEFAULT false,  -- legacy, always false
  animated BOOLEAN DEFAULT false,
  "contentHash" TEXT,
  "uploadedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX media_note_idx ON media_attachments("noteId");
CREATE INDEX media_channel_idx ON media_attachments("channelId", "uploadedAt");
```

### File System Setup
```bash
# On server
mkdir -p /data/media/channels
chmod 755 /data/media
chown serverpod:serverpod /data/media
```

---

## Testing Strategy

### Unit Tests
```dart
test('UUID filename generation', () {
  final uuid = Uuid().v4();
  expect(uuid.length, 36);
  expect(uuid, matches(RegExp(r'^[a-f0-9-]{36}$')));
});

test('Path sanitization', () {
  expect(_sanitizeFilename('image.jpg'), 'image.jpg');
  expect(_sanitizeFilename('../../../etc/passwd'), '_.._.._.._etc_passwd');
  expect(_sanitizeFilename('file<script>.jpg'), 'file_script_.jpg');
});

test('EXIF orientation applied before stripping', () async {
  final image = await decodeImage(iphonePhotoBytes);
  final oriented = bakeOrientation(image);
  // Verify rotation applied
  expect(oriented.width, image.height);  // Rotated 90°
});
```

### Integration Tests

> **Note:** `MediaEndpoint` was removed. Upload integration tests would target `POST /media/upload` directly via `http.MultipartRequest`. The examples below are historical design references only.

```dart
// HISTORICAL — MediaEndpoint no longer exists
// Real uploads go to POST /media/upload (MediaUploadRoute)
withServerpod('Given MediaUploadRoute', (sessionBuilder, endpoints) {
  test('when uploading >1GB then should reject', () async {
    // Send multipart POST to /media/upload with oversized stream
    // Expect 413 or error response
  });

  test('when upload fails then should cleanup temp file', () async {
    // Verify no orphaned .tmp files after failed upload
  });
});
```

---

## Performance Considerations

### Thumbnail Strategy
- Generate on upload in isolate (blocking but consistent)
- User sees preview immediately after send
- Pre-generated = faster gallery loading

### Caching
- Client: CachedNetworkImage with disk cache
- Server: `Cache-Control: public, max-age=31536000, immutable`
- Cache busting via content hash in URL param
- Fast fade-in (150ms) for disk-cached images to avoid perceived re-loading on scroll-back
- Pre-sized shimmer placeholders prevent layout shifts during cache reads

### Image Handling
- Lossless storage (no compression, no resizing)
- Non-web-safe formats converted to PNG for browser display
- Thumbnail generation (300px JPEG for all images)
- Animated GIF detection (preserve vs static)

### Query Performance
- Single JOIN query (no N+1)
- Indexes on channelId + uploadedAt
- LIMIT queries for pagination
- json_agg for efficient aggregation

---

## Related Files

### Server
- `lib/src/media/media_attachment.spy.yaml`
- `lib/src/media/image_processor.dart`
- `lib/src/chat/note.spy.yaml`
- `lib/server.dart`

### Flutter
- `lib/widgets/media_attachment_widget.dart`
- `lib/widgets/file_upload_dialog.dart`
- `lib/widgets/document_attachment_widget.dart`
- `lib/widgets/full_screen_image_view.dart`
- `lib/widgets/chat_view.dart`
- `lib/widgets/note_input.dart`

### Infrastructure
- `memoka_server/docker-compose.yaml`
- `migrations/`
