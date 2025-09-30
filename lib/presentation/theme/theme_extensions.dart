import 'package:flutter/material.dart';

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

/// Context extension for easier theme access
extension BuildContextThemeExtension on BuildContext {
  /// Get current theme
  ThemeData get theme => Theme.of(this);
  
  /// Get current color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  /// Get current text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  /// Check if current theme is dark
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  
  /// Get theme-aware colors using the extension
  Color get surfaceColor => theme.surfaceColor;
  Color get onSurfaceColor => theme.onSurfaceColor;
  Color get primaryColor => theme.primaryColor;
  Color get onPrimaryColor => theme.onPrimaryColor;
  Color get secondaryColor => theme.secondaryColor;
  Color get errorColor => theme.errorColor;
  Color get successColor => theme.successColor;
  Color get outlineColor => theme.outlineColor;
  Color get surfaceVariantColor => theme.surfaceVariantColor;
  Color get onSurfaceVariantColor => theme.onSurfaceVariantColor;
}

/// Semantic color helpers for common use cases
class ThemeColors {
  const ThemeColors._();
  
  /// Get appropriate text color for the given background
  static Color getTextColorForBackground(BuildContext context, Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 
        ? context.colorScheme.onSurface 
        : context.colorScheme.surface;
  }
  
  /// Get disabled color based on theme
  static Color getDisabledColor(BuildContext context) {
    return context.colorScheme.onSurface.withValues(alpha: 0.38);
  }
  
  /// Get subtle background color
  static Color getSubtleBackground(BuildContext context) {
    return context.isDarkMode 
        ? context.colorScheme.surface.withValues(alpha: 0.05)
        : context.colorScheme.onSurface.withValues(alpha: 0.05);
  }
  
  /// Get overlay color for modals/dialogs
  static Color getOverlayColor(BuildContext context) {
    return context.isDarkMode 
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.black.withValues(alpha: 0.5);
  }
  
  /// Get border color
  static Color getBorderColor(BuildContext context) {
    return context.colorScheme.outline.withValues(alpha: 0.2);
  }
  
  /// Get divider color
  static Color getDividerColor(BuildContext context) {
    return context.colorScheme.outline.withValues(alpha: 0.12);
  }
}