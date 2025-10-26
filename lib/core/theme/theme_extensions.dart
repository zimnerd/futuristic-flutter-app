import 'dart:math';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme extensions to provide easy access to theme-aware colors
/// This helps implement DRY principle and ensures consistent theme handling
extension PulseThemeExtension on ThemeData {
  /// Get theme-aware surface color
  Color get surfaceColor => colorScheme.surface;

  /// Get theme-aware on-surface color
  Color get onSurfaceColor => colorScheme.onSurface;

  /// Get theme-aware primary color
  Color get primaryColor => colorScheme.primary;

  /// Get theme-aware on-primary color
  Color get onPrimaryColor => colorScheme.onPrimary;

  /// Get theme-aware secondary color
  Color get secondaryColor => colorScheme.secondary;

  /// Get theme-aware error color
  Color get errorColor => colorScheme.error;

  /// Get theme-aware success color (tertiary)
  Color get successColor => colorScheme.tertiary;

  /// Get theme-aware outline color
  Color get outlineColor => colorScheme.outline;

  /// Get theme-aware surface variant color
  Color get surfaceVariantColor => colorScheme.surfaceContainerHighest;

  /// Get theme-aware on-surface variant color
  Color get onSurfaceVariantColor => colorScheme.onSurfaceVariant;
}

/// Theme-aware color extensions for BuildContext
/// 
/// Usage:
/// ```dart
/// Color textColor = context.onSurfaceColor;  // Automatically adapts to theme
/// bool isDark = context.isDarkMode;
/// ```
extension BuildContextThemeExtension on BuildContext {
  /// Check if currently in dark mode
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Get current theme data
  ThemeData get theme => Theme.of(this);

  /// Get color scheme
  ColorScheme get colorScheme => theme.colorScheme;
  
  // ============= QUICK ACCESS TO COMMON COLORS =============

  // ============= PRIMARY SURFACE COLORS =============

  /// Main surface/background color
  /// Light: White (#FFFFFF)
  /// Dark: Dark Navy (#0A0F2D)
  Color get surfaceColor => colorScheme.surface;

  /// Elevated card/sheet color
  /// Light: White (#FFFFFF)
  /// Dark: Slightly elevated (#202124)
  Color get surfaceElevated =>
      isDarkMode ? const Color(0xFF202124) : Colors.white;

  /// Lowest background (page background)
  /// Light: Off-white (#F8F9FA)
  /// Dark: Dark Navy (#0A0F2D)
  Color get backgroundColor =>
      isDarkMode ? AppColors.background : const Color(0xFFF8F9FA);

  /// Surface variant color - used for secondary surfaces
  Color get surfaceVariantColor => colorScheme.surfaceContainerHighest;

  // ============= TEXT COLORS (HIERARCHY) =============

  /// Primary text - High emphasis, always visible
  /// Used for: Headlines, important content
  /// Contrast: 7:1 (WCAG AAA)
  Color get textPrimary => colorScheme.onSurface;

  /// Alias for textPrimary - onSurface color for compatibility
  Color get onSurfaceColor => colorScheme.onSurface;

  /// Secondary text - Medium emphasis, supporting content
  /// Used for: Descriptions, subtitles, meta information
  /// Contrast: 4.5:1 (WCAG AA)
  Color get textSecondary => colorScheme.onSurfaceVariant;

  /// Alias for textSecondary - onSurfaceVariant color for compatibility
  Color get onSurfaceVariantColor => colorScheme.onSurfaceVariant;

  /// Tertiary text - Low emphasis, disabled/inactive content
  /// Used for: Hints, disabled state, timestamps
  /// Contrast: 3:1 (minimum)
  Color get textTertiary =>
      isDarkMode ? const Color(0xFF8C8CA1) : AppColors.textSecondary;

  /// Text on interactive elements (buttons, etc.)
  Color get textOnPrimary => colorScheme.onPrimary;

  // ============= BORDER & DIVIDER COLORS =============

