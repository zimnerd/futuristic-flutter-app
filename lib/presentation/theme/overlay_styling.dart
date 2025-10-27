import 'package:flutter/material.dart';

/// Helper class for theme-aware overlay styling
/// Provides gradients and text styles that work in both light and dark modes
class OverlayStyling {
  /// Returns a theme-aware gradient overlay for profile cards
  /// Light mode: Dark overlay (current) for readability on light backgrounds
  /// Dark mode: Light overlay to maintain readability on dark backgrounds
  static LinearGradient getOverlayGradient(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isDarkMode) {
      // DARK MODE: Light gradient overlay (white-based)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.15),
        ],
      );
    } else {
      // LIGHT MODE: Dark gradient overlay (black-based)
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.5),
          Colors.black.withValues(alpha: 0.85),
        ],
      );
    }
  }

  /// Returns gradient for top-to-bottom fade (profile header)
  static LinearGradient getTopFadeGradient(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isDarkMode) {
      // DARK MODE: Light fade from top
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      );
    } else {
      // LIGHT MODE: Dark fade from top
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          Colors.black.withValues(alpha: 0.4),
          Colors.black.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6],
      );
    }
  }

  /// Returns text color for overlay text
  /// Ensures contrast against the overlay gradient
  static Color getOverlayTextColor(BuildContext context) {
    // Use white for both modes - it contrasts well with both
    // dark overlay (light mode) and light overlay (dark mode)
    return Colors.white;
  }

  /// Returns shadow color for text shadows (for better readability)
  static Color getTextShadowColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode
        ? Colors.black.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.5);
  }

  /// Returns text style for profile name on overlay
  static TextStyle getProfileNameStyle(BuildContext context) {
    return TextStyle(
      color: getOverlayTextColor(context),
      fontSize: 24,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(
          color: getTextShadowColor(context),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Returns text style for profile subtitle/bio
  static TextStyle getProfileSubtitleStyle(BuildContext context) {
    return TextStyle(
      color: getOverlayTextColor(context).withValues(alpha: 0.95),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      shadows: [
        Shadow(
          color: getTextShadowColor(context),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Returns text style for profile details (location, occupation, etc.)
  static TextStyle getProfileDetailsStyle(BuildContext context) {
    return TextStyle(
      color: getOverlayTextColor(context).withValues(alpha: 0.9),
      fontSize: 13,
      fontWeight: FontWeight.w400,
      shadows: [
        Shadow(
          color: getTextShadowColor(context),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Returns a box decoration for overlay container
  static BoxDecoration getOverlayDecoration(
    BuildContext context, {
    bool showBorder = false,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: getOverlayGradient(context),
      border: showBorder
          ? Border(
              top: BorderSide(
                color: Colors.white.withValues(
                  alpha: isDarkMode ? 0.2 : 0.1,
                ),
                width: 1,
              ),
            )
          : null,
    );
  }

  /// Returns shadow for overlay container
  static List<BoxShadow> getOverlayShadow(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return [
      BoxShadow(
        color: (isDarkMode ? Colors.black : Colors.black)
            .withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ];
  }

  /// Returns padding for overlay content
  static EdgeInsets getOverlayPadding() {
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}
