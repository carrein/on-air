# Media Upload and Storage

Covers media upload, storage, and display for images, videos, and documents in the chat application.

## Overview

### Phase 1 (Completed): Single File Upload
- Paste images from clipboard (Ctrl+V)
- Drag-drop single file support
- Upload dialog with compression option
- Display inline in chat messages
- No captions required
- 100MB file size limit (increased from 50MB)
- Public access (no authentication required)

### Phase 2 (Completed): Multi-File Upload & Documents & Video
- **Multiple file selection** via file picker (`allowMultiple: true`)
- **Drag-drop multiple files** at once
- **Paste multiple files** from clipboard
- **Upload dialog**: `MultiFileUploadDialog` with progress tracking
- **Per-file compression**: Individual toggle for each image/video
- **Sequential upload**: Files uploaded one-by-one to avoid overwhelming server
- **Progress indicator**: Shows "Uploading X of Y..." with progress bar
- **Document support**: PDF, Text, Word, Excel, Zip file support
- **Video support**: MP4, MOV, WebM, AVI, MKV with thumbnail generation and optional 720p compression
- **File picker UI**: `FilePicker` with custom file type extensions

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
5. **WebP for compressed** - Better compression than JPEG, wide support

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
  
  # Compression flag
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
           'compressed', ma.compressed,
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
- Checkbox: "Compress image" (checked by default)
  - Full size: Original image (max 50MB)
  - Compressed: Resize to max 1920px, quality 85%, WebP format
- Buttons: "Cancel" | "Send"

**Upload Process:**
```dart
1. Show dialog with image preview
2. User selects compression option
3. Validate file size <= 50MB
4. Compress image if selected (using image package)
5. Call server endpoint: POST /api/chat/upload-media
   - multipart/form-data
   - Stream file data (not load into memory)
   - fields: channelId, compress, file stream
6. Server returns MediaAttachment metadata
7. Create note with attachment reference
8. Close dialog, display in chat with thumbnail
9. Preview appears immediately (thumbnail generated on server)
```

### 2. Server-Side (Serverpod)

**Critical: Atomic Upload with Two-Phase Commit**

```dart
class MediaEndpoint extends Endpoint {
  Future<MediaAttachment> uploadMedia(
    Session session,
    int channelId,
    bool compress,
    Stream<List<int>> fileStream,  // Stream, NOT ByteData
    String originalFilename,
    String mimeType,
  ) async {
    // 1. Validate file type and size limit (50MB)
    if (!_isValidMimeType(mimeType)) {
      throw Exception('Invalid file type');
    }
    
    // 2. Generate UUID for filename (no race conditions)
    final uuid = Uuid().v4();
    final ext = _getExtension(mimeType);
    final tempFilename = '$uuid.tmp';
    final finalFilename = '$uuid$ext';
    
    final channelDir = Directory('/app/media/channels/$channelId');
    await channelDir.create(recursive: true);
    
    // 3. Stream to temporary file (memory-safe)
    final tempFile = File('${channelDir.path}/$tempFilename');
    int bytesWritten = 0;
    final sink = tempFile.openWrite();
    
    try {
      await for (final chunk in fileStream) {
        bytesWritten += chunk.length;
        if (bytesWritten > 50 * 1024 * 1024) {  // 50MB limit
          throw Exception('File exceeds 50MB limit');
        }
        sink.add(chunk);
      }
      await sink.close();
      
      // 4. Process image (compression, thumbnail, EXIF)
      final processedData = await _processImage(
        tempFile.path,
        compress,
        mimeType,
      );
      
      // 5. Create MediaAttachment record in database
      final attachment = MediaAttachment(
        noteId: processedData.noteId,  // Created in transaction
        channelId: channelId,
        filePath: 'channels/$channelId/$finalFilename',
        originalFilename: originalFilename,
        mimeType: processedData.finalMimeType,
        fileSize: processedData.fileSize,
        width: processedData.width,
        height: processedData.height,
        thumbnailPath: processedData.thumbnailPath,
        compressed: compress,
        animated: processedData.animated,
        contentHash: processedData.hash,
      );
      
      final saved = await MediaAttachment.db.insertRow(session, attachment);
      
      // 6. Atomic rename: temp → final (only after DB insert succeeds)
      final finalFile = File('${channelDir.path}/$finalFilename');
      await tempFile.rename(finalFile.path);
      
      return saved;
      
    } catch (e) {
      // 7. Cleanup: delete temp file on any error
      await sink.close();
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    }
  }
}
```

**Image Processing (in Isolate):**

