import 'package:flutter/material.dart';

/// Responsive breakpoint utilities for adaptive layouts.
class ResponsiveUtils {
  // Breakpoint constants
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1200.0;

  /// Check if the current screen width is mobile (< 768px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if the current screen width is tablet (768-1199px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if the current screen width is desktop (≥ 1200px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if media panel should be visible by default (desktop only)
  static bool shouldShowMediaPanel(BuildContext context) {
    return isDesktop(context);
  }

  /// Get the number of grid columns based on screen width
  static int getGridColumnCount(BuildContext context, {bool isDocument = false}) {
    if (isDocument) {
      // Documents: 2 columns on desktop, 1 on mobile
      return isDesktop(context) ? 2 : 1;
    } else {
      // Images/Videos: 3 columns on desktop, 2 on tablet, 2 on mobile
      if (isDesktop(context)) return 3;
      return 2;
    }
  }

  /// Get appropriate spacing for grid items
  static double getGridSpacing(BuildContext context) {
    return isMobile(context) ? 8.0 : 12.0;
  }
}
