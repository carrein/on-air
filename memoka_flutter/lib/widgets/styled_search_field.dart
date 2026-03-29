import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'styled_text_field.dart';

/// Search text field with magnifying glass prefix and optional hover border.
///
/// Used by desktop search bar, mobile search input, and GIF picker.
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
    // When hideBorderUntilActive is false, delegate entirely to StyledTextField
    // which handles its own animated border.
    if (!widget.hideBorderUntilActive) {
      return StyledTextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        hintText: widget.hintText,
        onChanged: widget.onChanged,
        prefixIcon: _prefixIcon,
        suffixIcon: widget.suffixIcon,
      );
    }

    // hideBorderUntilActive: use custom border that fades in on hover/focus.
    final showBorder = _isHovered || _isFocused;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          border: Border.all(
            color: showBorder
                ? StyledTextField.borderColor
                : StyledTextField.backgroundColor,
            width: 1,
          ),
        ),
        child: StyledTextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          hintText: widget.hintText,
          onChanged: widget.onChanged,
          borderless: true,
          prefixIcon: _prefixIcon,
          suffixIcon: widget.suffixIcon,
        ),
      ),
    );
  }

  Widget get _prefixIcon => Padding(
    padding: const EdgeInsets.only(left: 12, right: 4),
    child: PhosphorIcon(
      PhosphorIcons.magnifyingGlass(),
      size: 20,
      color: StyledTextField.borderColor,
    ),
  );
}
