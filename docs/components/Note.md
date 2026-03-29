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
| `isHighlighted` | `bool` | No (default `false`) | When true, renders a 2px border (instead of 1px) for jump-to-context highlighting |

---

## Layout Structure

```
[Padding H:14px V:6px]
  Row:
    [Checkbox?]  ← visible in selection mode only
    Align(left):
      NoteConstraints (mobile: no constraint, desktop: IntrinsicWidth + ConstrainedBox(minWidth: 350px, maxWidth: 600px)):
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
| Outer padding | H: 14px, V: 6px |
| Min width | 350px (desktop only; mobile: full width) |
| Max width | 600px |
| Footer icon size | 20px |
| Footer icon color | `#00171F` at 50% opacity |

---

---

## Footer Actions

The footer is always visible (no hover state). Icons shown depend on context:

| Icon | Archive mode | Regular mode | Document-only note |
|------|-------------|--------------|-------------------|
| Reminder siren (`siren` fill) | hidden | visible (if reminder set) | visible (if reminder set) |
| Edit (`pencilSimple`) | hidden | visible | hidden |
| Copy (`copySimple`) | visible | visible | hidden |
| Archive/Restore (`archive` / `arrowCounterClockwise`) | restore | archive | archive |
| Share (`shareNetwork`) | visible | visible | visible |

**Document-only notes** (no text content, only document attachments) hide Edit and Copy buttons since there is no text to edit or copy.

All icons: 20px, `Color(0xFF00171F).withValues(alpha: 0.5)`.

---

## Text Selection

`MarkdownBody` has `selectable: kIsWeb`.

- **Mobile**: Text selection is **disabled** so long-press correctly triggers selection mode instead of the OS text-selection handles
- **Web**: Text selection is **enabled** (expected desktop behaviour)

## Markdown Rendering

`MarkdownBody` from `flutter_markdown` with custom builders and styling:

| Feature | Implementation |
|---------|---------------|
| **Emoji** | `:shortcodes:` rendered as Unicode via `md.EmojiSyntax()` inline syntax |
| **Links** | Navy blue (`#0F52BA`), dashed underline, opens in external browser |
| **Horizontal rule** | 2px `core.text` (`#00171F`) top border |
| **Footnotes** | Superscript via OpenType `numr` font feature |
| **Code (inline)** | `#FFFDF6` on `#00171F`, Space Grotesk, 14px, 2px horizontal padding (`_CodePaddingBuilder`) |
| **Code (block)** | Dark header bar with language label + copy button, Space Grotesk 13px body (`_CodeBlockBuilder` / `_CodeBlock`) |
| **Blockquote** | 3px left bar in `#3450A3`, bold 16px text, recursive nesting (`_BlockquoteBuilder`) |
| **Checkboxes** | Interactive Phosphor icons (`checkSquare` / `square`), toggle via regex replacement on note content |
| **Tables** | Notes containing tables skip the max-width constraint (`_wrapConstraints`) |

**Not supported** (flutter_markdown limitation): inline math, raw HTML elements.

---

## Context Menu

- **Desktop**: Right-click (`onPointerDown` with `event.buttons == 2`)
- **Mobile**: Long-press enters selection mode (does NOT show context menu)

Menu options differ by view:

**Regular channel:**
1. Copy — copies content to clipboard, shows toast
2. Edit — populates NoteInput with note content
3. Archive — soft-deletes, broadcasts WebSocket event
4. Explode — splits note into multiple notes (visible when splittable; see below)
5. Select — enters selection mode with this note pre-selected
6. Set Reminder — opens date/time picker, creates reminder on server

**Archive view:**
1. Copy
2. Restore — returns note to original channel
3. Delete — permanently deletes note
4. Select

---

## Combine / Explode

### Combine (Navbar selection bar)

When 2+ notes are selected, the Navbar shows a merge button (`PhosphorIcons.arrowsMerge()`). Online-only.

- Content is concatenated chronologically (newest first, matching chat display order), separated by double newlines
- All attachments from source notes are reassigned to the combined note
- Source notes are tombstoned (`deletedAt` set)
- Rejects notes with reminders or page watches (server validates)
- Broadcasts `noteCreated` for the combined note + `noteDeleted` for each source
- Link preview is fetched asynchronously for the combined note

### Explode (Context menu)

Visible when a note can be split into 2+ pieces (text segments split on `\n\n` + individual attachments). Online-only.

- Each text segment becomes its own note
- Each attachment becomes its own note (empty content)
- Original note is tombstoned
- Rejects notes with reminders or page watches (server validates)
- Broadcasts `noteCreated` for each new note + `noteDeleted` for the original
- Link previews fetched asynchronously for text notes

Both operations are transactional — all-or-nothing with a single `incrementGlobalVersion` call.

---

## Justified Media Grid

When a note has 2+ visual media attachments (images/videos), they are rendered in a justified-row grid (Google Photos style) instead of stacked vertically.

- **Algorithm**: Greedy row-filling — items are added to a row until the row height drops to/below `targetRowHeight` (150px). Last row is balanced by stealing from the previous row if too tall (>1.5x target).
- **Aspect ratios**: Computed from attachment `width`/`height` metadata; defaults to 1.0 if missing
- **Flex sizing**: Each cell uses `Flexible(flex:)` with width-proportional flex values to avoid floating-point drift
- **Shimmer**: Image cells show `ShimmerPlaceholder` until loaded
- **Videos in grid**: Show thumbnail with play button overlay; tap handler is currently a no-op (video lightbox not yet integrated for grid cells)
- **Non-visual media**: Documents and audio are always rendered as individual `MediaAttachmentWidget`s below the grid
- **IntrinsicWidth workaround**: Card notes on desktop are wrapped in `IntrinsicWidth` + `ConstrainedBox`. `LayoutBuilder` cannot answer intrinsic-dimension queries, so the grid accepts an optional `precomputedWidth` parameter to bypass `LayoutBuilder` in that context.

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
| `_ReminderSiren` | Reminder siren icon display (batch via `channelRemindersProvider`) |
| `_PageWatchBell` | Page watch bell icon (batch via `channelPageWatchesProvider` — 1 RPC per channel) |
| `channelPageWatchesProvider` | All page watches for a channel (avoids N per-note fetches) |
| `channelRemindersProvider` | All reminders for a channel (avoids N per-note fetches) |
| `pageWatchProvider` | Per-note watch state (used for mutations only) |
| `reminderProvider` | Per-note reminder state (used for mutations only) |

---

## Related Files

| File | Purpose |
|------|---------|
| `lib/widgets/note_item.dart` | Widget implementation |
| `lib/providers/note_selection_provider.dart` | Selection state |
| `lib/providers/editing_note_provider.dart` | Edit state |
| `lib/widgets/media_attachment_widget.dart` | Media rendering |
| `lib/widgets/link_preview_card.dart` | Link preview card |
| `lib/providers/reminder_provider.dart` | Reminder state per note |
| `docs/DesignSystem.md` | Color and typography tokens |
