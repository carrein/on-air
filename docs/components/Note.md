# Note

Individual note card widget that renders note content, footer actions, context menu, and selection mode UI.

**Source**: `memoka_flutter/lib/widgets/note_item.dart`

---

## Overview

`NoteItem` is a `ConsumerWidget` that displays a single note in the chat view. It handles:

- Markdown-formatted text content
- Media attachments (images, videos, audio, documents)
- Link preview cards
- Footer action icons (copy, edit, archive/restore, share)
- Right-click / long-press context menu
- Selection mode (checkbox toggle)

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
[Padding 14px all sides]
  Row:
    [Checkbox?]  ← visible in selection mode only
    Align(left):
      IntrinsicWidth:
        ConstrainedBox(minWidth: 300px, maxWidth: 600px):
          [Context Menu Wrapper]
            [Card with border — always]
              Column:
                [Text content (Markdown)?]
                [12px gap if next section present]
                [MediaAttachmentWidget(s)?]
                [12px gap between attachments]
                [12px gap if next section present]
                [LinkPreviewCard?]
                [12px gap]
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
| Gap between content sections | 12px |
| Gap between footer and content | 12px |
| Outer padding | 14px all sides |
| Min width | 350px |
| Max width | 600px |
| Footer icon size | 20px |
| Footer icon color | `#00171F` at 50% opacity |

---

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

## Text Selection

`MarkdownBody` has `selectable: kIsWeb`.

- **Mobile**: Text selection is **disabled** so long-press correctly triggers selection mode instead of the OS text-selection handles
- **Web**: Text selection is **enabled** (expected desktop behaviour)

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
