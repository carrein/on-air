import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable text field with consistent Memoka styling.
///
/// SpaceGrotesk font, cream background, accent-blue focus border, zero radius.
/// Animated border on hover/focus. Used by search field, server URL input, etc.
class StyledTextField extends StatefulWidget {
  const StyledTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.autocorrect = true,
    this.borderless = false,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 10),
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool autocorrect;

  /// When true, removes all borders (for use inside a custom border container).
  final bool borderless;

  final EdgeInsetsGeometry contentPadding;

  static const backgroundColor = Color(0xFFFFFDF6);
  static const borderColor = Color(0xFF3450A3);
  static const textColor = Color(0xFF00171F);

  @override
  State<StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<StyledTextField> {
  bool _isHovered = false;
  bool _isFocused = false;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(StyledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.borderless) return _buildTextField();

    final active = _isHovered || _isFocused;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          border: Border.all(
            color: active
                ? StyledTextField.borderColor
                : StyledTextField.borderColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: _buildTextField(),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      autocorrect: widget.autocorrect,
      keyboardType: widget.keyboardType,
      style: GoogleFonts.spaceGrotesk(
        color: StyledTextField.textColor,
        fontSize: 14,
      ),
      cursorColor: StyledTextField.borderColor,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      mouseCursor: SystemMouseCursors.text,
      decoration: InputDecoration(
        hoverColor: Colors.transparent,
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: StyledTextField.textColor.withValues(alpha: 0.4),
        ),
        prefixIcon: widget.prefixIcon,
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
        fillColor: StyledTextField.backgroundColor,
        contentPadding: widget.contentPadding,
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
    );
  }
}
