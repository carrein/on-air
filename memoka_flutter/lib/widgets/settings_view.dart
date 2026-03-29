import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../main.dart';
import '../providers/thumbnail_regen_provider.dart';
import '../services/notification_service.dart';
import '../utils/toast_utils.dart';
import 'app_text_button.dart';
import 'setting_item.dart';
import 'styled_text_field.dart';

/// Build-time version via --dart-define=APP_VERSION=$(git describe --tags --abbrev=0).
/// Shows the git tag version in production builds, "DEV" in local dev.
const _appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'DEV');

/// Settings view widget (displayed in main content area)
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late final TextEditingController _urlController;
  bool _testingUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool get _urlChanged => _urlController.text.trim() != serverUrl;

  String _normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (!url.endsWith('/')) url = '$url/';
    return url;
  }

  Future<void> _saveUrl() async {
    final url = _normalizeUrl(_urlController.text);
    if (url.isEmpty) {
      ToastUtils.show(
        context,
        'Please enter a server URL',
        type: ToastType.error,
      );
      return;
    }

    setState(() => _testingUrl = true);
    try {
      await setServerUrl(url);
      await client.chat.getChannels().timeout(const Duration(seconds: 10));
      if (!mounted) return;
      _urlController.text = url;
      setState(() => _testingUrl = false);
      ToastUtils.show(context, 'Connected', type: ToastType.success);
    } catch (e) {
      if (!mounted) return;
      setState(() => _testingUrl = false);
      ToastUtils.show(
        context,
        'Connection failed: ${e.toString().split('\n').first}',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a completion toast when a job transitions from running → done.
    ref.listen(thumbnailRegenProvider, (prev, next) {
      if (next == null || !context.mounted) return;
      // Running → done transition.
      if (prev?.isRunning == true && !next.isRunning) {
        if (next.processed == 0 && next.failed > 0) {
          ToastUtils.show(
            context,
            'All ${next.failed} thumbnail${next.failed == 1 ? '' : 's'} failed',
            type: ToastType.error,
          );
        } else {
          ToastUtils.show(
            context,
            'Regenerated ${next.processed} thumbnail${next.processed == 1 ? '' : 's'}'
            '${next.failed > 0 ? ' (${next.failed} failed)' : ''}',
            type: ToastType.success,
          );
        }
      }
      // Immediate zero-count (no eligible items).
      if (prev == null && !next.isRunning && next.total == 0) {
        ToastUtils.show(context, 'No thumbnails to regenerate');
      }
    });

    return ColoredBox(
      color: const Color(0xFFFFFDF6),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildServerSection(),
                _buildNotificationsSection(),
                _buildJobsSection(),
                _buildAboutSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Server'),
        SettingItem(
          title: 'Server URL',
          icon: PhosphorIcons.link(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                child: StyledTextField(
                  controller: _urlController,
                  enabled: !_testingUrl,
                  autocorrect: false,
                  keyboardType: TextInputType.url,
                  hintText: 'https://memoka.example.com',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (_urlChanged) _saveUrl();
                  },
                ),
              ),
              const SizedBox(width: 12),
              AppTextButton(
                label: 'Save',
                onPressed: _urlChanged && !_testingUrl ? _saveUrl : null,
                variant: AppTextButtonVariant.secondary,
                loading: _testingUrl,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        _sectionHeader('Notifications'),
        SettingItem(
          title: 'Test Notification',
          icon: PhosphorIcons.bell(),
          subtitle: 'Fires after 10 seconds',
          trailing: AppTextButton(
            label: 'Send',
            onPressed: () async {
              final granted = await scheduleTestNotification();
              if (!mounted) return;
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
            variant: AppTextButtonVariant.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildJobsSection() {
    final progress = ref.watch(thumbnailRegenProvider);
    final isRunning = progress?.isRunning ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        _sectionHeader('Jobs'),
        SettingItem(
          title: 'Regenerate Thumbnails',
          icon: PhosphorIcons.images(),
          trailing: isRunning
              ? Text(
                  '${progress!.processed} / ${progress.total}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3450A3),
                    fontWeight: FontWeight.w600,
                  ),
                )
              : AppTextButton(
                  label: 'Run',
                  onPressed: () async {
                    try {
                      await ref.read(thumbnailRegenProvider.notifier).start();
                    } catch (e) {
                      if (!mounted) return;
                      ToastUtils.show(
                        context,
                        'Failed to start: $e',
                        type: ToastType.error,
                      );
                    }
                  },
                  variant: AppTextButtonVariant.secondary,
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
        _sectionHeader('About'),
        SettingItem(
          title: 'Version',
          icon: PhosphorIcons.info(),
          trailing: Text(
            _appVersion,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3450A3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF00171F),
        ),
      ),
    );
  }
}
