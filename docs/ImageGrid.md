# Image Grid / Album Feature

Justified media grid for multi-attachment notes, rendering images/videos in proportional rows (Google Photos / Telegram album style).

## Current State

**Implemented** in `note_item.dart` via `_buildJustifiedMediaGrid()` and shared algorithm in `grid_layout_utils.dart`. Multi-file uploads already create one note with multiple `MediaAttachment` records.

### What Works
- Notes with 2+ visual media attachments (images/videos) render as a justified row grid
- **"Grow width, then wrap" algorithm**: starts with all items in 1 row at target height, grows note width as needed, wraps to more rows only when cells would be too small at max width
- **Dynamic note width on all platforms** (mobile AND desktop): media-only notes shrink to natural width when images are narrow, instead of spanning full container width. Clamped to [200px, maxAvailableWidth]
- No arbitrary items-per-row cap — algorithm figures out optimal row count
- Heavier rows first for uneven splits (e.g., 5 items → [3, 2])
- Aspect ratios from attachment metadata; falls back to 1:1 if missing
- Shimmer placeholders during image load
- Image tap opens full-screen lightbox at correct gallery index
- Media-only notes (no text) and mixed notes (text + media) both support the grid
- Non-visual media (documents, audio) rendered individually below the grid
- `precomputedWidth` parameter handles IntrinsicWidth ancestor constraint on desktop
- Upload dialog uses same shared algorithm for consistent preview

### Known Limitations
- **Video tap in grid is a no-op** — grid cells render thumbnail + play overlay but tapping does nothing (VideoAttachmentWidget's lightbox not integrated into grid cells)
- No drag-to-reorder within an album

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

### Grid Algorithm (`grid_layout_utils.dart`)

**`computeLayout(aspectRatios, {maxWidth, targetRowHeight, minWidth, minCellDim})`**

"Grow width, then wrap" algorithm:
1. Start with all items in 1 row at `targetRowHeight` → compute natural width
2. Compute required width so every cell's smallest dimension (width for portrait, height for landscape) meets `minCellDim`
3. Note width = max(naturalWidth, requiredWidth). If requiredWidth drove the expansion (portrait images), snap to full `maxWidth` to avoid awkward intermediate widths
4. If needed width > `maxWidth`, check cells at `maxWidth`. If acceptable, use `maxWidth`
5. If not, try 2 rows, 3 rows, etc. (balanced partition, heavier first) until cells fit or all stacked

Returns `GridLayout` with `rowCounts` and `width` (the dynamic note width).

**`finalizeRows(aspectRatios, rowCounts, containerWidth)`**

Converts partition into pixel-exact cell dimensions. Last cell in each row absorbs floating-point remainder to prevent overflow.

### Constants

| Constant | Value | Purpose |
|----------|-------|---------|
| `kTargetRowHeight` | 150px | Target row height for dynamic width calc |
| `kMinDynamicWidth` | 200px | Min note width for dynamic sizing |
| `kMinCellDimension` | 130px | Min acceptable cell dimension (width or height) before expanding or wrapping |

### Rendering (`_buildGridCell`)

- Images: `Image.network` with `BoxFit.cover`, shimmer placeholder via `frameBuilder`
- Videos: thumbnail (or grey fallback) + centered play icon overlay (white circle, brand blue icon)
- Each cell wrapped in `GestureDetector` + `ClipRect` + `SizedBox.expand`

### Width Measurement

- **Media-only notes on mobile**: `computeLayout` with `maxWidth = screenWidth - 28`, wrapped in `SizedBox(width: layout.width)`
- **Media-only notes on desktop**: `LayoutBuilder` gives full available channel width as `maxWidth` (no 600px cap), wrapped in `SizedBox(width: layout.width)`
- **Card notes** (IntrinsicWidth ancestor on desktop): caller passes `precomputedWidth` computed from screen dimensions and padding, bypassing `LayoutBuilder`

## Related Files

| File | Purpose |
|------|---------|
| `lib/utils/grid_layout_utils.dart` | Shared layout algorithm (`computeLayout`, `finalizeRows`) |
| `lib/widgets/note_item.dart` | Grid rendering (`_buildJustifiedMediaGrid`, `_buildGridContent`, `_buildGridCell`, `_GridCell`) |
| `lib/widgets/multi_file_upload_dialog.dart` | Upload preview grid (uses shared algorithm) |
| `lib/widgets/full_screen_image_view.dart` | Lightbox opened on image tap |
| `lib/utils/file_utils.dart` | `buildMediaUrl`, `buildThumbnailUrl` |
