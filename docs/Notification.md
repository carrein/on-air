# Notifications

Test notification harness accessible from Settings. Fires a notification after 10 seconds so the user can background the app and verify delivery on the actual platform.

## API

Single function, platform-conditional via barrel file (`notification_service.dart`):

| Function | Returns | Description |
|----------|---------|-------------|
| `scheduleTestNotification()` | `Future<bool>` | Requests permission, schedules notification in 10s. Returns `true` if granted. |

No startup initialization required — Android plugin is lazy-initialized on first call.

## Platform Behavior

| Platform | Permission | Notification API |
|----------|-----------|-----------------|
| **Web** | `Notification.requestPermission()` | Web Notifications API (`web.Notification`) |
| **Android** | `requestNotificationsPermission()` (API 33+) | `flutter_local_notifications` plugin |

## Implementation

- `notification_service.dart` — barrel file, conditional export (web vs stub)
- `notification_service_web.dart` — Web Notifications API
- `notification_service_stub.dart` — flutter_local_notifications with lazy init
- `settings_view.dart` — Settings UI trigger, toast feedback

## Dependencies

- `flutter_local_notifications: ^19.0.0` (Android only, tree-shaken on web)
- `web: ^1.1.1` (web only)
