import 'dart:async';

import 'package:serverpod/serverpod.dart';

/// Simple GET route that returns 200 OK with CORS headers.
///
/// Used by Flutter web clients as a connectivity probe. The browser-native
/// XHR timeout (set on the client) ensures these requests are properly
/// aborted — unlike Dart-side `.timeout()` which leaves the underlying
/// fetch open.
class HealthcheckRoute extends Route {
  HealthcheckRoute()
    : super(methods: {Method.get, Method.options}, path: '/**');

  @override
  FutureOr<Result> handleCall(Session session, Request request) {
    if (request.method == Method.options) {
      return Response.noContent(headers: _corsHeaders());
    }
    return Response.ok(
      body: Body.fromString('OK'),
      headers: _corsHeaders(),
    );
  }

  Headers _corsHeaders() => Headers.build(
    (mh) => mh.accessControlAllowOrigin =
        const AccessControlAllowOriginHeader.wildcard(),
  );
}