  /// Primary border color for form fields and cards
  /// Light: Light Gray (#DADCe0)
  /// Dark: Medium Gray (#5F6368)
  Color get borderColor => colorScheme.outline;

  /// Alias for borderColor - outline color for compatibility
  Color get outlineColor => colorScheme.outline;

  /// Light border - Used for subtle dividers
  /// Light: Very Light Gray (#DADCE0)
  /// Dark: Dark Gray (#3C4043)
  Color get borderLight => colorScheme.outlineVariant;

  /// Divider color - Used in lists and separators
  Color get dividerColor =>
      isDarkMode
          ? AppColors.border.withOpacity(0.2)
          : AppColors.borderLight.withOpacity(0.3);

  // ============= INTERACTIVE ELEMENT COLORS =============

  /// Primary action color (buttons, etc.)
  Color get primaryColor => colorScheme.primary;

  /// Secondary/accent color (highlights, accents)
  Color get accentColor => colorScheme.secondary;

  /// Success color (confirmations, positive actions)
  Color get successColor => colorScheme.tertiary;

  /// Error color (errors, destructive actions)
  Color get errorColor => colorScheme.error;

  /// Disabled/inactive element color
  /// Light: Light Gray (#BDC1C6)
  /// Dark: Medium Gray (#5F6368)
  Color get disabledColor =>
      isDarkMode ? const Color(0xFF8C8CA1) : AppColors.textSecondary;

  /// Disabled text color
  Color get disabledTextColor =>
      isDarkMode
          ? const Color(0xFF8C8CA1).withOpacity(0.6)
          : const Color(0xFF8C8CA1);

  // ============= FORM FIELD COLORS =============

  /// Form field background
  /// Light: Very light gray
  /// Dark: Surface with slight elevation
  Color get formFieldBackground =>
      isDarkMode ? surfaceElevated : const Color(0xFFF8F9FA);

  /// Form field border - input focus
  Color get formFieldBorder => borderColor;

  /// Form field border - focused state
  Color get formFieldBorderFocused => primaryColor;

  /// Form field placeholder/hint text
  Color get formFieldHint =>
      isDarkMode ? const Color(0xFF8C8CA1) : AppColors.textSecondary;

  /// Form field filled state (checked, selected)
  Color get formFieldFilled =>
      isDarkMode ? primaryColor.withOpacity(0.12) : primaryColor.withOpacity(0.08);

  // ============= CHIP & BADGE COLORS =============

  /// Chip background
  Color get chipBackground =>
      isDarkMode ? const Color(0xFF3C4043) : const Color(0xFFE8EAED);

  /// Chip text color
  Color get chipText =>
      isDarkMode ? AppColors.textPrimary : const Color(0xFF0A0F2D);

  /// Selected chip background
  Color get chipSelectedBackground => primaryColor;

  /// Selected chip text
  Color get chipSelectedText => colorScheme.onPrimary;

  // ============= CARD & SHEET COLORS =============

  /// Card background
  Color get cardBackground => surfaceElevated;

  /// Card border
  Color get cardBorder => borderLight;

  // ============= GLASS MORPHISM COLORS =============

  /// Glass morphism surface (for frosted glass effect)
  /// Light: White with opacity
  /// Dark: White with less opacity
  Color get glassSurface =>
      isDarkMode
          ? AppColors.glassSurface.withOpacity(0.08)
          : AppColors.glassSurface;

  /// Glass morphism border
  Color get glassBorder =>
      isDarkMode
          ? AppColors.glassBorder.withOpacity(0.15)
          : AppColors.glassBorder;

  // ============= SHADOW COLORS =============

