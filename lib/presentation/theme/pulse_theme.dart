import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pulse_colors.dart';

/// Modern theme configuration for Pulse Dating App
/// Implements Material Design 3 with custom Pulse branding
class PulseTheme {
  PulseTheme._();

  /// Light theme configuration
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color scheme based on Pulse brand colors
    colorScheme: const ColorScheme.light(
      primary: PulseColors.primary,
      onPrimary: Colors.white,
      primaryContainer: PulseColors.primaryContainer,
      onPrimaryContainer: PulseColors.primaryDark,

      secondary: PulseColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: PulseColors.secondaryContainer,
      onSecondaryContainer: PulseColors.secondaryDark,

      tertiary: PulseColors.success,
      onTertiary: Colors.white,
      tertiaryContainer: PulseColors.successContainer,
      onTertiaryContainer: PulseColors.successDark,

      error: PulseColors.error,
      onError: Colors.white,
      errorContainer: PulseColors.errorContainer,
      onErrorContainer: PulseColors.errorDark,

      surface: PulseColors.surface,
      onSurface: PulseColors.onSurface,
      surfaceContainerHighest: PulseColors.surfaceVariant,
      onSurfaceVariant: PulseColors.onSurfaceVariant,

      outline: PulseColors.outline,
      outlineVariant: PulseColors.outlineVariant,
    ),

    // Typography using custom text styles
    textTheme: const TextTheme(
      displayLarge: PulseTextStyles.displayLarge,
      displayMedium: PulseTextStyles.displayMedium,
      displaySmall: PulseTextStyles.displaySmall,
      headlineLarge: PulseTextStyles.headlineLarge,
      headlineMedium: PulseTextStyles.headlineMedium,
      headlineSmall: PulseTextStyles.headlineSmall,
      titleLarge: PulseTextStyles.titleLarge,
      titleMedium: PulseTextStyles.titleMedium,
      titleSmall: PulseTextStyles.titleSmall,
      bodyLarge: PulseTextStyles.bodyLarge,
      bodyMedium: PulseTextStyles.bodyMedium,
      bodySmall: PulseTextStyles.bodySmall,
      labelLarge: PulseTextStyles.labelLarge,
      labelMedium: PulseTextStyles.labelMedium,
      labelSmall: PulseTextStyles.labelSmall,
    ),

