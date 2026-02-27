import 'package:memoka_client/memoka_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/chat_screen.dart';
import 'screens/server_setup_screen.dart';

late Client client;

late String serverUrl;

/// Web server URL (port 8082 in dev, same port otherwise).
/// Used by upload route, media serving, etc.
String getWebServerUrl() {
  final uri = Uri.parse(serverUrl);
  final port = uri.port == 8080 ? 8082 : uri.port;
  return '${uri.scheme}://${uri.host}:$port';
}

/// SharedPreferences key for stored server URL.
const _serverUrlKey = 'server_url';

/// Get the server URL based on the platform.
/// Web: same-origin (frontend and backend served together).
/// Native: check SharedPreferences, then --dart-define, then debug fallback.
Future<String> getServerUrl() async {
  if (kIsWeb) {
    final uri = Uri.base;

    // In development (localhost), always connect to API server on port 8080
    // even if the web app is served from port 8082
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return 'http://localhost:8080/';
    }

    // In production with reverse proxy, use same origin (host + port)
    return '${uri.scheme}://${uri.host}:${uri.port}/';
  }

  // Native: check SharedPreferences for saved URL
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_serverUrlKey);
  if (saved != null && saved.isNotEmpty) {
    return saved;
  }

  // Compile-time override: --dart-define=SERVER_URL=https://...
  const defineUrl = String.fromEnvironment('SERVER_URL');
  if (defineUrl.isNotEmpty) {
    return defineUrl;
  }

  // No URL configured — return empty to signal setup needed
  return '';
}

/// Whether the native app needs server URL configuration.
bool get needsServerSetup => !kIsWeb && serverUrl.isEmpty;

/// Update the server URL and reinitialize the client.
Future<void> setServerUrl(String url) async {
  serverUrl = url;
  client = Client(serverUrl)
    ..connectivityMonitor = kIsWeb ? null : FlutterConnectivityMonitor();

  if (!kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverUrlKey, url);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // Preload fonts before the first frame so CJK characters never hit the
  // async-loading window that renders them as '?'.
  await GoogleFonts.pendingFonts([GoogleFonts.spaceGrotesk()]);

  serverUrl = await getServerUrl();

  // Only create client if we have a URL (web always has one)
  if (serverUrl.isNotEmpty) {
    client = Client(serverUrl)
      ..connectivityMonitor = kIsWeb ? null : FlutterConnectivityMonitor();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memoka',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: const Color(0xFFCE2161),
          selectionColor: const Color(0xFFCE2161).withValues(alpha: 0.3),
          selectionHandleColor: const Color(0xFFCE2161),
        ),
      ),
      home: needsServerSetup ? const ServerSetupScreen() : const ChatScreen(),
    );
  }
}
