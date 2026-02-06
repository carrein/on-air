import 'package:flutter/material.dart';

/// Settings/Account screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // User section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue[700],
                  child: const Icon(Icons.person, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Not signed in',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Settings sections
          _buildSection('Account', [
            _buildListTile(
              icon: Icons.login,
              title: 'Sign In',
              subtitle: 'Sign in to sync your data',
              onTap: () {
                // TODO: Implement sign in
              },
            ),
          ]),
          const Divider(height: 1),
          _buildSection('General', [
            _buildListTile(
              icon: Icons.palette,
              title: 'Theme',
              subtitle: 'Light',
              onTap: () {
                // TODO: Implement theme picker
              },
            ),
            _buildListTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Enabled',
              onTap: () {
                // TODO: Implement notification settings
              },
            ),
          ]),
          const Divider(height: 1),
          _buildSection('About', [
            _buildListTile(
              icon: Icons.info,
              title: 'Version',
              subtitle: '1.0.0',
              onTap: null,
            ),
            _buildListTile(
              icon: Icons.code,
              title: 'Open Source',
              subtitle: 'View on GitHub',
              onTap: () {
                // TODO: Open GitHub link
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
