# Media Upload and Storage

Plan for supporting media uploads (images, future: videos, files) in the chat application.

## Overview

### Phase 1 (Current): Image Upload
- Paste images from clipboard (Ctrl+V)
- Upload dialog with compression option
- Display inline in chat messages
- No captions required

### Future Phases
- Media gallery tab per channel
- Search and filter by date/type
- Video support
- File attachments (PDFs, documents)

---

## Architecture

### Storage Strategy

**File System Layout:**
```
/data/media/
├── channels/
│   ├── {channel_id}/
│   │   ├── {note_id}_{timestamp}_{hash}.jpg
│   │   ├── {note_id}_{timestamp}_{hash}.webp
│   │   └── thumbnails/
│   │       └── {note_id}_{timestamp}_{hash}_thumb.webp
```

**Key Decisions:**
1. **Use channel ID (not name)** - Avoids brittleness from channel renames
2. **Include note ID in filename** - Easy to associate files with notes
3. **Add timestamp and hash** - Prevents collisions, enables sorting
4. **Separate thumbnails directory** - Organized, easy to regenerate
5. **WebP for compressed** - Better compression than JPEG, wide support

**Docker Volume Binding:**
```yaml
services:
  on_air_server:
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
  
  # Redundant channelId for easier querying
  channelId: int, relation(parent=channels, onDelete=Cascade)
  
  # Storage path (relative to media root)
  filePath: String  # e.g., "channels/123/456_1234567890_abc123.jpg"
  
  # Original filename from upload
  originalFilename: String
  
  # MIME type
  mimeType: String  # e.g., "image/jpeg", "image/png"
  
  # File metadata
  fileSize: int  # bytes
  width: int?
  height: int?
  
  # Thumbnail path (if generated)
  thumbnailPath: String?
  
  # Compression flag
  compressed: bool, default=false
  
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

**Benefits of this approach:**
- Foreign keys ensure referential integrity
- Cascading deletes: delete note → delete attachments + files
- Efficient queries: `WHERE channelId = ? ORDER BY uploadedAt DESC`
- Future gallery view: join on channelId with pagination

**File Cleanup Strategy:**
- Database triggers or scheduled job to delete orphaned files
- When note is deleted, cascade deletes attachments, then cleanup files

---

## Upload Flow

### 1. Client-Side (Flutter)

**Paste Detection:**
```dart
// In ChatView or InputBar
onKeyEvent: (event) {
  if (event is KeyDownEvent && 
      event.logicalKey == LogicalKeyboardKey.keyV &&
      HardwareKeyboard.instance.isControlPressed) {
    _handlePaste();
  }
}

Future<void> _handlePaste() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  // Check for image data
  final imageData = await Clipboard.getImage(); // hypothetical
  if (imageData != null) {
    _showImageUploadDialog(imageData);
  }
}
```

**Upload Dialog:**
- Preview image (actual size or scaled down)
- Checkbox: "Compress image" (checked by default)
  - Full size: Original image
  - Compressed: Resize to max 1920px, quality 85%, WebP format
- Buttons: "Cancel" | "Send"

**Upload Process:**
```dart
1. Show dialog with image preview
2. User selects compression option
3. Compress image if selected (using image package)
4. Call server endpoint: POST /api/chat/upload-media
   - multipart/form-data
   - fields: channelId, compress, file
5. Server returns MediaAttachment metadata
6. Create note with attachment reference
7. Close dialog, display in chat
```

### 2. Server-Side (Serverpod)

**New Endpoint: MediaEndpoint**

```dart
class MediaEndpoint extends Endpoint {
  Future<MediaAttachment> uploadMedia(
    Session session,
    int channelId,
    bool compress,
    ByteData fileData,
    String filename,
    String mimeType,
  ) async {
    // 1. Validate file type (image/jpeg, image/png, image/webp)
    // 2. Generate unique filename
    // 3. Create directory if not exists
    // 4. Save file to disk
    // 5. If compress: resize and convert to WebP
    // 6. Generate thumbnail (300px wide)
    // 7. Extract image dimensions
    // 8. Create MediaAttachment record
    // 9. Return metadata
  }
  
