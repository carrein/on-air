# Image Grid / Album Feature

Justified media grid for multi-attachment notes, rendering images/videos in proportional rows (Google Photos / Telegram album style).

## Current State

**Implemented** in `note_item.dart` via `_buildJustifiedMediaGrid()`. Multi-file uploads already create one note with multiple `MediaAttachment` records.

### What Works
- Notes with 2+ visual media attachments (images/videos) render as a justified row grid
- Greedy row-filling algorithm: items fill rows until row height drops to target (150px)
- Last row balancing: steals from previous row if last row is too tall (>1.5x target)
- Aspect ratios from attachment metadata; falls back to 1:1 if missing
- Shimmer placeholders during image load
- Image tap opens full-screen lightbox at correct gallery index
- Media-only notes (no text) and mixed notes (text + media) both support the grid
- Non-visual media (documents, audio) rendered individually below the grid
- `precomputedWidth` parameter handles IntrinsicWidth ancestor constraint on desktop

### Known Limitations
- **Video tap in grid is a no-op** — grid cells render thumbnail + play overlay but tapping does nothing (VideoAttachmentWidget's lightbox not integrated into grid cells)
- No drag-to-reorder within an album
- No max-per-group limit enforced

## Industry Reference

| App | Model | Layout | Max |
|---|---|---|---|
| Telegram | One message, album | Proportional mosaic (aspect-ratio-aware) | 10 |
| Discord | One message, mosaic | Mosaic grid (crops to fit) | 10 |
| iMessage | One message, collection | Collage (2-3) / Stack (4+) | No limit |
| Signal | One message, album | Swipeable stack with count | ~32 |
| WhatsApp | Separate bubbles | None (vertical stack) | 30 |
| Slack | One message, attachments | Vertical file cards | 10 |

## Implementation Details

### Grid Algorithm (`_computeRows`)

1. Iterate attachments, accumulating aspect ratio sum per row
2. When row height (`containerWidth / sumAR`) drops to/below `targetRowHeight` (150px), close the row
3. After partitioning, balance: while last row height > 1.5x target and previous row has >1 item, steal one item
4. `_finalizeRow`: assigns exact pixel widths; last cell gets the remainder to prevent floating-point overflow

### Rendering (`_buildGridCell`)

- Images: `Image.network` with `BoxFit.cover`, shimmer placeholder via `frameBuilder`
- Videos: thumbnail (or grey fallback) + centered play icon overlay (white circle, brand blue icon)
- Each cell wrapped in `GestureDetector` + `ClipRect` + `SizedBox.expand`

### Width Measurement

- **Media-only notes** (no IntrinsicWidth ancestor): uses `LayoutBuilder` to measure available width
- **Card notes** (IntrinsicWidth ancestor on desktop): caller passes `precomputedWidth` computed from screen dimensions and padding, bypassing `LayoutBuilder`

## Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/note_item.dart` | Grid implementation (`_buildJustifiedMediaGrid`, `_computeRows`, `_buildGridCell`, `_GridCell`) |
| `lib/widgets/full_screen_image_view.dart` | Lightbox opened on image tap |
| `lib/utils/file_utils.dart` | `buildMediaUrl`, `buildThumbnailUrl` |
