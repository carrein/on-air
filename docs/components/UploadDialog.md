# Upload Dialog (MultiFileUploadDialog)

## Overview

Unified upload confirmation dialog for single and multi-file selections. Shows images in a justified grid layout (rows of equal height filling the full width) and non-image files in a compact list below. Users can remove individual files before uploading.

**File**: `memoka_flutter/lib/widgets/multi_file_upload_dialog.dart`
**Widget**: `MultiFileUploadDialog` (StatefulWidget)
**State**: `_MultiFileUploadDialogState`

---

## Props

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `files` | `List<UploadFileData>` | Yes | Files selected for upload |
| `onSend` | `void Function(List<UploadFileData>)` | Yes | Called with the (possibly filtered) file list when Upload All is tapped |

---

## Layout

```
AlertDialog (sharp corners, #F6F0ED background)
  contentPadding: 12px all sides
  width: 600px
  Column (mainAxisSize: min)
    // Images — justified grid
    LayoutBuilder
      SingleChildScrollView
        Column
          Row (per justified row)
            SizedBox (computed width/height per image)
              Stack
                Image (BoxFit.cover, cacheWidth: 800)
                Positioned (top: 6, right: 6)
                  IconButtonStyled (trashSimple, xs, white)
    // Non-image files — compact list
    SizedBox (height: 8) // gap if both sections
    Row (per file)
      Icon (file type icon, 24px, core.text @ 60%)
      Text (filename, 13px, ellipsis)
      Checkbox + "Compress" (videos only)
      IconButtonStyled (trashSimple, xs)
    // Actions
    SizedBox (height: 12)
    Row (end-aligned)
      TextButton ("Cancel")
      SizedBox (width: 8)
      FilledButton ("Upload All")
```

---

## Styling

### Colors

| Token | Value | Usage |
|-------|-------|-------|
| Dialog background | `#F6F0ED` (core.surface) | AlertDialog backgroundColor |
| File icon/text muted | `#00171F` @ 60% | Non-image file icons and secondary text |
| Trash icon (images) | `Colors.white` | Contrast against photo background |
| Trash icon (files) | `#3450A3` (default) | IconButtonStyled default color |

### Dimensions

| Token | Value |
|-------|-------|
| Dialog width | 600px |
| Content padding | 12px |
| Target row height | 220px |
| Image spacing | 0px (flush, no gaps) |
| Image cache width | 800px |
| Trash icon size | `IconButtonStyled.xs` (14px) |
| Trash icon offset | 6px from top-right corner |
| Gap media-to-actions | 12px |
| Gap cancel-to-upload | 8px |

---

## Justified Row Algorithm

Images are displayed in a justified grid where every row fills the full container width, forming a flush rectangle.

### Steps

1. **Aspect ratio resolution** (async, on init):
   - For each image file, decode the image header via `ImageProvider.resolve()` to get width/height
   - Platform-aware: `FileImage` on native, `MemoryImage` on web
   - Fallback to 1.0 aspect ratio on error
   - Shows `AppSpinner(size: 32)` while resolving

2. **Greedy row partition**:
   - Iterate images, accumulating aspect ratios in the current row
   - When `(containerWidth - gaps) / sumAspectRatios <= targetRowHeight`, finalize the row and start a new one
   - Each finalized row: all images scaled to a common height so their widths sum to `containerWidth`

3. **Rebalance pass**:
   - If the last row's computed height exceeds 1.5x the target (too few items), steal one image at a time from the previous row
   - Repeat until balanced or previous row has only 1 item
   - Prevents an "L-shaped" layout where the last row is much taller than others

4. **Finalize**:
   - Every row (including the last) scales to fill the full container width
   - Result: a flush rectangle on all four sides

### Single image

When only 1 image is selected, it fills the full container width at its natural aspect ratio.

---

## Interactions

### Remove file
- Tap trash icon on any image tile or file row
- File is removed from `_files` list and `_aspectRatios` map
- Grid re-renders with updated justified layout
- **Auto-close**: if the last file is removed, the dialog pops immediately (no empty state flash)

### Upload All
- Pops the dialog and calls `onSend(_files)` with the current (possibly filtered) file list
- Disabled when `_files` is empty

### Cancel
- Pops the dialog without calling `onSend`

### Video compression
- Videos in the non-image list show a compact checkbox + "Compress" label
- Toggling sets `file.compress` which is passed through to the upload queue for server-side 720p conversion

---

## State Management

### Local Widget State

| State | Type | Description |
|-------|------|-------------|
| `_files` | `List<UploadFileData>` | Mutable copy of `widget.files`; modified by remove |
| `_aspectRatios` | `Map<UploadFileData, double>` | Decoded aspect ratios for image files |
| `_loaded` | `bool` | `true` once all aspect ratios are resolved |

No providers are watched or read — this is a pure local-state dialog.

---

## Call Sites

The dialog is shown via `_showMultiFileUploadDialog()` in two widgets:

| Widget | File | Trigger |
|--------|------|---------|
| `ChatView` | `chat_view.dart` | Web paste, web drag-and-drop |
| `NoteInput` | `note_input.dart` | File picker, camera capture |

Both always use `MultiFileUploadDialog` regardless of file count (single or multi). The old `FileUploadDialog` for single files has been removed.

---

## Related Files

| File | Relationship |
|------|-------------|
| `lib/models/upload_file_data.dart` | Data model for selected files (bytes/path, name, extension, compress flag) |
| `lib/widgets/icon_button_styled.dart` | Trash icon button component |
| `lib/widgets/app_spinner.dart` | Loading spinner during aspect ratio resolution |
| `lib/providers/pending_uploads_provider.dart` | Upload queue that receives files from `onSend` |
| `lib/widgets/pending_note_widget.dart` | Ghost note widget shown during upload |
