import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'src/generated/endpoints.dart';
import 'src/generated/protocol.dart';
import 'src/shared/constants.dart';
import 'src/web/routes/app_config_route.dart';
import 'src/web/routes/cors_media_route.dart';
import 'src/web/routes/media_upload_route.dart';
import 'src/web/routes/root.dart';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(args, Protocol(), Endpoints());

  // Setup a default page at the web root.
  // These are used by the default page.
  pod.webServer.addRoute(RootRoute(), '/');
  pod.webServer.addRoute(RootRoute(), '/index.html');

  // Serve all files in the web/static relative directory under /.
  // These are used by the default web page.
  final root = Directory(Uri(path: 'web/static').toFilePath());
  pod.webServer.addRoute(StaticRoute.directory(root));

  // Setup the app config route.
  // We build this configuration based on the servers api url and serve it to
  // the flutter app.
  pod.webServer.addRoute(
    AppConfigRoute(apiConfig: pod.config.apiServer),
    '/app/assets/assets/config.json',
  );

  // Serve media files
  // Use local data/media directory in development, /app/media in production
  final mediaDir = Directory(ServerConstants.mediaBaseDir);
  if (!await mediaDir.exists()) {
    await mediaDir.create(recursive: true);
  }
  pod.webServer.addRoute(
    CorsMediaRoute(mediaDir),
    '/media',
  );

  // Multipart upload route (streams file to disk, no OOM)
  pod.webServer.addRoute(MediaUploadRoute(), '/media/upload');

  // Checks if the flutter web app has been built and serves it if it has.
  final appDir = Directory(Uri(path: 'web/app').toFilePath());
  if (appDir.existsSync()) {
    // Serve the flutter web app under the /app path.
    pod.webServer.addRoute(
      FlutterRoute(
        Directory(
          Uri(path: 'web/app').toFilePath(),
        ),
      ),
      '/app',
    );
  } else {
    // If the flutter web app has not been built, serve the build app page.
    pod.webServer.addRoute(
      StaticRoute.file(
        File(
          Uri(path: 'web/pages/build_flutter_app.html').toFilePath(),
        ),
      ),
      '/app/**',
    );
  }

  // Start the server.
  await pod.start();

  // Ensure default "General" channel exists
  await _ensureDefaultChannel(pod);
}

Future<void> _ensureDefaultChannel(Serverpod pod) async {
  final session = await pod.createSession();
  try {
    final count = await Channel.db.count(
      session,
      where: (t) => t.archived.equals(false),
    );
    if (count == 0) {
      await Channel.db.insertRow(
        session,
        Channel(name: 'General', emoji: '💬'),
      );
      session.log('Created default "General" channel');
    }
  } finally {
    await session.close();
  }
}
