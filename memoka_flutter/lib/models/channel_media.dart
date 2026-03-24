import 'package:memoka_client/memoka_client.dart';
import '../utils/file_utils.dart';

/// Represents all media and links in a channel, organized by type.
class ChannelMedia {
  final List<MediaItem> images;
  final List<MediaItem> videos;
  final List<MediaItem> documents;
  final List<LinkItem> links;

  ChannelMedia({
    required this.images,
    required this.videos,
    required this.documents,
    required this.links,
  });

  factory ChannelMedia.empty() {
    return ChannelMedia(
      images: const [],
      videos: const [],
      documents: const [],
      links: const [],
    );
  }

  /// Total count of all media items
  int get totalCount =>
      images.length + videos.length + documents.length + links.length;
}

/// Represents a media attachment (image, video, or document) from a note.
class MediaItem {
  final int noteId;
  final MediaAttachment attachment;
  final DateTime createdAt;
  final String noteContent;

  MediaItem({
    required this.noteId,
    required this.attachment,
    required this.createdAt,
    required this.noteContent,
  });

  /// Returns the full URL to the media file
  String getMediaUrl(String serverUrl) {
    return FileUtils.buildMediaUrl(
      serverUrl,
      attachment.filePath,
      attachment.contentHash,
    );
  }

  /// Returns the thumbnail URL (if available)
  String? getThumbnailUrl(String serverUrl) {
    return FileUtils.buildThumbnailUrl(serverUrl, attachment);
  }

  /// Check if this is an image
  bool get isImage => attachment.mimeType.startsWith('image/');

  /// Check if this is a video
  bool get isVideo => attachment.mimeType.startsWith('video/');

  /// Check if this is a document
  bool get isDocument => !isImage && !isVideo;
}

/// Represents a link preview from a note.
class LinkItem {
  final int noteId;
  final LinkPreview preview;
  final DateTime createdAt;
  final String noteContent;

  LinkItem({
    required this.noteId,
    required this.preview,
    required this.createdAt,
    required this.noteContent,
  });

  /// Extract the URL from the preview
  String get url => preview.url;

  /// Get the title or fallback to formatted URL
  String get displayTitle {
    if (preview.title != null && preview.title!.isNotEmpty) {
      return preview.title!;
    }
    // Fallback to domain name from URL
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// Get the description
  String? get description => preview.description;

  /// Check if this link has a full preview (title + description)
  bool get hasFullPreview => preview.title != null && preview.title!.isNotEmpty;

  /// Get the favicon URL
  String? get faviconUrl => preview.faviconUrl;
}
