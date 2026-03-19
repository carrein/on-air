import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../main.dart';
import '../screens/server_setup_screen.dart';
import '../services/notification_service.dart';

/// Build-time version via --dart-define=APP_VERSION=$(git describe --tags --abbrev=0).
/// Shows the git tag version in production builds, "DEV" in local dev.
const _appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'DEV');

/// Settings view widget (displayed in main content area)
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: const Color(0xFFFFFDF6),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Server section (native only)
                if (!kIsWeb) _buildServerSection(context),
                // Notifications section
                _buildNotificationsSection(context),
                // About section
                _buildAboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Server',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
          ),
        ),
        ListTile(
          title: const Text('Server URL', style: TextStyle(fontSize: 14)),
          subtitle: Text(
            serverUrl,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF00171F).withValues(alpha: 0.6),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: TextButton(
            onPressed: () async {
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const ServerSetupScreen(isEditing: true),
                ),
              );
            },
            child: const Text(
              'Change',
              style: TextStyle(color: Color(0xFF3450A3)),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Notifications',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
          ),
        ),
        ListTile(
          leading: PhosphorIcon(
            PhosphorIcons.bell(),
            color: const Color(0xFF00171F),
            size: 20,
          ),
          title: const Text(
            'Test Notification',
            style: TextStyle(fontSize: 14),
          ),
          subtitle: Text(
            'Fires after 10 seconds',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF00171F).withValues(alpha: 0.6),
            ),
          ),
          trailing: TextButton(
            onPressed: () async {
              final granted = await scheduleTestNotification();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    granted
                        ? 'Notification scheduled — arrives in 10 seconds'
                        : 'Notification permission denied',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Send',
              style: TextStyle(color: Color(0xFF3450A3)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
          ),
        ),
        ListTile(
          leading: PhosphorIcon(
            PhosphorIcons.info(),
            color: const Color(0xFF00171F),
            size: 20,
          ),
          title: const Text('Version', style: TextStyle(fontSize: 14)),
          subtitle: Text(
            _appVersion,
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF00171F).withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
