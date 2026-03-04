import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Shared search text field with consistent Memoka styling.
///
/// Accent-colored magnifying glass prefix, bordered outline, optional clear
/// suffix icon. Used by desktop search bar, mobile search input, and GIF picker.
class StyledSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? suffixIcon;

  const StyledSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText = 'Search...',
    this.onChanged,
    this.autofocus = false,
    this.suffixIcon,
  });

  static const _backgroundColor = Color(0xFFF6F0ED);
  static const _borderColor = Color(0xFFCE2161);
  static const _textColor = Color(0xFF00171F);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      style: GoogleFonts.spaceGrotesk(color: _textColor, fontSize: 14),
      cursorColor: _borderColor,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
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
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _backgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _borderColor, width: 1),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _borderColor, width: 1),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: _borderColor, width: 1),
        ),
      ),
    );
  }
}
