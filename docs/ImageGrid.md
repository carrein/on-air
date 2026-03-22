# Image Grid / Album Feature

Future feature: group multiple images into a single note with a visual grid layout.

## Current State

Each image upload creates a separate note with one `MediaAttachment`. Multi-file drag-and-drop produces N separate notes.

## Target Behavior

- Batch multiple images into a single note (one note, multiple `MediaAttachment` records)
- Render grouped images as a proportional mosaic/grid in the media-only note UI
- Max per group: 10 (following Telegram/Discord convention)

## Industry Reference

| App | Model | Layout | Max |
|---|---|---|---|
| Telegram | One message, album | Proportional mosaic (aspect-ratio-aware) | 10 |
| Discord | One message, mosaic | Mosaic grid (crops to fit) | 10 |
| iMessage | One message, collection | Collage (2-3) / Stack (4+) | No limit |
| Signal | One message, album | Swipeable stack with count | ~32 |
| WhatsApp | Separate bubbles | None (vertical stack) | 30 |
| Slack | One message, attachments | Vertical file cards | 10 |

## Common Grid Patterns

- 1 image: full width
- 2 images: side by side (proportional to aspect ratio)
- 3 images: 1 large + 2 small (1 top full-width, 2 bottom half-width)
- 4 images: 2x2 grid
- 5-10 images: mosaic with rows of 2-3, proportionally sized

Telegram's mosaic algorithm arranges images into rows where each row's images share the same height, with widths proportional to aspect ratios. This is the gold standard.

## Implementation Requirements

### Upload Flow
- Multi-file selection creates one note with multiple attachments (not N notes)
- Upload dialog shows all selected files as a batch
- Sequential upload per file, but all attach to the same note

### Server
- No schema change needed — notes already support `List<MediaAttachment>?`
- Upload route needs a `noteId` parameter to attach additional files to an existing note, or a batch upload mode

### Client Rendering
- Detect multi-attachment media-only notes in `note_item.dart`
- Mosaic layout widget that computes row arrangement from attachment aspect ratios
- Tap individual image to open lightbox at that index
- Timestamp pill overlays the grid (bottom-right of the overall group)

### Notes
- No app offers a user toggle between grouped and individual sending — auto-group is standard
- Note-taking apps (Apple Notes, Google Keep, Notion) do NOT auto-grid; they stack vertically
- Since Memoka is chat-style, the Telegram album model is the best fit