```dart
class _ImageProcessResult {
  final int fileSize;
  final int width;
  final int height;
  final String? thumbnailPath;
  final String finalMimeType;
  final bool animated;
  final String hash;
}

Future<_ImageProcessResult> _processImage(
  String tempFilePath,
  bool compress,
  String mimeType,
) async {
  // Run in isolate to avoid blocking main thread
  return await compute(_processImageIsolate, {
    'path': tempFilePath,
    'compress': compress,
    'mimeType': mimeType,
  });
}

Future<_ImageProcessResult> _processImageIsolate(Map<String, dynamic> params) async {
  final file = File(params['path']);
  final bytes = await file.readAsBytes();
  
  // Decode image
  Image? image;
  bool animated = false;
  
  if (params['mimeType'] == 'image/gif') {
    final gif = decodeGif(bytes);
    if (gif != null && gif.numFrames > 1) {
      // Animated GIF: preserve original, generate static thumbnail
      animated = true;
      image = gif.frames.first;  // Use first frame for thumbnail
    } else {
      image = gif;
    }
  } else {
    image = decodeImage(bytes);
  }
  
  if (image == null) {
    throw Exception('Failed to decode image');
  }
  
  // Apply EXIF orientation BEFORE stripping metadata
  image = bakeOrientation(image);
  
  int width = image.width;
  int height = image.height;
  String finalMimeType = params['mimeType'];
  
  // Compress if requested and not animated GIF
  if (params['compress'] && !animated) {
    // Resize if too large
    if (width > 1920 || height > 1920) {
      image = copyResize(image, 
        width: width > height ? 1920 : null,
        height: height > width ? 1920 : null,
      );
      width = image.width;
      height = image.height;
    }
    
    // Convert to WebP
    final webpBytes = encodeWebP(image, quality: 85);
    await file.writeAsBytes(webpBytes);
    finalMimeType = 'image/webp';
  }
  
  // Generate thumbnail (300px wide) in isolate
  final thumbnail = copyResize(image, width: 300);
  final thumbnailBytes = encodeWebP(thumbnail, quality: 80);
  
  final thumbnailDir = Directory('${file.parent.path}/thumbnails');
  await thumbnailDir.create();
  
  final uuid = path.basenameWithoutExtension(file.path);
  final thumbnailPath = 'thumbnails/${uuid}_thumb.webp';
  final thumbnailFile = File('${file.parent.path}/$thumbnailPath');
  await thumbnailFile.writeAsBytes(thumbnailBytes);
  
  // Calculate content hash for cache busting
  final hash = sha256.convert(await file.readAsBytes()).toString().substring(0, 8);
  
  final fileSize = await file.length();
  
  return _ImageProcessResult(
    fileSize: fileSize,
    width: width,
    height: height,
    thumbnailPath: thumbnailPath,
    finalMimeType: finalMimeType,
    animated: animated,
    hash: hash,
  );
}
```

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
- **Animated GIF handling**: Animated GIFs use `Image.network` (preserves animation); static images use `CachedNetworkImage` (disk caching with shimmer placeholder). The `attachment.animated` flag determines which widget to use.
- **Media-only notes**: Notes with only media attachments and no text content render without the white chat bubble wrapper for a cleaner visual appearance. Detected via `_isMediaOnlyNote()` helper.

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
- **File size limit:** 50MB per file
- **No storage quotas:** Unlimited storage per channel
- **Monitoring:** Optional disk usage alert at 85%
- **Rationale:** Self-hosted server with sufficient storage capacity

### Compression Settings

**Images:**
- **Default:** Compression off (user opts in)
- **Compressed:** Max 1920px, WebP format, 85% quality
- **Original:** Keep original if unchecked
- **Thumbnails:** 300px wide, WebP format, generated in isolate

**Videos:**
- **Default:** Compression off (user opts in)
- **Compressed:** Max 1280×720, H.264 codec, medium quality preset (server-side via ffmpeg)
- **Thumbnails:** Generated from the 1-second mark via ffprobe/ffmpeg

### Supported Formats

**Images (Phase 1):**
- **JPEG** - Convert to WebP if compressed
- **PNG** - Convert to WebP if compressed (preserves transparency)
- **WebP** - Native support
- **GIF** - Preserve animated GIFs, generate static thumbnail
- **HEIC** (iPhone) - Convert to WebP

**Videos (Phase 2):**
- **MP4**: `video/mp4`
- **MOV / QuickTime**: `video/quicktime`
- **WebM**: `video/webm`
- **AVI**: `video/x-msvideo`
- **MKV**: `video/x-matroska`

