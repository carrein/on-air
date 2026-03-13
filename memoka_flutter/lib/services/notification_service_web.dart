import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Request browser notification permission and fire a test notification
/// after 10 seconds.
///
/// Returns `true` if permission was granted and the notification was scheduled,
/// `false` if the user denied or dismissed the prompt.
Future<bool> scheduleTestNotification() async {
  final permission = (await web.Notification.requestPermission().toDart).toDart;
  if (permission != 'granted') return false;

  Future.delayed(const Duration(seconds: 10), () {
    web.Notification(
      'Memoka',
      web.NotificationOptions(
        body: 'Test notification — it works!',
        icon: 'favicon.png',
      ),
    );
  });

  return true;
}

/// Show a notification when a watched page's content has changed.
Future<void> showPageChangeNotification({
  required int noteId,
  required int channelId,
  String? pageTitle,
  String? pageDomain,
  String? pageUrl,
  String? faviconUrl,
}) async {
  final permission = web.Notification.permission;
  if (permission != 'granted') return;

  final body = '${pageDomain ?? 'A watched page'} has new content';
  final options = faviconUrl != null
      ? web.NotificationOptions(body: body, icon: faviconUrl)
      : web.NotificationOptions(body: body);

  final notification = web.Notification(
    pageTitle ?? 'Page Changed',
    options,
  );

  // Tap to open the URL in a new tab
  if (pageUrl != null) {
    notification.onclick = (web.Event event) {
      web.window.open(pageUrl, '_blank');
      notification.close();
    }.toJS;
  }
}
