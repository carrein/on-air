import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/background_provider.dart';
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
    final currentBackground = ref.watch(backgroundPreferenceProvider);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(currentBackground.assetPath),
          repeat: ImageRepeat.repeat,
          scale: 1.0,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // Server section (native only)
                if (!kIsWeb) _buildServerSection(context),
                // Chat Background section
                _buildBackgroundSection(ref, currentBackground),
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
              style: TextStyle(color: Color(0xFFCE2161)),
            ),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildBackgroundSection(
    WidgetRef ref,
    BackgroundType currentBackground,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: const Text(
            'Chat Background',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00171F),
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: BackgroundType.values.length,
            itemBuilder: (context, index) {
              final background = BackgroundType.values[index];
              final isSelected = background == currentBackground;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildBackgroundCard(ref, background, isSelected),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
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
              style: TextStyle(color: Color(0xFFCE2161)),
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

  Widget _buildBackgroundCard(
    WidgetRef ref,
    BackgroundType background,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref
            .read(backgroundPreferenceProvider.notifier)
            .setBackground(background);
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background preview
              Image.asset(
                background.assetPath,
                fit: BoxFit.cover,
              ),
              // Selected indicator
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFCE2161),
                      shape: BoxShape.circle,
                    ),
                    child: PhosphorIcon(
                      PhosphorIcons.check(),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              // Label at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                  child: Text(
                    background.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
