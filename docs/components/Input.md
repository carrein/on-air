# Input (NoteInput)

## Overview

NoteInput is the note composition component pinned to the bottom of the screen. It handles creating new notes, editing existing notes, link preview detection, per-channel draft persistence, and file uploads (single and multi-file).

**File**: `memoka_flutter/lib/widgets/note_input.dart`
**Widget**: `NoteInput` (ConsumerStatefulWidget)
**State**: `_NoteInputState`

## Subcomponents

### Bar Container

The outer light container holding the text field and action icons.

- Background: `#F6F0ED` (core.surface)
- Top border: 1px `brand.primary` (`#CE2161`)
- Padding: left 10px, top 8px, bottom 8px, right 6px
- Full-width, spans below both the sidebar and content area

### Text Field

The main text input area.

- Fill: transparent (blends with bar background)
- Border: none
- Border radius: 0px (sharp corners)
- Content padding: zero
- Dense mode enabled (`isDense: true`)
- Starts at 1 line (`minLines: 1`), expands up to 8 lines (`maxLines: 8`)
- Text color: `#00171F` (core.text)
- Cursor color: `#CE2161` (brand.primary)
- Placeholder text: "Keyboard goes brrrr..." in `#00171F` at 40% opacity
- Edit mode placeholder: "Edit note... (Shift+Enter for new line)"

### Action Icons (normal mode)

Tappable icons using `IconButtonStyled` with regular Phosphor icons.

- **Camera** (mobile only): `PhosphorIcons.camera()` — opens device camera
  - Fades out with `AnimatedOpacity` + collapses with `AnimatedSize` when text is entered
- **Attachment**: `PhosphorIcons.paperclip()` — opens file picker
  - Zooms out via `AnimatedSwitcher` + `ScaleTransition` when text is entered
- **Send**: `PhosphorIcons.paperPlaneRight()` — submits note
  - Zooms in via `AnimatedSwitcher` + `ScaleTransition` when text is entered
  - Replaces the attachment icon in the same slot

All icons: 24px, `#CE2161` (brand.primary) color.

### Action Icons (edit mode)

Both icons appear on the **right side** of the text field (same position as camera/attachment/send):

- **Cancel**: `IconButtonStyled(icon: PhosphorIcons.xCircle())` — clears field and exits edit mode
- **Save**: `IconButtonStyled(icon: PhosphorIcons.highlighter())` — saves changes; dimmed at 40% opacity when field is empty

### Animation

Icon transitions use 250ms `easeInOut` curves:
- Camera: `AnimatedOpacity` (fade) + `AnimatedSize` (collapse) — disappears when text is entered
- 2px animated gap between camera and attachment collapses with camera
- Attachment/Send: `AnimatedSwitcher` with `ScaleTransition` (zoom swap)

### Link Preview

Appears above the NoteInput when a URL is detected in the text.

- Uses `InputLinkPreview` widget
- Detects first URL via regex matching
- Dismissible by the user
- Hidden in edit mode

### Dialogs (File Upload, Multi-File Upload)

- **Single file**: `FileUploadDialog` with compression option
- **Multi-file**: `MultiFileUploadDialog` for batch uploads
- Both show toast notifications on success/failure

## Styling

### Color Palette

| Token                | Value       | Usage                          |
|----------------------|-------------|--------------------------------|
| `_barBackground`     | `#F6F0ED`   | Bar container background       |
| `_fieldFill`         | transparent | Text field fill (blends with bar) |
| `_borderColor`       | `#CE2161`   | Top border                     |
| `_iconColor`         | `#CE2161`   | All action icons, cursor       |
| `_iconDisabledAlpha` | `0.4`       | Disabled save icon opacity     |
| `_hintTextColor`     | `#00171F`   | Placeholder text color         |
| `_hintTextAlpha`     | `0.4`       | Placeholder text opacity       |

### Typography

| Element    | Size  | Weight | Color                  |
|------------|-------|--------|------------------------|
| Input text | —     | Normal | `#00171F` (core.text)  |
| Hint text  | —     | Normal | `#00171F` @ 40%        |

### Dimensions

| Token                  | Value                          | Usage                      |
|------------------------|--------------------------------|----------------------------|
| `_barPadding`          | L: 10, T: 8, B: 8, R: 6      | Bar container padding      |
| `_fieldContentPadding` | zero                           | Text field inner padding   |
| `_iconGap`             | 2px                            | Gap between field and icons|
| `_fieldBorderRadius`   | 0px                            | Text field corners         |
| `_iconSize`            | 24px                           | Phosphor icon size         |
| Camera-attach gap      | 2px (animated)                 | Gap between camera and attachment |