    // App bar theme with modern look
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: PulseElevations.low,
      backgroundColor: PulseColors.surface,
      foregroundColor: PulseColors.onSurface,
      surfaceTintColor: PulseColors.primary,
      centerTitle: false,
      titleTextStyle: PulseTextStyles.headlineSmall,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),

    // Card theme for consistent card styling
    cardTheme: CardThemeData(
      elevation: PulseElevations.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.card),
      ),
      margin: const EdgeInsets.all(PulseSpacing.sm),
      clipBehavior: Clip.antiAlias,
    ),

    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: PulseElevations.button,
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadii.button),
        ),
        textStyle: PulseTextStyles.labelLarge,
        minimumSize: const Size(120, 48),
      ),
    ),

    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.md,
          vertical: PulseSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadii.button),
        ),
        textStyle: PulseTextStyles.labelLarge,
      ),
    ),

    // Outlined button theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadii.button),
        ),
        textStyle: PulseTextStyles.labelLarge,
        side: const BorderSide(color: PulseColors.outline, width: 1.5),
        minimumSize: const Size(120, 48),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PulseColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PulseRadii.input),
        borderSide: const BorderSide(color: PulseColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PulseRadii.input),
        borderSide: const BorderSide(color: PulseColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PulseRadii.input),
        borderSide: const BorderSide(color: PulseColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PulseRadii.input),
        borderSide: const BorderSide(color: PulseColors.error),
      ),
      contentPadding: const EdgeInsets.all(PulseSpacing.md),
      labelStyle: PulseTextStyles.bodyMedium,
      hintStyle: PulseTextStyles.bodyMedium.copyWith(
        color: PulseColors.onSurfaceVariant,
      ),
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: PulseElevations.fab,
      shape: CircleBorder(),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      elevation: PulseElevations.medium,
      selectedItemColor: PulseColors.primary,
      unselectedItemColor: PulseColors.onSurfaceVariant,
      selectedLabelStyle: PulseTextStyles.labelSmall,
      unselectedLabelStyle: PulseTextStyles.labelSmall,
    ),

    // List tile theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: PulseSpacing.md,
        vertical: PulseSpacing.sm,
      ),
      titleTextStyle: PulseTextStyles.bodyLarge,
      subtitleTextStyle: PulseTextStyles.bodyMedium,
    ),

    // Dialog theme
    dialogTheme: DialogThemeData(
      elevation: PulseElevations.modal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.dialog),
      ),
      titleTextStyle: PulseTextStyles.headlineSmall,
      contentTextStyle: PulseTextStyles.bodyMedium,
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      elevation: PulseElevations.modal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(PulseRadii.bottomSheet),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    // Chip theme
    chipTheme: ChipThemeData(
      padding: const EdgeInsets.symmetric(
        horizontal: PulseSpacing.sm,
        vertical: PulseSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.md),
      ),
      labelStyle: PulseTextStyles.labelMedium,
    ),

    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return PulseColors.primary;
        }
        return PulseColors.onSurfaceVariant;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return PulseColors.primaryContainer;
        }
        return PulseColors.surfaceVariant;
      }),
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  /// Dark theme configuration - Enhanced with new color system
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Enhanced dark color scheme matching web design
    colorScheme: const ColorScheme.dark(
      primary: PulseColors.primary, // Keep brand purple consistent
      onPrimary: Colors.white,
      primaryContainer: PulseColors.primaryDark,
      onPrimaryContainer: PulseColors.primaryLight,

      secondary: PulseColors.secondary, // Keep cyan accent consistent
      onSecondary: Colors.white,
      secondaryContainer: PulseColors.secondaryDark,
      onSecondaryContainer: PulseColors.secondaryLight,

      tertiary: PulseColors.success, // Updated success color
      onTertiary: Colors.white,
      tertiaryContainer: PulseColors.successDark,
      onTertiaryContainer: PulseColors.successLight,

      error: PulseColors.error, // Updated error color
      onError: Colors.white,
      errorContainer: PulseColors.errorDark,
      onErrorContainer: PulseColors.errorLight,

      surface: PulseColors.surfaceDark, // Enhanced dark surface
      onSurface: PulseColors.onSurfaceDark,
      surfaceContainerHighest: PulseColors.surfaceVariantDark,
      onSurfaceVariant: PulseColors.onSurfaceVariantDark,

      outline: PulseColors.outline,
      outlineVariant: PulseColors.outlineVariant,
      
      // Enhanced background hierarchy
      surfaceContainer: PulseColors.surfaceVariantDark,
      surfaceContainerLow: PulseColors.surfaceDark,
      surfaceContainerLowest: Color(0xFF060A1F), // From web neutral-950
      background: PulseColors.surfaceDark,
      onBackground: PulseColors.onSurfaceDark,
    ),

    // Enhanced text theme with better contrast
    textTheme: TextTheme(
      displayLarge: PulseTextStyles.displayLarge.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      displayMedium: PulseTextStyles.displayMedium.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      displaySmall: PulseTextStyles.displaySmall.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      headlineLarge: PulseTextStyles.headlineLarge.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      headlineMedium: PulseTextStyles.headlineMedium.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      headlineSmall: PulseTextStyles.headlineSmall.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      titleLarge: PulseTextStyles.titleLarge.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      titleMedium: PulseTextStyles.titleMedium.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      titleSmall: PulseTextStyles.titleSmall.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      bodyLarge: PulseTextStyles.bodyLarge.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      bodyMedium: PulseTextStyles.bodyMedium.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      bodySmall: PulseTextStyles.bodySmall.copyWith(
        color: PulseColors.onSurfaceVariantDark,
      ),
      labelLarge: PulseTextStyles.labelLarge.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      labelMedium: PulseTextStyles.labelMedium.copyWith(
        color: PulseColors.onSurfaceDark,
      ),
      labelSmall: PulseTextStyles.labelSmall.copyWith(
        color: PulseColors.onSurfaceVariantDark,
      ),
    ),

    // Enhanced dark app bar with better visual hierarchy
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: PulseElevations.low,
      backgroundColor: PulseColors.surfaceDark,
      foregroundColor: PulseColors.onSurfaceDark,
      surfaceTintColor: PulseColors.primary,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: PulseColors.onSurfaceDark,
      ),
      systemOverlayStyle:
          SystemUiOverlayStyle.light, // Light status bar for dark theme
    ),

    // Enhanced card theme for dark mode
    cardTheme: CardThemeData(
      elevation: PulseElevations.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.card),
      ),
      margin: const EdgeInsets.all(PulseSpacing.sm),
      clipBehavior: Clip.antiAlias,
      color: PulseColors.surfaceVariantDark, // Better contrast in dark mode
    ),

    // Rest of component themes stay the same with automatic color adaptation
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: PulseElevations.button,
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadii.button),
        ),
        textStyle: PulseTextStyles.labelLarge,
        minimumSize: const Size(120, 48),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: PulseSpacing.lg,
          vertical: PulseSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PulseRadii.button),
        ),
        textStyle: PulseTextStyles.labelLarge,
        minimumSize: const Size(120, 48),
      ),
    ),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Design system constants for consistent spacing, elevation, and radii
class PulseSpacing {
  PulseSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class PulseElevations {
  PulseElevations._();

  static const double none = 0.0;
  static const double low = 1.0;
  static const double card = 2.0;
  static const double button = 1.0;
  static const double medium = 4.0;
  static const double fab = 6.0;
  static const double modal = 8.0;
  static const double drawer = 16.0;
}

class PulseRadii {
  PulseRadii._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double button = 12.0;
  static const double card = 16.0;
  static const double input = 8.0;
  static const double dialog = 24.0;
  static const double bottomSheet = 24.0;
  static const double sheet = 24.0;
  static const double circle = 999.0;
}
