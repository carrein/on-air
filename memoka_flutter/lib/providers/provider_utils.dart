import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'connection_provider.dart';

/// Whether the app currently has a server connection.
bool isOnline(Ref ref) =>
    ref.read(connectionProvider) == ConnectionState.connected;

/// Whether an exception indicates a network/connectivity failure.
bool isNetworkError(Object e) =>
    e is ServerpodClientException && e.statusCode == -1;

/// Execute [onlineAction] if connected. On network error, fall through
/// and execute [offlineAction]. If [offlineAction] is null and offline,
/// the online action is skipped silently.
///
/// Non-network errors from [onlineAction] are rethrown.
Future<T?> executeWithOfflineFallback<T>(
  Ref ref, {
  required Future<T> Function() onlineAction,
  Future<T> Function()? offlineAction,
}) async {
  if (isOnline(ref)) {
    try {
      return await onlineAction();
    } catch (e) {
      if (!isNetworkError(e)) rethrow;
      // Fall through to offline path
    }
  }
  if (offlineAction != null) {
    return await offlineAction();
  }
  return null;
}