  Future<void> deleteMedia(Session session, int attachmentId) async {
    // 1. Fetch attachment
    // 2. Delete files from disk
    // 3. Delete database record
  }
}
```

**File Naming Convention:**
```dart
String generateFilename(int noteId, String originalFilename) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final hash = _generateHash(originalFilename + timestamp.toString());
  final ext = path.extension(originalFilename);
  return '${noteId}_${timestamp}_$hash$ext';
}
```

**Image Processing:**
- Use `image` package for Dart
- Resize if > 1920px on longest side
- Convert to WebP with quality 85
- Generate thumbnail: 300px wide, WebP

**Serving Files:**
Two options:

**Option A: Static Route (Recommended)**
```dart
// In server.dart
pod.webServer.addRoute(
  Route.get('/media/<channel>/<filename>'),
  (request, channel, filename) async {
    final filePath = '/app/media/channels/$channel/$filename';
    final file = File(filePath);
    if (!await file.exists()) return Response.notFound();
    
    final bytes = await file.readAsBytes();
    final mimeType = lookupMimeType(filename);
    return Response.ok(
      bytes,
      headers: {'Content-Type': mimeType},
    );
  },
);
```

**Option B: Endpoint**
```dart
Stream<List<int>> getMedia(Session session, String filePath) async* {
  // Stream file bytes
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
        
        // Media attachments
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
```dart
class MediaAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: Container(
        margin: EdgeInsets.only(top: 8),
        child: ClipRRectangle(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: '/media/${attachment.filePath}',
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              height: 200,
              color: Colors.grey[200],
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showFullScreen(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => FullScreenImageView(attachment: attachment),
    ));
  }
}
```

---

## Future Extensibility

### Media Gallery Tab

**UI Design:**
- Tab in channel view (beside chat)
- Grid layout of image thumbnails
- Click to open full screen
- Filter by date range
- Sort by newest/oldest

**Backend:**
```dart
class MediaEndpoint extends Endpoint {
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
  
  Future<int> getMediaCount(Session session, int channelId) async {
    return await MediaAttachment.db.count(
      session,
      where: (t) => t.channelId.equals(channelId),
    );
  }
}
```

### Search and Filter

**Backend Indexing:**
```yaml
# In media_attachment.spy.yaml
indexes:
  channel_date_idx:
    fields: channelId, uploadedAt
  channel_type_idx:
    fields: channelId, mimeType, uploadedAt
```

**Search Endpoint:**
```dart
Future<List<MediaAttachment>> searchMedia(
  Session session,
  int channelId,
  String? mimeTypePrefix,  // e.g., "image/", "video/"
  DateTime? startDate,
  DateTime? endDate,
) async {
  // Efficient query using indexes
}
```

### Storage Quota and Limits

**Per-Channel Quotas:**
```yaml
# In channel.spy.yaml
fields:
  mediaStorageUsed: int, default=0  # bytes
  mediaStorageLimit: int, default=10737418240  # 10GB
```

**Enforce on Upload:**
```dart
Future<MediaAttachment> uploadMedia(...) async {
  final channel = await Channel.db.findById(session, channelId);
  
  if (channel.mediaStorageUsed + fileSize > channel.mediaStorageLimit) {
    throw Exception('Storage quota exceeded');
  }
  
  // Upload...
  
  // Update quota
  channel.mediaStorageUsed += fileSize;
  await Channel.db.updateRow(session, channel);
}
```

---

## Security Considerations

### File Upload Validation
- Validate file type (whitelist MIME types)
- Limit file size (e.g., 25MB per image)
- Sanitize filenames
- Validate image dimensions

### Access Control
- Check user has access to channel before upload
- Check user has access to channel before serving media
- Use session authentication for all media endpoints

### Path Traversal Prevention
```dart
// Validate filename doesn't contain path traversal
if (filename.contains('..') || filename.contains('/')) {
  throw Exception('Invalid filename');
}
```

---

## Dependencies

### Server
```yaml
dependencies:
  serverpod: 3.2.3
  image: ^4.0.0  # Image processing
  mime: ^1.0.0   # MIME type detection
  path: ^1.8.0   # Path utilities
```

### Flutter
```yaml
dependencies:
  image_picker: ^1.0.0  # For paste support
  cached_network_image: ^3.4.1  # Already added
  photo_view: ^0.14.0  # Full screen image viewer
  flutter_image_compress: ^2.1.0  # Client-side compression
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

## Implementation Phases

### Phase 1: Basic Image Upload (MVP)
1. Create MediaAttachment model
2. Update Note model with attachments field
3. Create media directory structure
4. Implement upload endpoint
5. Add paste detection in Flutter
6. Create upload dialog UI
7. Implement image compression
8. Display images in chat
9. Serve images via static route

### Phase 2: Enhanced Display
1. Full screen image viewer
2. Image loading indicators
3. Error handling for failed loads
4. Retry mechanism

### Phase 3: Media Gallery
1. Create gallery tab UI
2. Implement grid layout
3. Add pagination
4. Implement filtering

### Phase 4: Additional Features
1. Multiple image upload
2. Drag and drop support
3. Image editing (crop, rotate)
4. Video support
5. File attachments

---

## Performance Considerations

### Thumbnail Strategy
- Generate on upload (blocking)
- Or generate on first access (lazy, cache)
- Store in separate directory for easy management

### Caching
- Client: CachedNetworkImage handles HTTP caching
- Server: Set cache headers on static routes
  ```dart
  headers: {
    'Cache-Control': 'public, max-age=31536000',  // 1 year
  }
  ```

### Image Optimization
- WebP format (30% smaller than JPEG)
- Progressive loading (thumbnail → full)
- Lazy loading in gallery view
- CDN for future scaling (optional)

---

## Testing Strategy

### Unit Tests
- File upload validation
- Filename generation
- Image compression
- Path sanitization

### Integration Tests
```dart
withServerpod('Given MediaEndpoint', (sessionBuilder, endpoints) {
  test('when uploading valid image then should save and return metadata', () async {
    final imageBytes = await File('test/fixtures/test.jpg').readAsBytes();
    final attachment = await endpoints.media.uploadMedia(
      sessionBuilder,
      channelId: 1,
      compress: true,
      fileData: ByteData.view(imageBytes.buffer),
      filename: 'test.jpg',
      mimeType: 'image/jpeg',
    );
    
    expect(attachment.filePath, isNotEmpty);
    expect(File('/app/media/${attachment.filePath}').existsSync(), true);
  });
});
```

### Manual Testing Checklist
- [ ] Paste image (Ctrl+V)
- [ ] Upload with compression
- [ ] Upload without compression
- [ ] Display in chat
- [ ] Click to view full screen
- [ ] Delete note with attachment (files cleaned up)
- [ ] Large image (>10MB)
- [ ] Invalid file type
- [ ] Network error during upload

---

## Open Questions

1. **Max file size limit?** Suggestion: 25MB for images
2. **Storage quota per channel?** Suggestion: 10GB default
3. **Auto-delete old media?** Optional retention policy
4. **Support GIFs?** Yes, treat as images
5. **Support multiple images per note?** Yes, list of attachments
6. **Allow editing uploaded images?** Phase 2 feature

---

## Related Files

### Server
- `lib/src/media/media_attachment.spy.yaml` (new)
- `lib/src/media/media_endpoint.dart` (new)
- `lib/src/chat/note.spy.yaml` (update)
- `lib/server.dart` (add static route)

### Flutter
- `lib/widgets/media_attachment_widget.dart` (new)
- `lib/widgets/image_upload_dialog.dart` (new)
- `lib/widgets/full_screen_image_view.dart` (new)
- `lib/widgets/chat_view.dart` (update)
- `lib/providers/media_provider.dart` (new)

### Infrastructure
- `on_air_server/docker-compose.yaml` (add volume)
- `migrations/` (new migration for media_attachments table)

---

## ✅ Confirmed Decisions

### File Size & Storage
- **No max file size limit** - Allow any size uploads
- **No storage quotas** - Unlimited storage per channel
- **Rationale:** Self-hosted server with sufficient storage capacity

### Compression Settings
- **Default:** Compression checkbox **checked** by default
- **Compressed:** Max 1920px, WebP format, 85% quality
- **Original:** Keep original if user unchecks compression
- **Thumbnails:** 300px wide, WebP format

### Supported Formats (Phase 1)
- **JPEG** - Convert to WebP if compressed
- **PNG** - Convert to WebP if compressed (preserves transparency)
- **WebP** - Native support
- **GIF** - Convert to static WebP (first frame for thumbnail)
- **HEIC** (iPhone) - Convert to WebP

### Upload Behavior
- **Single image per paste** - One at a time (multi-paste in future phase)
- **Paste priority:** If clipboard has image, ignore text
- **Progress indicator:** Show for uploads >2MB
- **Error handling:** Toast message + retry button

### Display & Interaction
- **Delete:** Delete entire note to remove images (no individual image delete yet)
- **Full screen:** Click image to open full screen viewer
- **Loading:** Show placeholder while loading
- **Failed load:** Show broken image icon with retry option

### Security & Privacy
- **Auth required:** Yes - check session before upload/download
- **Channel access:** Verify user can post to channel
- **EXIF stripping:** Remove GPS and personal metadata on upload
- **File validation:** Decode image on server to ensure valid file

### Real-time Updates
- **WebSocket broadcast:** Yes - broadcast `noteCreated` with attachment
- **Live preview:** Other users see images immediately
- **Thumbnail generation:** Generate before broadcasting (blocking)

---

## 🔧 Additional Technical Decisions

### Image Processing
- **Max dimensions:** No server-side limit (client validates reasonableness)
- **Aspect ratio:** No restrictions
- **Orientation:** Auto-rotate based on EXIF before stripping
- **Transparency:** Preserve PNG/WebP alpha channel, display on white background

### File Naming
- **Hash algorithm:** SHA256 (more secure than MD5)
- **Collision handling:** Regenerate with new timestamp (astronomically unlikely)
- **Format:** `{note_id}_{timestamp}_{hash}.{ext}`

### Error Handling
- **Upload timeout:** 60 seconds (generous for large files)
- **Retry strategy:** Manual retry button (no auto-retry)
- **Network errors:** Show clear error message with details
- **Server errors:** Display server error message

### Rate Limiting (Optional - Add if Needed)
- **Not implemented initially** - Add if spam becomes an issue
- **Future:** 20 uploads per minute per user

### Cleanup Strategy
- **Orphaned files:** Database cascade delete handles most cases
- **Backup cleanup:** Daily cron job at 3am to find/remove orphaned files
- **Manual command:** `serverpod cleanup-media` for manual cleanup

---

## 📐 Deferred Features (Phase 2+)

### Not in Initial Implementation
- ❌ Multiple images per paste (one at a time for now)
- ❌ Individual image deletion (delete note to delete images)
- ❌ Drag and drop upload
- ❌ Mobile camera integration
- ❌ Image editing (crop, rotate, filters)
- ❌ Animated GIF support (convert to static)
- ❌ Multiple image sizes (original + thumbnail only)
- ❌ Video support
- ❌ File attachments (PDFs, documents)
- ❌ Image search by content
- ❌ Storage analytics dashboard

### Phase 2 Candidates
- Multiple images per note (upload queue)
- Animated GIF preservation
- Image editing before send
- Download original button
- Gallery view with filters

### Phase 3+ Ideas
- Video attachments
- File attachments
- Voice messages
- Screen recording
- OCR for text in images
- Image-based search
