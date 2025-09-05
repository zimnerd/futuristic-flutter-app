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
      surfaceVariant: PulseColors.surfaceVariant,
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

  /// Dark theme configuration
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // Dark color scheme
    colorScheme: const ColorScheme.dark(
      primary: PulseColors.primaryLight,
      onPrimary: PulseColors.onSurface,
      primaryContainer: PulseColors.primaryDark,
      onPrimaryContainer: PulseColors.primaryLight,

      secondary: PulseColors.secondaryLight,
      onSecondary: PulseColors.onSurface,
      secondaryContainer: PulseColors.secondaryDark,
      onSecondaryContainer: PulseColors.secondaryLight,

      tertiary: PulseColors.successLight,
      onTertiary: PulseColors.onSurface,
      tertiaryContainer: PulseColors.successDark,
      onTertiaryContainer: PulseColors.successLight,

      error: PulseColors.errorLight,
      onError: PulseColors.onSurface,
      errorContainer: PulseColors.errorDark,
      onErrorContainer: PulseColors.errorLight,

      surface: PulseColors.surfaceDark,
      onSurface: PulseColors.onSurfaceDark,
      surfaceVariant: PulseColors.surfaceVariantDark,
      onSurfaceVariant: PulseColors.onSurfaceVariantDark,

      outline: PulseColors.outline,
      outlineVariant: PulseColors.outlineVariant,
    ),

    // Use the same component themes as light with automatic color adaptation
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

    // Dark app bar
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: PulseElevations.low,
      backgroundColor: PulseColors.surfaceDark,
      foregroundColor: PulseColors.onSurfaceDark,
      surfaceTintColor: PulseColors.primaryLight,
      centerTitle: false,
      titleTextStyle: PulseTextStyles.headlineSmall,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),

    // Same component themes as light theme (will automatically adapt to dark colors)
    cardTheme: CardThemeData(
      elevation: PulseElevations.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PulseRadii.card),
      ),
      margin: const EdgeInsets.all(PulseSpacing.sm),
      clipBehavior: Clip.antiAlias,
    ),

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

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
