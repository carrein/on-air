import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

/// Wraps [StaticRoute.directory] for the `/media` path and injects CORS
/// headers so that browser-based clients (e.g. Flutter web in dev mode)
/// can load media files even when they are served from a different port.
class CorsMediaRoute extends Route {
  final StaticRoute _inner;

  CorsMediaRoute(Directory root)
      : _inner = StaticRoute.directory(root),
        super(
          methods: {Method.get, Method.head, Method.options},
          path: '/**',
        );

  @override
  FutureOr<Result> handleCall(Session session, Request request) async {
    // Respond to preflight without hitting the static handler.
    if (request.method == Method.options) {
      return Response.noContent(headers: _corsHeaders());
    }

    final result = await _inner.handleCall(session, request);
    if (result is Response) {
      return result.copyWith(
        headers: result.headers.transform(
          (mh) => mh.accessControlAllowOrigin =
              const AccessControlAllowOriginHeader.wildcard(),
        ),
      );
    }
    return result;
  }

  Headers _corsHeaders() => Headers.build(
        (mh) => mh.accessControlAllowOrigin =
            const AccessControlAllowOriginHeader.wildcard(),
      );
}
