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
  /// Size tiers for consistent icon sizing across the app.
  /// - **xs (14)**: Inline dismiss buttons (search clear, link preview close)
  /// - **sm (18)**: In-note controls (audio, document, attachment actions)
  /// - **md (24)**: Navbar and input bar actions (default)
  /// - **lg (30)**: Fullscreen overlay controls (lightbox close, navigation)
  static const double xs = 14;
  static const double sm = 18;
  static const double md = 24;
  static const double lg = 30;

  /// The Phosphor icon to display.
  final IconData icon;

  /// Callback when the button is tapped. When null the button is disabled.
  final VoidCallback? onPressed;

  /// Icon size in logical pixels. Defaults to 24.
  final double size;

  /// Padding inside the button around the icon.
  /// If null, scales with icon size: xs=4, sm=6, md=8, lg=8.
  final double? padding;

  /// Icon and border color. Defaults to #CE2161.
  final Color color;

  const IconButtonStyled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.padding,
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
    final enabled = widget.onPressed != null;
    final active = enabled && (_isHovered || _isPressed);
    final effectivePadding =
        widget.padding ??
        (widget.size <= IconButtonStyled.xs
            ? 5.0
            : widget.size <= IconButtonStyled.sm
            ? 6.0
            : 8.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? widget.color : Colors.transparent,
              width: widget.size <= IconButtonStyled.sm ? 1.0 : 1.5,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(effectivePadding),
            child: Icon(
              widget.icon,
              color: enabled
                  ? widget.color
                  : widget.color.withValues(alpha: 0.3),
              size: widget.size,
            ),
          ),
        ),
      ),
    );
  }
}
