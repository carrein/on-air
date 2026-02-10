import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;

/// Styled tooltip component with consistent brand styling.
///
/// Features:
/// - Custom styling: white background, pink border, Space Grotesk 12px text
/// - 500ms hover delay before showing
/// - Auto-positioning
/// - Disabled on mobile devices (only shown on desktop/web with mouse)
///
/// Usage:
/// ```dart
/// StyledTooltip(
///   message: 'Delete note',
///   child: IconButton(...),
/// )
/// ```
class StyledTooltip extends StatelessWidget {
  /// The tooltip message to display
  final String message;

  /// The child widget that triggers the tooltip on hover
  final Widget child;

  const StyledTooltip({
    super.key,
    required this.message,
    required this.child,
  });

  /// Check if we're on a mobile platform (tooltips disabled on mobile)
  bool get _isMobile {
    if (kIsWeb) return false; // Web is always desktop-like for tooltips
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show tooltips on mobile devices
    if (_isMobile) {
      return child;
    }

    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFFF52A1), // brand.accent
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      textStyle: GoogleFonts.spaceGrotesk(
        color: const Color(0xFF00171F), // core.background
        fontSize: 12,
      ),
      child: child,
    );
  }
}
