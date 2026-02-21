import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:memoka_server/src/web/routes/healthcheck_route.dart';

void main() {
  group('HealthcheckRoute', () {
    late HealthcheckRoute route;

    setUp(() {
      route = HealthcheckRoute();
    });

    test('accepts GET and OPTIONS methods', () {
      expect(route.methods, contains(Method.get));
      expect(route.methods, contains(Method.options));
    });

    test('path is /', () {
      expect(route.path, '/**');
    });
  });
}
