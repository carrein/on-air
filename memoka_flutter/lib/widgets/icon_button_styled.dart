import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'styled_tooltip.dart';

/// A styled Phosphor icon button with circular InkWell and optional tooltip.
///
/// Provides a consistent design language for all tappable icons in the app.
/// Uses duotone Phosphor icons with a circular ink splash on press.
///
/// Features:
/// - Circular InkWell with white splash/highlight
/// - Phosphor duotone icon with configurable primary and secondary colors
/// - Optional tooltip (via StyledTooltip, desktop/web only)
/// - Configurable size and padding
///
/// Usage:
/// ```dart
/// IconButtonStyled(
///   icon: PhosphorIconsDuotone.camera,
///   onPressed: _capturePhoto,
///   tooltip: 'Camera',
/// )
/// ```
class IconButtonStyled extends StatelessWidget {
  /// The Phosphor icon to display.
  final PhosphorIconData icon;

  /// Callback when the button is tapped.
  final VoidCallback onPressed;

  /// Optional tooltip message (shown on hover, desktop/web only).
  final String? tooltip;

  /// Icon size in logical pixels. Defaults to 24.
  final double size;

  /// Padding inside the InkWell around the icon. Defaults to 8.
  final double padding;

  /// Primary icon color. Defaults to white.
  final Color color;

  /// Duotone secondary color. Defaults to #F9A302.
  final Color duotoneSecondaryColor;

  /// Duotone secondary opacity. Defaults to 1.0.
  final double duotoneSecondaryOpacity;

  /// InkWell splash color. Defaults to white24.
  final Color splashColor;

  /// InkWell highlight color. Defaults to white24.
  final Color highlightColor;

  const IconButtonStyled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 24,
    this.padding = 8,
    this.color = Colors.white,
    this.duotoneSecondaryColor = const Color(0xFFF9A302),
    this.duotoneSecondaryOpacity = 1.0,
    this.splashColor = Colors.white24,
    this.highlightColor = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: splashColor,
        highlightColor: highlightColor,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: PhosphorIcon(
            icon,
            color: color,
            duotoneSecondaryColor: duotoneSecondaryColor,
            duotoneSecondaryOpacity: duotoneSecondaryOpacity,
            size: size,
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return StyledTooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
