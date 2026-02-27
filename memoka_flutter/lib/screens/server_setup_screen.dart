import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'chat_screen.dart';

/// Screen for configuring the server URL on native platforms.
/// Shown on first launch when no server URL is saved, or when
/// the user taps "Change Server" in settings.
class ServerSetupScreen extends StatefulWidget {
  /// When true, navigates back instead of replacing the route on success.
  final bool isEditing;

  const ServerSetupScreen({super.key, this.isEditing = false});

  @override
  State<ServerSetupScreen> createState() => _ServerSetupScreenState();
}

class _ServerSetupScreenState extends State<ServerSetupScreen> {
  static const _bgColor = Color(0xFF00171F);
  static const _accent = Color(0xFFCE2161);

  final _controller = TextEditingController();
  bool _testing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current URL or emulator default in debug
    if (serverUrl.isNotEmpty) {
      _controller.text = serverUrl;
    } else if (kDebugMode) {
      _controller.text = 'http://localhost:8080/';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    // Add scheme if missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    // Ensure trailing slash
    if (!url.endsWith('/')) {
      url = '$url/';
    }
    return url;
  }

  Future<void> _testConnection() async {
    final url = _normalizeUrl(_controller.text);
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a server URL');
      return;
    }

    setState(() {
      _testing = true;
      _error = null;
    });

    try {
      // Initialize client with the test URL and try to reach the server
      await setServerUrl(url);
      await client.chat.getChannels().timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (widget.isEditing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Connection failed: ${e.toString().split('\n').first}';
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App title
                Text(
                  'Memoka',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to your server',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 48),

                // URL input
                TextField(
                  controller: _controller,
                  enabled: !_testing,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  style: GoogleFonts.spaceGrotesk(
                    color: const Color(0xFF00171F),
                  ),
                  decoration: InputDecoration(
                    hintText: 'https://memoka.example.com',
                    hintStyle: GoogleFonts.spaceGrotesk(
                      color: Color(0xFF00171F).withValues(alpha: 0.38),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _testConnection(),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFDB0000),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Test Connection button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _testing ? null : _testConnection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: _testing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Test Connection',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                // Cancel button (editing mode only)
                if (widget.isEditing) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