Processing: `ffprobe` extracts width/height/duration; thumbnail generated at the 1-second mark via ffmpeg; optional compression to 720p H.264.

**Documents (Phase 2):**
- **PDF**: `application/pdf`
- **Text**: `text/plain`, `text/markdown`
- **Word**: `application/msword`, `application/vnd.openxmlformats-officedocument.wordprocessingml.document`
- **Excel**: `application/vnd.ms-excel`, `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
- **Zip**: `application/zip`

### Upload Behavior
- **Multi-file support:** Select, drag, or paste multiple files at once
- **Paste priority:** If clipboard has files, ignore text — intercepts even when text field is focused
- **Default compression:** Compress toggle defaults to **off** (user opts in)
- **Progress indicator:** Shows upload count and progress for multi-file uploads
- **Error handling:** Toast notifications (success/error) with human-readable messages
- **Streaming:** Upload via stream (memory-safe)
- **Sequential processing:** Files uploaded one-by-one to avoid server overload
- **Dialog routing**:
  - Single file → `FileUploadDialog` (simple preview + compression)
  - Multiple files → `MultiFileUploadDialog` (list view + per-file compression)

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
- **EXIF stripping:** Remove GPS and personal metadata AFTER rotation
- **EXIF orientation:** Apply rotation before stripping (iPhone compatibility)
- **File validation:** Decode image on server to ensure valid file
- **Path sanitization:** UUID filenames, whitelist chars, ignore user input

### File Naming & Storage
- **UUID-based filenames:** Prevents race conditions, no note ID dependency
- **Content hash:** For cache busting (URL param: ?v={hash})
- **Original filename:** Stored in DB only, never used in file paths
- **Animated GIF detection:** Check frame count, preserve if animated
- **Web media URLs:** Uses `Uri.base` origin on web platform (works behind reverse proxies without hardcoded ports)

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
**Implementation:** Validate 50MB limit while streaming, early abort on overflow

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

### 9. EXIF Orientation ✅
**Problem:** iPhone photos appear sideways after EXIF stripped  
**Solution:** Apply bakeOrientation() BEFORE stripping EXIF  
**Implementation:**
```dart
1. Decode image
2. image = bakeOrientation(image);  // Rotate based on EXIF
3. Strip all EXIF metadata
4. Encode to WebP
```

### 10. Resumable Uploads ⏸️
**Status:** Deferred to Phase 2  
**Rationale:** Adds significant complexity, 50MB limit makes it less critical  
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
- ✅ Validate MIME type (whitelist)
- ✅ Enforce 50MB size limit while streaming
- ✅ Decode image to validate format
- ✅ Sanitize all file paths
- ✅ UUID prevents directory traversal
- ✅ Strip EXIF metadata (privacy)

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
  serverpod: 3.2.3
  image: ^4.0.0       # Image processing
  mime: ^1.0.0        # MIME type detection
  path: ^1.8.0        # Path utilities
  uuid: ^4.0.0        # UUID generation
  crypto: ^3.0.0      # SHA-256 hashing
```

