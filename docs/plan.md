# Memoka Implementation Plan

> **Project**: Real-time chat-style notes application with Serverpod backend and Flutter frontend
>
> **Key Architecture Decisions**:
> - WebSocket streaming via Serverpod's built-in streaming methods + MessageCentral for broadcasting
> - Riverpod for Flutter state management
> - Cursor-based pagination for notes
> - Auto-create "General" channel on server startup
>
> **Security**: See [docs/security.md](./security.md) for security considerations and incident history

---

## Completed Features

**Core Application**
- Server data models and migrations (Channel, Note, ChatEvent, LinkPreview, MediaAttachment, ArchiveItem)
- Chat endpoint with CRUD operations for channels and notes
- Real-time WebSocket streaming via MessageCentral
- Default "General" channel auto-creation
- Backend integration tests
- Riverpod state management setup
- Flutter providers (channels, notes, chat stream, connection, editing, device UUID)
- UI components (ChatScreen, Sidebar, ChatView, InputBar, OfflineBanner)
- Channel management (create, update, delete, pin/unpin, emoji, archive/restore)
- Note management (create, update, delete, pagination, archive/restore)
- Real-time updates across connected clients

**Link Preview Feature**
- Server-side URL detection and metadata fetching
- OpenGraph and Twitter Card support
- Async preview generation with WebSocket broadcast
- Client-side preview card display
- Input bar link detection banner

**Media Upload Feature**
- Image upload (JPEG, PNG, WebP, GIF, HEIC)
- Document upload (PDF, TXT, MD, DOC, DOCX, XLS, XLSX, ZIP)
- Clipboard paste support (Ctrl+V) — intercepts image/video files even when text field is focused
- Drag-and-drop upload support
- Multi-file batch upload with progress dialog
- Compression with WebP conversion (default compress toggle: off)
- Thumbnail generation in isolates
- EXIF metadata stripping (after orientation correction)
- Animated GIF preservation
- UUID-based filenames for security
- Two-phase commit (temp file → DB → atomic rename)
- Public media serving via static routes
- Full-res inline previews (not thumbnails), max display 600x500
- Image-only notes render without white bubble wrapper
- Compressed badge indicator on media attachments
- Full-screen lightbox with gallery navigation (arrows, keyboard, swipe, counter)
- Web media URL uses `Uri.base` origin (works behind reverse proxies)

**UI/UX Features**
- Toast notification system (success/error/info)
- Chat bubbles with consistent styling
- Right-click context menus (Copy/Edit/Delete)
- Per-channel input draft preservation
- Multi-select with bulk delete
- Inter font with 14px note text
- Absolute timestamps with timezone conversion
- Date separators (Today, Yesterday, formatted date)
- Settings overlay with page navigation
- Chat background picker with themed patterns (14 options)
- Shimmer placeholders for media loading (pre-sized from attachment metadata, no layout jumps)
- Fast fade-in (150ms) for disk-cached images to reduce perceived re-loading on scroll
- Custom PWA icons (192, 512, maskable variants) and 32x32 favicon

**Media Sidebar**
- Right sidebar with 4 tabs (Images, Videos, Documents, Links)
- Grid layout for media, list for links
- Responsive behavior (desktop always visible, mobile hidden with menu access)
- Resizable sidebar (250-400px)
- Real-time updates via WebSocket

**Archive System**
- Archive Crate (system channel for archived notes)
- Channel archiving (soft delete with restore)
- Note archiving (move to Archive Crate with original channel tracking)
- Restore functionality for both notes and channels

**Channel Features**
- Smart channel selection (persists last opened channel via SharedPreferences)
- Channel validation on startup with fallback
- Emoji identifiers per channel
- Pin/unpin support
- Drag-to-reorder channels (sortOrder field, ReorderableListView, reorderChannels endpoint)

**Architecture Cleanup**
- Removed unused auth scaffolding (JWT, email IDP, sign-in screen) — ~1500 lines of dead code and 3 unused dependencies

---

## Future Phases

**Enhanced Media**
- Resumable uploads (chunked protocol)
- Full screen image viewer with swipe
- Image editing (crop, rotate)

**Media Gallery**
- Date range filtering
- Media type filtering

**Advanced Features**
- Video support
- Storage analytics dashboard
- Content-based search

---

## References

- Serverpod Docs: https://docs.serverpod.dev/
- Serverpod Streaming: https://docs.serverpod.dev/concepts/streams
- MessageCentral (Server Events): https://docs.serverpod.dev/concepts/server-events
- Riverpod Docs: https://riverpod.dev/
