import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Sends a GET request to [url] using browser-native XHR with a 4-second
/// timeout.
///
/// Unlike `http`-package requests (which use `fetch()` under the hood),
/// XHR timeouts are enforced by the browser itself — the request is actually
/// aborted after 4 seconds. This prevents stale pending requests from
/// accumulating in Chrome's HTTP/1.1 connection pool (6-connection limit)
/// after repeated backoff cycles.
///
/// Throws if the request fails, times out, or returns a non-2xx status.
Future<void> webHealthPing(String url) {
  final completer = Completer<void>();

  final xhr = web.XMLHttpRequest();
  xhr.open('GET', url);
  xhr.timeout = 4000;

  xhr.addEventListener(
    'load',
    ((web.Event _) {
      if (!completer.isCompleted) {
        if (xhr.status >= 200 && xhr.status < 300) {
          completer.complete();
        } else {
          completer.completeError(
            Exception('Health ping failed: HTTP ${xhr.status}'),
          );
        }
      }
    }).toJS,
  );

  xhr.addEventListener(
    'error',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Health ping network error'));
      }
    }).toJS,
  );

  xhr.addEventListener(
    'timeout',
    ((web.Event _) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('Health ping timed out'));
      }
    }).toJS,
  );

  xhr.send();

  return completer.future;
}