  /// Shadow color for elevation
  /// Adapts based on background brightness
  Color get shadowColor =>
      isDarkMode ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);

  // ============= UTILITY METHODS =============

  /// Get color with theme-aware opacity
  /// Useful for: disabled states, overlays
  Color withThemeOpacity(Color color, double opacity) {
    return color.withOpacity(isDarkMode ? opacity * 0.8 : opacity);
  }

  /// Blend two colors based on theme
  /// Light mode: blend towards light
  /// Dark mode: blend towards dark
  Color blendWithTheme(Color color, {double lightness = 0.5}) {
    final hslColor = HSLColor.fromColor(color);
    final newLightness = isDarkMode
        ? hslColor.lightness * (1 - lightness)
        : hslColor.lightness + ((1 - hslColor.lightness) * lightness);
    
    return hslColor.withLightness(newLightness).toColor();
  }

  /// Get overlay color for bottom sheets and dialogs
  Color get overlayColor =>
      isDarkMode ? Colors.black45 : Colors.black26;

  // ============= STATUS COLORS =============
  // Used for upload/sync/processing states

  /// Info status color (processing, in progress)
  /// Light: Bright Blue
  /// Dark: Lighter Blue for visibility
  Color get statusInfo =>
      isDarkMode ? const Color(0xFF42A5F5) : const Color(0xFF2196F3);

  /// Warning status color (paused, attention needed)
  /// Light: Orange
  /// Dark: Lighter Orange for visibility
  Color get statusWarning =>
      isDarkMode ? const Color(0xFFFFA726) : AppColors.warning;

  /// Cancelled/stopped status color
  /// Light: Deep Orange
  /// Dark: Lighter Orange-Red for visibility
  Color get statusCancelled =>
      isDarkMode ? const Color(0xFFFF7043) : const Color(0xFFFF5722);

  // ============= PRIORITY COLORS =============
  // Used for safety tips, notifications, importance indicators

  /// High priority/danger indicator
  /// Light: Error Red
  /// Dark: Lighter Red for visibility
  Color get priorityHigh =>
      isDarkMode ? const Color(0xFFEF5350) : AppColors.error;

  /// Medium priority/warning indicator
  /// Light: Warning Orange
  /// Dark: Lighter Orange for visibility
  Color get priorityMedium =>
      isDarkMode ? const Color(0xFFFFA726) : AppColors.warning;

  /// Low priority/success indicator
  /// Light: Success Green
  /// Dark: Lighter Green for visibility
  Color get priorityLow =>
      isDarkMode ? const Color(0xFF66BB6A) : AppColors.success;

  // ============= CATEGORY COLORS =============
  // Used for categorization, tagging, grouping

  /// Neutral/general category
  /// Light: Blue
  /// Dark: Lighter Blue for visibility
  Color get categoryNeutral =>
      isDarkMode ? const Color(0xFF42A5F5) : const Color(0xFF2196F3);

  /// Danger/critical category
  /// Light: Red
  /// Dark: Lighter Red for visibility
  Color get categoryDanger =>
      isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFF44336);

  /// General/misc category
  /// Light: Purple
  /// Dark: Lighter Purple for visibility
  Color get categoryGeneral =>
      isDarkMode ? const Color(0xFFAB47BC) : const Color(0xFF9C27B0);

  // ============= RECORDING/MEDIA STATE COLORS =============
  // Used for voice recorder, video recording, live streaming

  /// Active recording state
  /// Light: Bright Red
  /// Dark: Lighter Red for visibility
  Color get recordingActive =>
      isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFFF3B5C);

  /// Paused recording state
  /// Light: Orange
  /// Dark: Lighter Orange for visibility
  Color get recordingPaused =>
      isDarkMode ? const Color(0xFFFFA726) : const Color(0xFFFF9800);

  /// Ready/stopped recording state (safe to proceed)
  /// Light: Green
  /// Dark: Lighter Green for visibility
  Color get recordingReady =>
      isDarkMode ? const Color(0xFF66BB6A) : AppColors.success;

  // ============= SWIPE/INTERACTION COLORS =============
  // Used for swipe cards, gestures, quick actions

  /// Like/accept action color
  /// Light: Green
  /// Dark: Lighter Green for visibility
  Color get swipeLike =>
      isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);

  /// Dislike/reject action color
  /// Light: Red-Orange
  /// Dark: Lighter Red-Orange for visibility
  Color get swipeNope =>
      isDarkMode ? const Color(0xFFFF7043) : const Color(0xFFFF5722);

  /// Super like/special action color
  /// Light: Blue
  /// Dark: Lighter Blue for visibility
  Color get swipeSuperLike =>
      isDarkMode ? const Color(0xFF42A5F5) : const Color(0xFF2196F3);

  // ============= ANALYTICS/PERFORMANCE COLORS =============
  // Used for metrics, charts, performance indicators

  /// Excellent performance indicator
  /// Light: Bright Green
  /// Dark: Lighter Green for visibility
  Color get performanceExcellent =>
      isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);

  /// Good performance indicator
  /// Light: Light Green
  /// Dark: Lighter variant for visibility
  Color get performanceGood =>
      isDarkMode ? const Color(0xFF9CCC65) : const Color(0xFF8BC34A);

  /// Moderate performance indicator
  /// Light: Orange
  /// Dark: Lighter Orange for visibility
  Color get performanceModerate =>
      isDarkMode ? const Color(0xFFFFA726) : const Color(0xFFFF9800);

  /// Poor performance indicator
  /// Light: Red
  /// Dark: Lighter Red for visibility
  Color get performancePoor =>
      isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFF44336);

  /// Neutral performance indicator (no data/baseline)
  /// Light: Grey
  /// Dark: Lighter Grey for visibility
  Color get performanceNeutral =>
      isDarkMode ? const Color(0xFFBDBDBD) : const Color(0xFF9E9E9E);

  // ============= PREMIUM/SPECIAL FEATURE COLORS =============
  // Used for premium badges, boost features, special highlights

  /// Premium/gold color
  /// Light: Gold
  /// Dark: Lighter Gold for visibility
  Color get premiumGold =>
      isDarkMode ? const Color(0xFFFFD54F) : AppColors.premium;

  /// Premium gradient start color
  /// Light: Gold
  /// Dark: Lighter Gold for visibility
  Color get premiumGradientStart =>
      isDarkMode ? const Color(0xFFFFD54F) : const Color(0xFFFFD700);

  /// Premium gradient end color
  /// Light: Orange
  /// Dark: Lighter Orange for visibility
  Color get premiumGradientEnd =>
      isDarkMode ? const Color(0xFFFFA726) : const Color(0xFFFF9900);

  // ============= MEDIA VIEWER COLORS =============
  // Used for photo/video viewers, full-screen media

  /// Media viewer background (dark in both modes for immersion)
  Color get mediaViewerBackground => Colors.black;

  /// Media viewer controls background (semi-transparent)
  Color get mediaViewerControls =>
      Colors.white.withValues(alpha: isDarkMode ? 0.5 : 0.6);

  /// Media viewer overlay (for headers/footers)
  Color get mediaViewerOverlay =>
      Colors.black.withValues(alpha: isDarkMode ? 0.6 : 0.7);

  /// Media viewer text (always white for contrast on dark bg)
  Color get mediaViewerText => Colors.white;

  /// Media viewer secondary text (slightly dimmed)
  Color get mediaViewerTextSecondary =>
      Colors.white.withValues(alpha: 0.7);

  // ============= CALL SCREEN COLORS =============
  // Used for incoming/outgoing calls with glassmorphism

  /// Call accept action color
  /// Light: Green
  /// Dark: Lighter Green for visibility
  Color get callAccept =>
      isDarkMode ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);

  /// Call decline/end action color
  /// Light: Red
  /// Dark: Lighter Red for visibility
  Color get callDecline =>
      isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFF44336);

  /// Call screen overlay text (always white for glassmorphism)
  Color get callOverlayText => Colors.white;

  /// Call screen secondary text (slightly dimmed white)
  Color get callOverlayTextSecondary =>
      Colors.white.withValues(alpha: 0.7);

  // ============= GRADIENT HELPERS =============
  // Pre-defined gradients for common use cases

  /// Brand gradient (primary to accent)
  LinearGradient get brandGradient => AppColors.brandGradient;

  /// Success gradient (success to accent)
  LinearGradient get successGradient => AppColors.successGradient;

  /// Premium gradient (gold to orange)
  LinearGradient get premiumGradient => LinearGradient(
        colors: [premiumGradientStart, premiumGradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Danger gradient (for warnings/errors)
  LinearGradient get dangerGradient => LinearGradient(
        colors: [
          isDarkMode ? const Color(0xFFEF5350) : const Color(0xFFF44336),
          isDarkMode ? const Color(0xFFFF7043) : const Color(0xFFFF5722),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Material 3 specific extensions (if using Material Design 3)
extension Material3Colors on BuildContext {
  /// Surface container colors for elevation levels
  /// Level 0: surface
  /// Level 1: surfaceContainer
  /// Level 2: surfaceContainerHigh
  /// Level 3: surfaceContainerHighest
  
  Color get surfaceContainer =>
      isDarkMode
          ? const Color(0xFF1A1F33)
          : const Color(0xFFF8F9FA);

  Color get surfaceContainerHigh =>
      isDarkMode
          ? const Color(0xFF202124)
          : const Color(0xFFF1F3F4);

  Color get surfaceContainerHighest =>
      isDarkMode
          ? const Color(0xFF2D3136)
          : const Color(0xFFEAEEF1);
}

/// Material 2 Color Shade compatibility extension
/// Provides Material 2 shade-like colors for Material 3 colors
extension Material2ShadeCompat on Color {
  /// Get a shaded variant of this color (Material 2 style)
  /// shade50 = very light, shade900 = very dark
  Color get shade50 => withValues(alpha: 0.1);
  Color get shade100 => withValues(alpha: 0.15);
  Color get shade200 => withValues(alpha: 0.25);
  Color get shade300 => withValues(alpha: 0.35);
  Color get shade400 => withValues(alpha: 0.45);
  Color get shade500 => withValues(alpha: 0.5);
  Color get shade600 => withValues(alpha: 0.65);
  Color get shade700 => withValues(alpha: 0.75);
  Color get shade800 => withValues(alpha: 0.85);
  Color get shade900 => withValues(alpha: 0.95);
}

/// Contrast checker utility - helps ensure accessibility
/// Usage: context.checkContrast(textColor, backgroundColor)
extension AccessibilityHelper on BuildContext {
  /// Simple contrast ratio calculator
  /// Returns true if contrast ratio is >= 4.5:1 (WCAG AA)
  bool checkContrast(Color text, Color bg) {
    final textLum = _calculateLuminance(text);
    final bgLum = _calculateLuminance(bg);
    
    final lighter = textLum > bgLum ? textLum : bgLum;
    final darker = textLum > bgLum ? bgLum : textLum;
    
    final contrastRatio = (lighter + 0.05) / (darker + 0.05);
    return contrastRatio >= 4.5; // WCAG AA standard
  }

  double _calculateLuminance(Color color) {
    final r = _relativeLuminance(color.red);
    final g = _relativeLuminance(color.green);
    final b = _relativeLuminance(color.blue);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  double _relativeLuminance(int component) {
    final c = component / 255.0;
    return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.0).toDouble();
  }

  /// Debug helper - Print contrast info to console
  void debugPrintContrast(Color text, Color bg, String elementName) {
    final ratio = _getContrastRatio(text, bg);
    debugPrint(
      '🎨 [$elementName] Contrast Ratio: ${ratio.toStringAsFixed(2)}:1 '
      '${ratio >= 4.5 ? '✅' : '❌'}',
    );
  }

  double _getContrastRatio(Color text, Color bg) {
    final textLum = _calculateLuminance(text);
    final bgLum = _calculateLuminance(bg);
    
    final lighter = textLum > bgLum ? textLum : bgLum;
    final darker = textLum > bgLum ? bgLum : textLum;
    
    return (lighter + 0.05) / (darker + 0.05);
  }
}