### Flutter
```yaml
dependencies:
  image_picker: ^1.0.0              # For paste support
  cached_network_image: ^3.4.1      # Image caching
  photo_view: ^0.14.0               # Full screen viewer
  flutter_image_compress: ^2.1.0    # Client compression
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
  compressed BOOLEAN DEFAULT false,
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
```dart
withServerpod('Given MediaEndpoint', (sessionBuilder, endpoints) {
  test('when uploading >50MB then should reject', () async {
    final largeStream = _generate60MBStream();
    expect(
      () => endpoints.media.uploadMedia(
        sessionBuilder,
        channelId: 1,
        fileStream: largeStream,
        ...
      ),
      throwsA(contains('exceeds 50MB')),
    );
  });
  
  test('when upload fails then should cleanup temp file', () async {
    final tempDir = Directory('/app/media/channels/1');
    final beforeFiles = await tempDir.list().length;
    
    try {
      await endpoints.media.uploadMedia(
        sessionBuilder,
        channelId: 1,
        fileStream: _corruptedStream(),
        ...
      );
    } catch (_) {}
    
    final afterFiles = await tempDir.list().length;
    expect(afterFiles, beforeFiles);  // No orphaned files
  });
});
```

---

## Implementation Phases

### Phase 1: Basic Image Upload (MVP)
1. ✅ Create MediaAttachment model with UUID filenames
2. ✅ Update Note model with attachments field
3. ✅ Create media directory structure
4. ✅ Implement streaming upload endpoint with two-phase commit
5. ✅ Add paste detection in Flutter
6. ✅ Create upload dialog UI
7. ✅ Implement image compression with EXIF handling
8. ✅ Generate thumbnails in isolate
9. ✅ Display images in chat with cache busting
10. ✅ Serve images via public static route
11. ✅ Implement JOIN query for efficient loading

### Phase 2: Enhanced Features
1. Resumable uploads (chunked protocol)
2. Multiple images per upload
3. Full screen viewer with swipe
4. Image editing (crop, rotate)
5. Drag and drop support

### Phase 3: Media Gallery
1. Gallery tab UI with grid layout
2. Pagination and infinite scroll
3. Date range filtering
4. Media type filtering

### Phase 4: Advanced Features
1. Video support
2. File attachments (PDFs, documents)
3. Storage analytics dashboard
4. Content-based image search

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

### Image Optimization
- WebP format (30% smaller than JPEG)
- Thumbnail generation (300px vs full size)
- Lazy loading in gallery view (future)
- Animated GIF detection (preserve vs static)

### Query Performance
- Single JOIN query (no N+1)
- Indexes on channelId + uploadedAt
- LIMIT queries for pagination
- json_agg for efficient aggregation

---

## Deferred Features (Phase 2+)

### Not in Initial Implementation
- ❌ Resumable uploads (Phase 2 - chunked protocol)
- ❌ Multiple images per paste (Phase 2)
- ❌ Individual image deletion (delete note to delete images)
- ❌ Drag and drop upload (Phase 2)
- ❌ Mobile camera integration (Phase 2)
- ❌ Image editing before send (Phase 2)
- ❌ Multiple image sizes/responsive images (Phase 3)
- ❌ Video support (Phase 3)
- ❌ File attachments (Phase 3)
- ❌ Storage analytics dashboard (Phase 3)

---

## Document Upload Implementation Status

### Server-Side (Completed)
**File**: `memoka_server/lib/src/media/media_endpoint.dart`

Implemented features:
- Document MIME type support (PDF, TXT, MD, DOC, DOCX, XLS, XLSX, ZIP)
- Conditional processing logic:
  - Images: Full processing (compression, thumbnails, EXIF stripping)
  - Documents: Simple file storage with hash calculation
- `_isImage()` helper method to detect file type
- Extended `_getExtensionFromMimeType()` for all document types
- `ImageProcessor.calculateHash()` public method for document hash calculation

### Flutter-Side (Remaining Work)

**Required Changes:**

1. **Update Input** (`lib/widgets/note_input.dart`):
   - Replace `_pickImage()` with `_pickFile()` using `file_picker` package
   - Support all file extensions: jpg, png, pdf, txt, md, doc, docx, xls, xlsx, zip
   - Change button icon from `Icons.image` to `Icons.attach_file`
   - Update tooltip from "Upload image" to "Upload file"

2. **Create Generic Upload Dialog** (`lib/widgets/file_upload_dialog.dart`):
   - Detect file type (image vs document)
   - For images: Show preview + compression option
   - For documents: Show file info (name, size, type) + icon

3. **Update Media Attachment Widget** (`lib/widgets/media_attachment_widget.dart`):
   - Detect attachment MIME type
   - If image: Show existing image widget
   - If document: Show document card with file icon, filename, size, download button

4. **Create Document Attachment Widget** (`lib/widgets/document_attachment_widget.dart`):
   - Display document icon based on extension (PDF, TXT, DOC, etc.)
   - Show filename and formatted file size
   - Download button functionality

5. **Update Chat View** (`lib/widgets/chat_view.dart`):
   - Update `_handleWebDrop()` to accept all file types
   - Route to appropriate dialog based on detected file type

**Dependencies:**
- Add `file_picker: ^8.1.4` to `memoka_flutter/pubspec.yaml` (already added)

## Related Files

### Server
- `lib/src/media/media_attachment.spy.yaml`
- `lib/src/media/media_endpoint.dart`
- `lib/src/media/image_processor.dart`
- `lib/src/chat/note.spy.yaml`
- `lib/server.dart`

### Flutter
- `lib/widgets/media_attachment_widget.dart`
- `lib/widgets/image_upload_dialog.dart`
- `lib/widgets/file_upload_dialog.dart` (to create)
- `lib/widgets/document_attachment_widget.dart` (to create)
- `lib/widgets/full_screen_image_view.dart`
- `lib/widgets/chat_view.dart`
- `lib/widgets/note_input.dart`
- `lib/providers/media_provider.dart`

### Infrastructure
- `memoka_server/docker-compose.yaml`
- `migrations/`
