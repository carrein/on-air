import 'package:flutter/material.dart';

import 'app_spinner.dart';

/// Visual variant for [AppTextButton].
enum AppTextButtonVariant { primary, secondary, destructive }

/// A styled text button with consistent design system tokens.
///
/// Provides three variants:
/// - **primary**: Filled `#3450A3` background, white text
/// - **secondary**: Transparent background, `#3450A3` border, dark text
/// - **destructive**: Filled `#DB0000` background, white text
///
/// Usage:
/// ```dart
/// AppTextButton(
///   label: 'Create',
///   onPressed: _onCreate,
/// )
///
/// AppTextButton(
///   label: 'Cancel',
///   onPressed: () => Navigator.pop(context),
///   variant: AppTextButtonVariant.secondary,
/// )
/// ```
class AppTextButton extends StatefulWidget {
  /// The button label text.
  final String label;

  /// Callback when tapped. Null disables the button.
  final VoidCallback? onPressed;

  /// Visual variant. Defaults to primary.
  final AppTextButtonVariant variant;

  /// When true, shows AppSpinner instead of label text.
  final bool loading;

  /// When true, button expands to full width with 48px height.
  final bool expand;

  /// Optional color override.
  /// - For primary/destructive: overrides background color.
  /// - For secondary: overrides border and text color.
  final Color? color;

  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppTextButtonVariant.primary,
    this.loading = false,
    this.expand = false,
    this.color,
  });

  @override
  State<AppTextButton> createState() => _AppTextButtonState();
}

class _AppTextButtonState extends State<AppTextButton> {
  static const _primaryBg = Color(0xFF3450A3);
  static const _destructiveBg = Color(0xFFDB0000);
  static const _borderColor = Color(0xFF3450A3);
  static const _textDark = Color(0xFF00171F);
  static const _textLight = Color(0xFFFFFFFF);

  bool _isHovered = false;
  bool _isPressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  ({Color bg, Color fg, Color border}) _resolve() {
    final active = _enabled && (_isHovered || _isPressed);
    final pressed = _enabled && _isPressed;

    switch (widget.variant) {
      case AppTextButtonVariant.primary:
        var bg = widget.color ?? _primaryBg;
        if (!_enabled) bg = bg.withValues(alpha: 0.3);
        if (pressed) bg = Color.lerp(bg, Colors.black, 0.1)!;
        final fg = _enabled ? _textLight : _textLight.withValues(alpha: 0.5);
        return (bg: bg, fg: fg, border: Colors.transparent);

      case AppTextButtonVariant.secondary:
        final accent = widget.color ?? _borderColor;
        final border = _enabled ? accent : accent.withValues(alpha: 0.3);
        final fg = widget.color != null
            ? (_enabled ? widget.color! : widget.color!.withValues(alpha: 0.3))
            : (_enabled ? _textDark : _textDark.withValues(alpha: 0.3));
        var bg = Colors.transparent;
        if (pressed) bg = accent.withValues(alpha: 0.15);
        if (active && !pressed) bg = accent.withValues(alpha: 0.08);
        return (bg: bg, fg: fg, border: border);

      case AppTextButtonVariant.destructive:
        var bg = widget.color ?? _destructiveBg;
        if (!_enabled) bg = bg.withValues(alpha: 0.3);
        if (pressed) bg = Color.lerp(bg, Colors.black, 0.1)!;
        final fg = _enabled ? _textLight : _textLight.withValues(alpha: 0.5);
        return (bg: bg, fg: fg, border: Colors.transparent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (:bg, :fg, :border) = _resolve();

    Widget child;
    if (widget.loading) {
      child = SizedBox(
        width: 16,
        height: 16,
        child: AppSpinner(size: 16, color: fg),
      );
    } else {
      child = Text(
        widget.label,
        style: TextStyle(color: fg, fontSize: 14),
      );
    }

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: _enabled ? widget.onPressed : null,
        onTapDown: _enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: _enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: bg,
            border: border != Colors.transparent
                ? Border.all(color: border, width: 1)
                : null,
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: widget.expand ? Alignment.center : null,
          child: child,
        ),
      ),
    );

    if (widget.expand) {
      button = SizedBox(
        width: double.infinity,
        height: 48,
        child: button,
      );
    }

    return button;
  }
}
