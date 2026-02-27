import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/background_provider.dart';
import '../main.dart';
import '../screens/server_setup_screen.dart';

/// Build-time version override via --dart-define=APP_VERSION=x.y.z.
const _buildTimeVersion = String.fromEnvironment('APP_VERSION');

/// Resolves app version: build-time override > PackageInfo > fallback.
Future<String> _resolveAppVersion() async {
  if (_buildTimeVersion.isNotEmpty) return _buildTimeVersion;
  final info = await PackageInfo.fromPlatform();
  if (info.version.isNotEmpty) return info.version;
  return '—';
}

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
              color: Color(0xFF00171F).withValues(alpha: 0.5),
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
        FutureBuilder<String>(
          future: _resolveAppVersion(),
          builder: (context, snapshot) => ListTile(
            leading: PhosphorIcon(
              PhosphorIcons.info(),
              color: const Color(0xFF00171F),
              size: 20,
            ),
            title: const Text('Version', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              snapshot.data ?? '—',
              style: TextStyle(
                fontSize: 12,
                color: const Color(0xFF00171F).withValues(alpha: 0.5),
              ),
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
