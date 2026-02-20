import 'package:flutter/material.dart';

/// A styled Phosphor icon button with circular border feedback.
///
/// Provides a consistent design language for all tappable icons in the app.
/// Uses a circular border on hover/press instead of a filled background.
///
/// Features:
/// - Animated circular border on hover (desktop) and press (all platforms)
/// - Phosphor icon with configurable color
/// - Configurable size and padding
///
/// Usage:
/// ```dart
/// IconButtonStyled(
///   icon: PhosphorIcons.camera(),
///   onPressed: _capturePhoto,
/// )
/// ```
class IconButtonStyled extends StatefulWidget {
  /// The Phosphor icon to display.
  final IconData icon;

  /// Callback when the button is tapped.
  final VoidCallback onPressed;

  /// Icon size in logical pixels. Defaults to 24.
  final double size;

  /// Padding inside the button around the icon. Defaults to 8.
  final double padding;

  /// Icon and border color. Defaults to #CE2161.
  final Color color;

  const IconButtonStyled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.padding = 8,
    this.color = const Color(0xFFCE2161),
  });

  @override
  State<IconButtonStyled> createState() => _IconButtonStyledState();
}

class _IconButtonStyledState extends State<IconButtonStyled> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _isHovered || _isPressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? widget.color.withValues(alpha: _isPressed ? 1.0 : 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.padding),
            child: Icon(
              widget.icon,
              color: widget.color,
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}
