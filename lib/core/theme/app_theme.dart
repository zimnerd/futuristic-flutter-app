import 'package:flutter/material.dart';

/// Pulse Dating App Brand Colors
/// Based on the web app color scheme
class PulseColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6E3BFF); // Purple
  static const Color primaryLight = Color(0xFF8B5FFF);
  static const Color primaryDark = Color(0xFF5729CC);

  // Accent colors
  static const Color accent = Color(0xFF00C2FF); // Cyan
  static const Color accentLight = Color(0xFF33D1FF);
  static const Color accentDark = Color(0xFF0099CC);

  // Success color
  static const Color success = Color(0xFF00D4AA); // Green
  static const Color successLight = Color(0xFF33DDBB);
  static const Color successDark = Color(0xFF00A688);

  // Error colors
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorLight = Color(0xFFFF8888);
  static const Color errorDark = Color(0xFFCC5555);

  // Warning colors
  static const Color warning = Color(0xFFFFB800);
  static const Color warningLight = Color(0xFFFFC533);
  static const Color warningDark = Color(0xFFCC9200);

  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // Dating app specific colors
  static const Color like = success;
  static const Color pass = grey400;
  static const Color superLike = warning;
  static const Color premium = primary;
  static const Color verified = accent;
  static const Color online = success;
  static const Color away = warning;
  static const Color offline = grey400;

  // Glassmorphism colors
  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);
}

/// Typography configuration for Pulse Dating App
class PulseTextStyles {
  // Font families
  static const String headingFont = 'SpaceGrotesk';
  static const String bodyFont = 'Inter';

  // Display text styles (largest)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: headingFont,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    height: 1.22,
  );

  // Headline text styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: headingFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: headingFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: headingFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // Title text styles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  // Body text styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  // Label text styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
  );
}

/// Theme configuration for Pulse Dating App
class PulseTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      cardTheme: _cardTheme,
      bottomNavigationBarTheme: _bottomNavigationBarTheme,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      chipTheme: _chipTheme,
      dialogTheme: _dialogTheme,
      snackBarTheme: _snackBarTheme,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      textTheme: _textTheme,
      appBarTheme: _appBarThemeDark,
      elevatedButtonTheme: _elevatedButtonTheme,
      textButtonTheme: _textButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: _inputDecorationThemeDark,
      cardTheme: _cardThemeDark,
      bottomNavigationBarTheme: _bottomNavigationBarThemeDark,
      floatingActionButtonTheme: _floatingActionButtonTheme,
      chipTheme: _chipThemeDark,
      dialogTheme: _dialogThemeDark,
      snackBarTheme: _snackBarTheme,
    );
  }

  /// Light color scheme
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: PulseColors.primary,
    onPrimary: PulseColors.white,
    secondary: PulseColors.accent,
    onSecondary: PulseColors.white,
    tertiary: PulseColors.success,
    onTertiary: PulseColors.white,
    error: PulseColors.error,
    onError: PulseColors.white,
    surface: PulseColors.white,
    onSurface: PulseColors.grey900,
    surfaceContainerHighest: PulseColors.grey50,
    onSurfaceVariant: PulseColors.grey600,
    outline: PulseColors.grey300,
    outlineVariant: PulseColors.grey200,
    shadow: PulseColors.black,
    scrim: PulseColors.black,
    inverseSurface: PulseColors.grey900,
    onInverseSurface: PulseColors.grey50,
    inversePrimary: PulseColors.primaryLight,
  );

  /// Dark color scheme
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: PulseColors.primaryLight,
    onPrimary: PulseColors.grey900,
    secondary: PulseColors.accentLight,
    onSecondary: PulseColors.grey900,
    tertiary: PulseColors.successLight,
    onTertiary: PulseColors.grey900,
    error: PulseColors.errorLight,
    onError: PulseColors.grey900,
    surface: PulseColors.grey900,
    onSurface: PulseColors.grey100,
    surfaceContainerHighest: PulseColors.grey800,
    onSurfaceVariant: PulseColors.grey400,
    outline: PulseColors.grey600,
    outlineVariant: PulseColors.grey700,
    shadow: PulseColors.black,
    scrim: PulseColors.black,
    inverseSurface: PulseColors.grey100,
    onInverseSurface: PulseColors.grey900,
    inversePrimary: PulseColors.primary,
  );

  /// Text theme
  static const TextTheme _textTheme = TextTheme(
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
  );

  /// App bar theme
  static const AppBarTheme _appBarTheme = AppBarTheme(
    backgroundColor: PulseColors.white,
    foregroundColor: PulseColors.grey900,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: PulseTextStyles.titleLarge,
  );

  static const AppBarTheme _appBarThemeDark = AppBarTheme(
    backgroundColor: PulseColors.grey900,
    foregroundColor: PulseColors.grey100,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: PulseTextStyles.titleLarge,
  );

  /// Button themes
  static final ElevatedButtonThemeData _elevatedButtonTheme =
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          foregroundColor: PulseColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: PulseTextStyles.labelLarge,
        ),
      );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: PulseColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: PulseTextStyles.labelLarge,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PulseColors.primary,
          side: const BorderSide(color: PulseColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: PulseTextStyles.labelLarge,
        ),
      );

  /// Input decoration theme
  static const InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.error),
        ),
        filled: true,
        fillColor: PulseColors.grey50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  static const InputDecorationTheme _inputDecorationThemeDark =
      InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.grey600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.grey600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: PulseColors.errorLight),
        ),
        filled: true,
        fillColor: PulseColors.grey800,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  /// Card theme
  static const CardThemeData _cardTheme = CardThemeData(
    color: PulseColors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    margin: EdgeInsets.all(8),
  );

  static const CardThemeData _cardThemeDark = CardThemeData(
    color: PulseColors.grey800,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    margin: EdgeInsets.all(8),
  );

  /// Bottom navigation bar theme
  static const BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
        backgroundColor: PulseColors.white,
        selectedItemColor: PulseColors.primary,
        unselectedItemColor: PulseColors.grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  static const BottomNavigationBarThemeData _bottomNavigationBarThemeDark =
      BottomNavigationBarThemeData(
        backgroundColor: PulseColors.grey900,
        selectedItemColor: PulseColors.primaryLight,
        unselectedItemColor: PulseColors.grey500,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      );

  /// Floating action button theme
  static const FloatingActionButtonThemeData _floatingActionButtonTheme =
      FloatingActionButtonThemeData(
        backgroundColor: PulseColors.primary,
        foregroundColor: PulseColors.white,
        elevation: 4,
        shape: CircleBorder(),
      );

  /// Chip theme
  static const ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: PulseColors.grey100,
    selectedColor: PulseColors.primary,
    labelStyle: PulseTextStyles.labelMedium,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  );

  static const ChipThemeData _chipThemeDark = ChipThemeData(
    backgroundColor: PulseColors.grey700,
    selectedColor: PulseColors.primaryLight,
    labelStyle: PulseTextStyles.labelMedium,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
  );

  /// Dialog theme
  static const DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: PulseColors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 8,
  );

  static const DialogThemeData _dialogThemeDark = DialogThemeData(
    backgroundColor: PulseColors.grey800,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 8,
  );

  /// Snack bar theme
  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: PulseColors.grey800,
    contentTextStyle: TextStyle(color: PulseColors.white),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    behavior: SnackBarBehavior.floating,
  );
}
