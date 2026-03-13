import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'chat_stream_provider.dart';
import 'page_watch_provider.dart';
import '../services/notification_service.dart';

part 'page_change_listener_provider.g.dart';

/// Listens to the WebSocket stream for page watch events and fires
/// local notifications + invalidates watch providers.
@Riverpod(keepAlive: true)
void pageChangeListener(Ref ref) {
  ref.listen(chatStreamProvider, (_, next) {
    next.whenData((event) {
      if (event.type == 'pageChanged' && event.noteId != null) {
        // Refresh the watch provider for badge update
        ref.invalidate(pageWatchProvider(event.noteId!));

        // Extract link preview info for rich notification
        final preview = event.note?.linkPreview;
        final url = preview?.url ?? event.note?.content;
        String? domain;
        if (url != null) {
          final uri = Uri.tryParse(url);
          domain = uri?.host;
        }

        showPageChangeNotification(
          noteId: event.noteId!,
          channelId: event.channelId ?? 0,
          pageTitle: preview?.title,
          pageDomain: domain,
          pageUrl: preview?.url,
          faviconUrl: preview?.faviconUrl,
        );
      } else if (event.type == 'pageWatchDisabled' && event.noteId != null) {
        ref.invalidate(pageWatchProvider(event.noteId!));
      }
    });
  });
}
