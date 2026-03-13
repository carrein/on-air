import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

final _plugin = FlutterLocalNotificationsPlugin();
var _initialized = false;

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _plugin.initialize(
    const InitializationSettings(android: android),
    onDidReceiveNotificationResponse: _onNotificationTap,
  );
  _initialized = true;
}

void _onNotificationTap(NotificationResponse response) {
  final url = response.payload;
  if (url != null && url.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Request permission and schedule a test notification after 10 seconds.
///
/// Returns `true` if permission was granted and the notification was scheduled,
/// `false` if the user denied notification permission.
Future<bool> scheduleTestNotification() async {
  await _ensureInitialized();

  // Request permission (Android 13+ / API 33+).
  final android = _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  if (android != null) {
    final granted = await android.requestNotificationsPermission();
    if (granted != true) return false;
  }

  Future.delayed(const Duration(seconds: 10), () {
    _plugin.show(
      0,
      'Memoka',
      'Test notification — it works!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'memoka_test',
          'Test Notifications',
          channelDescription: 'Test notification channel for Memoka',
          importance: Importance.high,
          priority: Priority.high,
        ),
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
  await _ensureInitialized();
  _plugin.show(
    noteId,
    pageTitle ?? 'Page Changed',
    '${pageDomain ?? 'A watched page'} has new content',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'memoka_page_watch',
        'Page Watch',
        channelDescription: 'Notifications when a watched page changes',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: pageUrl,
  );
}
