import 'constants.dart';

/// Shared validation functions for channel and note inputs.
class Validation {
  /// Validates a channel name. Returns an error message or null if valid.
  static String? validateChannelName(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return 'Channel name cannot be empty';
    if (trimmed.length > 100) {
      return 'Channel name too long (max 100 characters)';
    }
    return null;
  }

  /// Validates an emoji/icon key. Returns an error message or null if valid.
  static String? validateEmojiKey(String? emoji) {
    if (emoji != null && emoji.length > 30) {
      return 'Icon key too long (max 30 characters)';
    }
    return null;
  }

  /// Validates note content. Returns an error message or null if valid.
  static String? validateNoteContent(String? content) {
    final trimmed = content?.trim() ?? '';
    if (trimmed.isEmpty) return 'Note content cannot be empty';
    if (trimmed.length > maxNoteContentLength) {
      return 'Note content too long (max 200,000 characters)';
    }
    return null;
  }
}
