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
      web.NotificationOptions(body: 'Test notification — it works!'),
    );
  });

  return true;
}
