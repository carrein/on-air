import 'dart:async';

import 'package:serverpod/serverpod.dart';

/// Simple healthcheck route that returns 200 OK with CORS headers.
/// Used by the Flutter client to verify server reachability.
class HealthcheckRoute extends Route {
  HealthcheckRoute()
    : super(methods: {Method.get, Method.options}, path: '/**');

  @override
  FutureOr<Result> handleCall(Session session, Request request) {
    return Response.ok(
      body: Body.fromString('ok'),
      headers: Headers.build(
        (mh) => mh.accessControlAllowOrigin =
            const AccessControlAllowOriginHeader.wildcard(),
      ),
    );
  }
}
