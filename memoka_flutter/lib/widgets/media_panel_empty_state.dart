import 'package:flutter/material.dart';

/// Shared empty state for MediaPanel tabs.
///
/// Displays a centered icon + message. All tabs use the same layout,
/// colors, and sizing — callers only specify the icon and text.
class MediaPanelEmptyState extends StatelessWidget {
  const MediaPanelEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  static const _color = Color(0xFF00171F);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: _color.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: _color.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
