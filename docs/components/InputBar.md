# InputBar

## Overview

The InputBar is the note composition component at the bottom of the chat view. It handles creating new notes, editing existing notes, link preview detection, per-channel draft persistence, and file uploads (single and multi-file).

**File**: `memoka_flutter/lib/widgets/input_bar.dart`
**Widget**: `InputBar` (ConsumerStatefulWidget)
**State**: `_InputBarState`

## Subcomponents

### Bar Container

The outer dark container holding the text field and action icons.

- Background: `core.background` (#00171F)
- Padding: 12px uniform
- Border: 1px `brand.accent` (#FF52A1) on left and right sides
- Full-width, pinned to the bottom of the chat view

### Text Field

The main text input area.

- Fill: `core.surface` (white)
- Border radius: 0px (sharp corners)
- Content padding: 12px uniform
- Starts at 1 line (`minLines: 1`), expands up to 8 lines (`maxLines: 8`)
- Placeholder text: "Keyboard goes brrrr..." in `brand.accent` (#FF52A1) at full opacity
- Edit mode placeholder: "Edit note... (Shift+Enter for new line)"
- Uses `TextInputAction.none` to disable default Enter behavior

### Attachment Button

File upload trigger (hidden in edit mode).

- Custom SVG icon (`attachment.svg`) at 28px
- Uses original SVG colors (no recoloring)
- Opens system file picker on tap
- Supports multiple file selection

### Send Button

Submit trigger for creating/updating notes.

- **Normal mode**: Custom SVG icon (`send.svg`) at 28px, original colors
- **Edit mode**: Material `Icons.check` in `brand.accent` (#FF52A1)
- **Disabled state**: 40% opacity when text field is empty
- Disabled when text is empty (onPressed: null)

### Cancel Button (edit mode only)

Shown when editing an existing note.

- Material `Icons.close` in `brand.accent` at 40% opacity
- Cancels edit mode and clears the field

### Link Preview

Appears above the input bar when a URL is detected in the text.

- Uses `InputLinkPreview` widget
- Detects first URL via regex matching
- Dismissible by the user
- Hidden in edit mode

### Tooltips

Custom-styled tooltips on all icon buttons.

- Background: white
- Text: `core.background` (#00171F) in Space Grotesk at 12px
- Border: 1px `brand.accent` (#FF52A1)
- Border radius: 0 (sharp corners)
- Padding: 8px vertical, 12px horizontal
- Labels: "Upload file", "Send", "Save", "Cancel"

### Dialogs (File Upload, Multi-File Upload)

- **Single file**: `FileUploadDialog` with compression option
- **Multi-file**: `MultiFileUploadDialog` for batch uploads
- Both show toast notifications on success/failure

## Styling

### Color Palette

| Token                | Value       | Theme Token        | Usage                          |
|----------------------|-------------|--------------------|--------------------------------|
| `_barBackground`     | `#00171F`   | `core.background`  | Bar container background       |
| `_fieldFill`         | `#FFFFFF`   | `core.surface`     | Text field fill                |
| `_iconColor`         | `#FF52A1`   | `brand.accent`     | Icons, borders, hint text      |
| `_iconDisabledAlpha` | `0.4`       | —                  | Disabled icon/send opacity     |
| `_hintTextColor`     | `#FF52A1`   | `brand.accent`     | Placeholder text color         |
| `_tooltipBackground` | `#00171F`   | `core.background`  | Tooltip text color             |

### Typography

| Element          | Font           | Size  | Weight  | Color                   |
|------------------|----------------|-------|---------|-------------------------|
| Input text       | Space Grotesk  | 14px  | Normal  | Default (dark on white) |
| Hint text        | Space Grotesk  | 14px  | Normal  | `#FF52A1` @ 100%        |
| Tooltip text     | Space Grotesk  | 12px  | Normal  | `#00171F`               |

### Dimensions

| Token                  | Value          | Usage                      |
|------------------------|----------------|----------------------------|
| `_barPadding`          | 12px uniform   | Bar container padding      |
| `_fieldContentPadding` | 12px uniform   | Text field inner padding   |
| `_iconGap`             | 8px            | Gap between field and icons|
| `_fieldBorderRadius`   | 0px            | Text field corners         |
| `_iconSize`            | 28px           | Attachment/send SVG size   |

## Interactions

### Text Input & Submission

- **Enter**: Submits the note (calls `_submit()`)
- **Shift+Enter**: Inserts a newline (manually via `RawKeyboardListener`, text field expands)
- Focus is retained after submission for continuous typing
- Text is cleared after successful submit
- Newlines are converted to markdown line breaks (`\n` → `  \n`) on submit

### Edit Mode

- Triggered externally via `editingNoteProvider`
- Populates the text field with the existing note content
- Field auto-focuses when entering edit mode
- Cancel button clears field and exits edit mode
- Submit updates the existing note instead of creating a new one

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
- Single file: opens `FileUploadDialog` with compression option
- Multiple files: opens `MultiFileUploadDialog` for batch upload
- Current text field content is attached as note text for single file uploads
- Toast notifications for success and failure

## State Management

### Providers Watched (reactive)

| Provider              | Type                | Purpose                              |
|-----------------------|---------------------|--------------------------------------|
| `editingNoteProvider` | `int?`              | Note ID being edited (null = create) |

### Providers Listened (side effects)

| Provider                | Purpose                                      |
|-------------------------|----------------------------------------------|
| `editingNoteProvider`   | Populate field when entering edit mode        |
| `currentChannelProvider`| Save/load drafts on channel switch            |

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

The InputBar is placed at the bottom of the `ChatView` column, below the scrollable note list. It communicates exclusively through Riverpod providers. The `RawKeyboardListener` wrapping the `TextField` intercepts Enter/Shift+Enter before the field processes them.

## Related Files

| File | Relationship |
|------|-------------|
| `lib/widgets/input_bar.dart` | This component |
| `lib/widgets/input_link_preview.dart` | Link preview widget shown above bar |
| `lib/widgets/file_upload_dialog.dart` | Single file upload dialog |
| `lib/widgets/multi_file_upload_dialog.dart` | Multi-file upload dialog |
| `lib/widgets/chat_view.dart` | Parent widget that hosts the input bar |
| `lib/providers/notes_provider.dart` | Note CRUD operations |
| `lib/providers/current_channel_provider.dart` | Active channel for submissions |
| `lib/providers/editing_note_provider.dart` | Edit mode state |
| `lib/providers/drafts_provider.dart` | Per-channel draft persistence |
| `lib/providers/media_provider.dart` | File upload handling |
| `lib/models/upload_file_data.dart` | Upload file data model |
| `lib/utils/toast_utils.dart` | Success/error toast display |
