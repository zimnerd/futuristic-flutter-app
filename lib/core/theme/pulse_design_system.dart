import 'package:flutter/material.dart';

/// PulseLink Design System - Central theme management
/// 
/// Inspired by modern dating apps with a unique PulseLink aesthetic:
/// - Curved glassmorphism design elements
/// - Vibrant purple-pink gradient scheme
/// - Smooth micro-interactions and haptic feedback
/// - Performance-optimized animations
/// 
/// Design Philosophy:
/// - Central design system (DRY principle)
/// - Clean, modern, and reusable components
/// - Consistent spacing and typography
/// - Accessible color contrasts

/// Core PulseLink color palette
class PulseColors {
  // Primary brand colors
  static const Color primary = Color(0xFF6E3BFF);
  static const Color primaryLight = Color(0xFF8B5FFF); 
  static const Color primaryDark = Color(0xFF4C1FFF);
  
  // Accent colors
  static const Color accent = Color(0xFF00C2FF);
  static const Color accentLight = Color(0xFF4DD5FF);
  static const Color accentDark = Color(0xFF0099CC);
  
  // Success/like colors
  static const Color success = Color(0xFF00D4AA);
  static const Color successLight = Color(0xFF4DDFBF);
  static const Color successDark = Color(0xFF00A885);
  
  // Gradient colors
  static const Color gradientStart = Color(0xFF6E3BFF);
  static const Color gradientMiddle = Color(0xFF9C27B0);
  static const Color gradientEnd = Color(0xFFE91E63);
  
  // Action colors
  static const Color reject = Color(0xFFFF4458);
  static const Color rejectLight = Color(0xFFFF6B7A);
  static const Color rejectDark = Color(0xFFCC2233);
  
  static const Color superLike = Color(0xFF4FC3F7);
  static const Color superLikeLight = Color(0xFF7DD3FF);
  static const Color superLikeDark = Color(0xFF29B6F6);
  
  static const Color rewind = Color(0xFFFFB74D);
  static const Color rewindLight = Color(0xFFFFCC71);
  static const Color rewindDark = Color(0xFFFF9800);
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF1A1A1A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2A2A2A);
}

/// Typography system
class PulseTypography {
  static const String fontFamily = 'Inter';
  static const String headingFontFamily = 'SpaceGrotesk';
  
  // Text styles
  static const TextStyle h1 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static const TextStyle h2 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
  
  static const TextStyle h3 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  
  static const TextStyle h4 = TextStyle(
    fontFamily: headingFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}

/// Spacing system
class PulseSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

/// Border radius system
class PulseBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double full = 999.0;
}

/// Shadow system
class PulseShadows {
  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.15),
    offset: Offset(0, 8),
    blurRadius: 24,
    spreadRadius: 0,
  );
  
  static const BoxShadow cardShadowSecondary = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  );
  
  static const List<BoxShadow> card = [cardShadow, cardShadowSecondary];
  
  static const BoxShadow buttonShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: 0,
  );
  
  static const List<BoxShadow> button = [buttonShadow];
  
  static const BoxShadow glassmorphismShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    offset: Offset(0, 4),
    blurRadius: 16,
    spreadRadius: 0,
  );
  
  static const List<BoxShadow> glassmorphism = [glassmorphismShadow];
}

/// Gradient system
class PulseGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      PulseColors.gradientStart,
      PulseColors.gradientMiddle,
      PulseColors.gradientEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  static const LinearGradient primarySubtle = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      PulseColors.primaryLight,
      PulseColors.primary,
    ],
  );
  
  static const LinearGradient accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      PulseColors.accent,
      PulseColors.accentDark,
    ],
  );
  
  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      PulseColors.successLight,
      PulseColors.success,
    ],
  );
  
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      PulseColors.backgroundLight,
      Color(0xFFE9ECEF),
    ],
  );
  
  static const LinearGradient cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.transparent,
      Color.fromRGBO(0, 0, 0, 0.7),
    ],
    stops: [0.0, 0.5, 1.0],
  );
  
  // Glassmorphism effect
  static const LinearGradient glassmorphism = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromRGBO(255, 255, 255, 0.25),
      Color.fromRGBO(255, 255, 255, 0.1),
    ],
  );
}

/// Animation durations and curves
class PulseAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
  
  // Card-specific durations
  static const Duration cardSwipe = Duration(milliseconds: 300);
  static const Duration cardEntry = Duration(milliseconds: 400);
  static const Duration cardScale = Duration(milliseconds: 200);
  static const Duration cardRotation = Duration(milliseconds: 250);
  
  // Button animations
  static const Duration buttonPress = Duration(milliseconds: 100);
  static const Duration buttonScale = Duration(milliseconds: 150);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInCubic;
}

