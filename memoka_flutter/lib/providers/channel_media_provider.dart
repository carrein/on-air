import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../models/channel_media.dart';
import '../utils/url_utils.dart';
import 'notes_provider.dart';

part 'channel_media_provider.g.dart';

/// Provides all media and links for a specific channel.
/// Synchronously derives from notesProvider so the MediaPanel never sees
/// a loading→data flicker when notes change.
@riverpod
ChannelMedia channelMediaData(Ref ref, int channelId) {
  final notesAsync = ref.watch(notesProvider(channelId));
  return notesAsync.when(
    data: (notes) => _extractMedia(notes),
    loading: () => ChannelMedia.empty(),
    error: (_, _) => ChannelMedia.empty(),
  );
}

/// Extract and organize media from notes.
ChannelMedia _extractMedia(List<Note> notes) {
  final List<MediaItem> images = [];
  final List<MediaItem> videos = [];
  final List<MediaItem> documents = [];
  final List<LinkItem> links = [];

  for (final note in notes) {
    // Extract attachments
    if (note.attachments != null && note.attachments!.isNotEmpty) {
      for (final attachment in note.attachments!) {
        final mediaItem = MediaItem(
          noteId: note.id!,
          attachment: attachment,
          createdAt: note.createdAt,
          noteContent: note.content,
        );

        if (mediaItem.isImage) {
          images.add(mediaItem);
        } else if (mediaItem.isVideo) {
          videos.add(mediaItem);
        } else {
          documents.add(mediaItem);
        }
      }
    }

    // Extract links - get ALL URLs from note content
    final urls = _extractUrlsFromContent(note.content);
    for (final url in urls) {
      // If this URL has a preview, use it; otherwise create a basic preview
      final hasPreview =
          note.linkPreview != null && note.linkPreview!.url == url;
      final preview = hasPreview
          ? note.linkPreview!
          : LinkPreview(
              url: url,
              title: null,
              description: null,
              imageUrl: null,
              faviconUrl: null,
            );

      links.add(
        LinkItem(
          noteId: note.id!,
          preview: preview,
          createdAt: note.createdAt,
          noteContent: note.content,
        ),
      );
    }
  }

  // Sort all by createdAt descending (newest first)
  images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  links.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return ChannelMedia(
    images: images,
    videos: videos,
    documents: documents,
    links: links,
  );
}

/// Extract all URLs from note content.
List<String> _extractUrlsFromContent(String content) {
  final matches = urlPattern.allMatches(content);
  return matches.map((match) => match.group(0)!).toSet().toList();
}