## Interactions

### Text Input & Submission

- **Enter**: Submits the note (via `Shortcuts`/`Actions` with `SingleActivator(LogicalKeyboardKey.enter)` → `_SubmitIntent`)
- **Shift+Enter**: Inserts a newline naturally (TextField's default multiline behavior)
- Focus is retained after submission for continuous typing
- Text is cleared after successful submit
- Newlines are converted to markdown line breaks (`\n` → `  \n`) on submit

### Icon State Transitions

- **Empty field**: Camera + attachment icons visible, send hidden
- **Text entered**: Camera fades + collapses, attachment zooms out, send zooms in
- **Text cleared**: Reverse animation — send zooms out, attachment zooms in, camera fades in + expands

### Edit Mode

- Triggered externally via `editingNoteProvider`
- Populates the text field with the existing note content
- Field auto-focuses when entering edit mode
- Cancel button (`xCircle`, right side) clears field and exits edit mode
- Save button (`highlighter`, right side) updates the existing note instead of creating a new one
- Both edit mode buttons are on the **right side** of the text field

### Draft Persistence

- On channel switch, the current text is saved as a draft for the previous channel
- On arriving at a channel, any saved draft is loaded into the field
- Drafts are not saved/loaded during edit mode
- Drafts are cleared after a note is successfully sent

### Link Preview Detection

- Extracts the first URL from input text via regex on each keystroke
- Shows `InputLinkPreview` widget above the bar when URL is detected
- Preview can be dismissed by the user
- Preview state resets on submit or cancel

### File Upload

- File picker supports: images (jpg, png, gif, webp, heic), videos (mp4, mov, webm, avi, mkv), documents (pdf, txt, md, doc, docx, xls, xlsx), archives (zip)
- Camera capture on mobile (via `image_picker`)
- Single file: opens `FileUploadDialog` with compression option
- Multiple files: opens `MultiFileUploadDialog` for batch upload
- Current text field content is attached as note text for single file uploads
- Toast notifications for success and failure

## State Management

### Providers Watched (reactive)

| Provider              | Type   | Purpose                              |
|-----------------------|--------|--------------------------------------|
| `editingNoteProvider` | `int?` | Note ID being edited (null = create) |

### Providers Listened (side effects)

| Provider                | Purpose                                |
|-------------------------|----------------------------------------|
| `editingNoteProvider`   | Populate field when entering edit mode |
| `currentChannelProvider`| Save/load drafts on channel switch     |

### Providers Read (on interaction)

| Provider                            | Usage                               |
|-------------------------------------|-------------------------------------|
| `notesProvider(channelId).notifier`  | Create or update notes              |
| `currentChannelProvider`            | Get active channel for submissions  |
| `editingNoteProvider.notifier`      | Cancel editing                      |
| `draftsProvider.notifier`           | Save, load, clear per-channel drafts|
| `mediaUploadProvider.notifier`      | Upload files and create notes       |

### Local Widget State

| Field           | Type                    | Purpose                        |
|-----------------|-------------------------|--------------------------------|
| `_controller`   | `TextEditingController` | Text field content management  |
| `_focusNode`    | `FocusNode`             | Focus control for auto-focus   |
| `_previewUrl`   | `String?`               | Currently detected URL         |
| `_showPreview`  | `bool`                  | Link preview visibility toggle |

## Integration

NoteInput is placed at the bottom of the `ChatScreen` layout. On desktop/web it sits below the main `Row` (channel list + chat + media panel), spanning the content area. On mobile it's the last item in the outermost `Column`. It is hidden when viewing the Archive channel or when settings is open (both are "detail mode").

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/note_input.dart` | This component |
| `lib/widgets/icon_button_styled.dart` | Reusable icon button (camera, send, attach, edit mode) |
| `lib/widgets/input_link_preview.dart` | Link preview widget shown above bar |
| `lib/widgets/file_upload_dialog.dart` | Single file upload dialog |
| `lib/widgets/multi_file_upload_dialog.dart` | Multi-file upload dialog |
| `lib/screens/chat_screen.dart` | Parent layout that hosts the NoteInput |
| `lib/providers/notes_provider.dart` | Note CRUD operations |
| `lib/providers/current_channel_provider.dart` | Active channel for submissions |
| `lib/providers/editing_note_provider.dart` | Edit mode state |
| `lib/providers/drafts_provider.dart` | Per-channel draft persistence |
| `lib/providers/media_provider.dart` | File upload handling |
| `lib/models/upload_file_data.dart` | Upload file data model |
| `lib/utils/toast_utils.dart` | Success/error toast display |