/// Custom widget decorations
class PulseDecorations {
  // Glassmorphism container
  static BoxDecoration glassmorphism({
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: color != null 
          ? LinearGradient(
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.1),
              ],
            )
          : PulseGradients.glassmorphism,
      borderRadius: borderRadius ?? BorderRadius.circular(PulseBorderRadius.lg),
      boxShadow: boxShadow ?? PulseShadows.glassmorphism,
      border: Border.all(
        color: PulseColors.white.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }
  
  // Action button decoration
  static BoxDecoration actionButton({
    required Color color,
    double? size,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: PulseColors.white,
      shape: BoxShape.circle,
      boxShadow: boxShadow ?? PulseShadows.button,
      border: Border.all(
        color: color.withValues(alpha: 0.1),
        width: 2,
      ),
    );
  }
  
  // Swipe card decoration
  static BoxDecoration swipeCard({
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: PulseColors.white,
      borderRadius: borderRadius ?? BorderRadius.circular(PulseBorderRadius.xl),
      boxShadow: boxShadow ?? PulseShadows.card,
    );
  }
  
  // Header bar decoration
  static BoxDecoration headerBar({
    Color? backgroundColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: backgroundColor != null 
          ? null 
          : PulseGradients.glassmorphism,
      color: backgroundColor,
      boxShadow: boxShadow ?? [
        BoxShadow(
          color: PulseColors.black.withValues(alpha: 0.05),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ],
    );
  }
}

/// Icon system
class PulseIcons {
  // Action icons
  static const IconData like = Icons.favorite;
  static const IconData pass = Icons.close;
  static const IconData superLike = Icons.star;
  static const IconData rewind = Icons.undo;
  static const IconData boost = Icons.flash_on;
  
  // Navigation icons
  static const IconData explore = Icons.explore;
  static const IconData sparks = Icons.local_fire_department;
  static const IconData events = Icons.event;
  static const IconData messages = Icons.message;
  static const IconData profile = Icons.person;
  
  // Settings icons
  static const IconData settings = Icons.settings;
  static const IconData filters = Icons.tune;
  static const IconData notifications = Icons.notifications;
  static const IconData ai = Icons.smart_toy;
}

/// Action button configuration
class ActionButtonConfig {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final String label;
  final VoidCallback? onTap;
  
  const ActionButtonConfig({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.size,
    required this.label,
    this.onTap,
  });
  
  // Pre-defined action buttons
  static const ActionButtonConfig pass = ActionButtonConfig(
    icon: PulseIcons.pass,
    color: PulseColors.reject,
    backgroundColor: PulseColors.white,
    size: 60,
    label: 'Pass',
  );
  
  static const ActionButtonConfig like = ActionButtonConfig(
    icon: PulseIcons.like,
    color: PulseColors.success,
    backgroundColor: PulseColors.white,
    size: 60,
    label: 'Like',
  );
  
  static const ActionButtonConfig superLike = ActionButtonConfig(
    icon: PulseIcons.superLike,
    color: PulseColors.superLike,
    backgroundColor: PulseColors.white,
    size: 50,
    label: 'Super Like',
  );
  
  static const ActionButtonConfig rewind = ActionButtonConfig(
    icon: PulseIcons.rewind,
    color: PulseColors.rewind,
    backgroundColor: PulseColors.white,
    size: 45,
    label: 'Rewind',
  );
  
  static const ActionButtonConfig boost = ActionButtonConfig(
    icon: PulseIcons.boost,
    color: PulseColors.accent,
    backgroundColor: PulseColors.white,
    size: 45,
    label: 'Boost',
  );
}

/// Theme data factory
class PulseTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PulseColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: PulseTypography.fontFamily,
      textTheme: const TextTheme(
        headlineLarge: PulseTypography.h1,
        headlineMedium: PulseTypography.h2,
        headlineSmall: PulseTypography.h3,
        titleLarge: PulseTypography.h4,
        bodyLarge: PulseTypography.bodyLarge,
        bodyMedium: PulseTypography.bodyMedium,
        bodySmall: PulseTypography.bodySmall,
        labelLarge: PulseTypography.labelLarge,
        labelMedium: PulseTypography.labelMedium,
        labelSmall: PulseTypography.labelSmall,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PulseColors.primary,
          foregroundColor: PulseColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PulseBorderRadius.lg),
          ),
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: PulseSpacing.lg,
            vertical: PulseSpacing.md,
          ),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: PulseColors.primary,
        brightness: Brightness.dark,
      ),
      fontFamily: PulseTypography.fontFamily,
      textTheme: const TextTheme(
        headlineLarge: PulseTypography.h1,
        headlineMedium: PulseTypography.h2,
        headlineSmall: PulseTypography.h3,
        titleLarge: PulseTypography.h4,
        bodyLarge: PulseTypography.bodyLarge,
        bodyMedium: PulseTypography.bodyMedium,
        bodySmall: PulseTypography.bodySmall,
        labelLarge: PulseTypography.labelLarge,
        labelMedium: PulseTypography.labelMedium,
        labelSmall: PulseTypography.labelSmall,
      ),
    );
  }
}