# Note

Individual note card widget that renders note content, footer actions, context menu, and selection mode UI.

**Source**: `memoka_flutter/lib/widgets/note_item.dart`

---

## Overview

`NoteItem` is a `ConsumerWidget` that displays a single note in the chat view. It handles:

- Markdown-formatted text content
- Media attachments (images, videos, documents)
- Link preview cards
- Footer action icons (copy, edit, archive/restore, share)
- Right-click / long-press context menu
- Selection mode (checkbox toggle)
- Media-only notes (no card wrapper)

---

## Props

| Prop | Type | Required | Description |
|------|------|----------|-------------|
| `note` | `Note` | Yes | The note data to display |
| `channelId` | `int` | Yes | Parent channel ID (for API calls) |
| `allImageUrls` | `List<String>` | No (default `[]`) | All image URLs in the current chat, used for lightbox gallery navigation |

---

## Layout Structure

```
[Padding 14px horizontal, 6px vertical]
  Row:
    [Checkbox?]  ← visible in selection mode only
    Expanded:
      Align(left):
        ConstrainedBox(maxWidth: 680px):
          [Context Menu Wrapper]
            [Media-only: bare content, no card]
            [Regular: Card with border]
              Column:
                [Text content (Markdown)]
                [MediaAttachmentWidget(s)]
                [LinkPreviewCard?]
            [Note Footer]
```

---

## Styling

All values follow `docs/DesignSystem.md` tokens.

| Element | Value |
|---------|-------|
| Card background | `#F6F0ED` (core.surface) |
| Card border | 1px `#CE2161` (brand.primary) |
| Card border radius | 0px |
| Card padding | 12px all sides |
| Outer horizontal padding | 14px |
| Outer vertical padding | 6px between cards |
| Max width | 680px (fixed) |
| Footer icon size | 20px |
| Footer icon color | `#00171F` at 50% opacity |

---

## Media-Only Notes

If a note has **attachments but no text content**, `isMediaOnly()` returns `true` and the card border/background is omitted — the media and footer render without a container, floating directly in the chat background.

```dart
static bool isMediaOnly(Note note) {
  if (note.content.isNotEmpty) return false;
  final attachments = note.attachments;
  if (attachments == null || attachments.isEmpty) return false;
  return true;
}
```

---

## Footer Actions

The footer is always visible (no hover state). Icons shown depend on context:

| Icon | Archive mode | Regular mode |
|------|-------------|--------------|
| Edit (`pencilSimple`) | hidden | visible |
| Copy (`copySimple`) | visible | visible |
| Archive/Restore (`archive` / `arrowCounterClockwise`) | restore | archive |
| Share (`shareNetwork`) | visible | visible |

All icons: 20px, `Color(0xFF00171F).withValues(alpha: 0.5)`.

---

## Context Menu

- **Desktop**: Right-click (`onPointerDown` with `event.buttons == 2`)
- **Mobile**: Long-press enters selection mode (does NOT show context menu)

Menu options differ by view:

**Regular channel:**
1. Copy — copies content to clipboard, shows toast
2. Edit — populates NoteInput with note content
3. Archive — soft-deletes, broadcasts WebSocket event
4. Select — enters selection mode with this note pre-selected

**Archive view:**
1. Copy
2. Restore — returns note to original channel
3. Delete — permanently deletes note
4. Select

---

## Selection Mode

When `noteSelectionProvider` is non-empty, the widget renders in selection mode:

- A `PhosphorIcons.circle()` (unselected) or `PhosphorIcons.checkCircle()` (selected) appears at 24px, `#CE2161`, to the left of the note
- Tapping the note (or checkbox) toggles `noteSelectionProvider` for this note's ID
- Long-press in selection mode also toggles (does not re-enter selection mode)

---

## Dependencies

| Dependency | Purpose |
|------------|---------|
| `noteSelectionProvider` | Selection mode state (Set of selected note IDs) |
| `editingNoteProvider` | Sets note to edit in NoteInput |
| `notesProvider` | Archive / restore / delete operations |
| `LinkPreviewCard` | Renders link preview metadata |
| `MediaAttachmentWidget` | Routes to image/video/document widget by MIME type |

---

## Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/note_item.dart` | Widget implementation |
| `lib/providers/note_selection_provider.dart` | Selection state |
| `lib/providers/editing_note_provider.dart` | Edit state |
| `lib/widgets/media_attachment_widget.dart` | Media rendering |
| `lib/widgets/link_preview_card.dart` | Link preview card |
| `docs/DesignSystem.md` | Color and typography tokens |
