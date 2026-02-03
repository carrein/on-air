# Implementation Status

## ✅ Completed

### 1. Smart Channel Selection (FIXED)
- Updated `current_channel_provider.dart` to intelligently select channel:
  - Tries to load last opened channel from SharedPreferences
  - Validates that saved channel still exists
  - Falls back to first available channel if saved one doesn't exist
  - Throws error if no channels available (prompts user to create one)
- **Status**: Ready to test after running `flutter pub run build_runner build`

### 2. Document Upload Support - Server Side (COMPLETED)
**File**: `on_air_server/lib/src/media/media_endpoint.dart`
- ✅ Added document MIME types:
  - PDF: `application/pdf`
  - Text: `text/plain`, `text/markdown`
  - Word: `application/msword`, `.docx`
  - Excel: `.xls`, `.xlsx`
  - Zip: `application/zip`
- ✅ Conditional processing logic:
  - Images: Full processing (compression, thumbnails, EXIF)
  - Documents: Simple file storage with hash calculation
- ✅ Added `_isImage()` helper method
- ✅ Extended `_getExtensionFromMimeType()` for all document types
- ✅ Added `ImageProcessor.calculateHash()` public method for documents

**Status**: Server is ready to accept documents!

## 🚧 In Progress / Needs Completion

### 3. Document Upload Support - Flutter Side

**What's Done**:
- ✅ Added `file_picker: ^8.1.4` to pubspec.yaml

**What Remains**:

#### A. Update Input Bar (`input_bar.dart`)
```dart
// Replace _pickImage() with _pickFile()
Future<void> _pickFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'png', 'pdf', 'txt', 'md', 'doc', 'docx', 'xls', 'xlsx', 'zip'],
  );

  if (result != null && result.files.single.bytes != null) {
    final file = result.files.single;
    await _showFileUploadDialog(file.bytes!, file.name, file.extension ?? '');
  }
}

// Change button icon from Icons.image to Icons.attach_file
// Change tooltip from 'Upload image' to 'Upload file'
```

#### B. Create Generic Upload Dialog
**New file**: `lib/widgets/file_upload_dialog.dart`
```dart
// Should detect if file is image or document
// For images: Show preview + compression option (reuse existing logic)
// For documents: Show file info (name, size, type) + icon
```

#### C. Update Media Attachment Widget
**File**: `lib/widgets/media_attachment_widget.dart`
```dart
// Add logic to detect attachment type:
// - If image MIME: Show existing image widget
// - If document MIME: Show document card with:
//   - File icon (based on extension)
//   - Filename
//   - File size
//   - Download button
```

#### D. Create Document Attachment Widget
**New file**: `lib/widgets/document_attachment_widget.dart`
```dart
class DocumentAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final String serverUrl;

  // Display:
  // - Document icon (PDF, TXT, DOC, etc.)
  // - Filename
  // - File size (formatted: KB, MB)
  // - Download button (opens in new tab or downloads)
}
```

#### E. Update Chat View Drag-Drop
**File**: `lib/widgets/chat_view.dart`
- Update `_handleWebDrop()` to accept all file types, not just images
- Route to appropriate dialog based on file type

## 📝 Next Steps

### Immediate (To Complete Document Support):

1. **Run Flutter pub get**:
   ```bash
   cd on_air_flutter
   flutter pub get
   ```

2. **Regenerate Riverpod code** (for channel provider fix):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

3. **Regenerate Server code**:
   ```bash
   cd ../on_air_server
   serverpod generate
   ```

4. **Implement Flutter changes** (A-E above)

5. **Test both features**:
   - Test channel selection on app restart
   - Test document upload (PDF, TXT)
   - Test image upload still works
   - Test drag-drop with documents

### Implementation Time Estimate:
- Flutter changes (A-E): ~30-45 minutes
- Testing: ~15 minutes
- **Total**: ~1 hour

## 🎯 Goals

- [x] Fix channel selection to use last opened channel
- [x] Server accepts documents (PDF, TXT, DOC, XLS, ZIP)
- [ ] Flutter UI supports document selection
- [ ] Documents display appropriately in chat
- [ ] Downloads work for documents
- [ ] Drag-drop works for documents

## 📦 Files Modified

### Server:
- `on_air_server/lib/src/media/media_endpoint.dart`
- `on_air_server/lib/src/media/image_processor.dart`

### Flutter:
- `on_air_flutter/lib/providers/current_channel_provider.dart`
- `on_air_flutter/pubspec.yaml`

### To Create:
- `on_air_flutter/lib/widgets/file_upload_dialog.dart`
- `on_air_flutter/lib/widgets/document_attachment_widget.dart`

### To Update:
- `on_air_flutter/lib/widgets/input_bar.dart`
- `on_air_flutter/lib/widgets/media_attachment_widget.dart`
- `on_air_flutter/lib/widgets/chat_view.dart`
