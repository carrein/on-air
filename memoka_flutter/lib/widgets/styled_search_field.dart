import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Shared search text field with consistent Memoka styling.
///
/// Accent-colored magnifying glass prefix, bordered outline, optional clear
/// suffix icon. Used by desktop search bar, mobile search input, and GIF picker.
class StyledSearchField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? suffixIcon;

  /// When true, border is hidden until hover/focus (navbar style).
  /// When false, border is always visible (default).
  final bool hideBorderUntilActive;

  const StyledSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.autofocus = false,
    this.suffixIcon,
    this.hideBorderUntilActive = false,
  });

  @override
  State<StyledSearchField> createState() => _StyledSearchFieldState();
}

class _StyledSearchFieldState extends State<StyledSearchField> {
  static const _backgroundColor = Color(0xFFF6F0ED);
  static const _borderColor = Color(0xFFCE2161);
  static const _textColor = Color(0xFF00171F);

  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(StyledSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      widget.focusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode?.hasFocus ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final showBorder =
        !widget.hideBorderUntilActive || _isHovered || _isFocused;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          border: Border.all(
            color: showBorder ? _borderColor : _backgroundColor,
            width: 1,
          ),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          style: GoogleFonts.spaceGrotesk(color: _textColor, fontSize: 14),
          cursorColor: _borderColor,
          onChanged: widget.onChanged,
          mouseCursor: SystemMouseCursors.text,
          decoration: InputDecoration(
            hoverColor: Colors.transparent,
            hintText: widget.hintText,
            hintStyle: TextStyle(color: _textColor.withValues(alpha: 0.4)),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: PhosphorIcon(
                PhosphorIcons.magnifyingGlass(),
                size: 20,
                color: _borderColor,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: widget.suffixIcon,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: _backgroundColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
