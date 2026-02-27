import 'package:flutter/material.dart';

/// A styled icon button with circular InkWell splash feedback.
///
/// No visible border at rest — only a subtle circular splash on tap.
class IconButtonStyled extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double padding;
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
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(
            icon,
            color: enabled ? color : color.withValues(alpha: 0.3),
            size: size,
          ),
        ),
      ),
    );
  }
}
