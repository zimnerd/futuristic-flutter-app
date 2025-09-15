import 'package:flutter/material.dart';

/// Pulse Dating App Color Palette
/// Exactly matching the web brand colors (#6E3BFF, #00C2FF, #00D4AA)
class PulseColors {
  PulseColors._();

  // Primary Brand Colors - Exact match with web (#6E3BFF)
  static const Color primary = Color(0xFF6E3BFF); // Pulse purple
  static const Color primaryLight = Color(0xFFA777FF); // From web primary-400
  static const Color primaryDark = Color(0xFF4A26B0); // From web primary-700
  static const Color primaryContainer = Color(
    0xFFE9E1FF,
  ); // From web primary-100

  // Secondary Brand Colors - Exact match with web (#00C2FF)
  static const Color secondary = Color(0xFF00C2FF); // Cyan accent
  static const Color secondaryLight = Color(0xFF33CAFF); // From web accent-400
  static const Color secondaryDark = Color(0xFF0074A9); // From web accent-700
  static const Color secondaryContainer = Color(
    0xFFCCF2FF,
  ); // From web accent-100

  // Success & Positive Actions - Exact match with web (#00D95F)
  static const Color success = Color(
    0xFF00D95F,
  ); // Green - updated to match web
  static const Color successLight = Color(0xFF33FF99); // From web success-400
  static const Color successDark = Color(0xFF008640); // From web success-700
  static const Color successContainer = Color(
    0xFFCCFFE6,
  ); // From web success-100

  // Error & Warning - Updated to match web design system
  static const Color error = Color(
    0xFFFF3B5C,
  ); // Modern red - from web destructive
  static const Color errorLight = Color(0xFFFF6684); // From web destructive-400
  static const Color errorDark = Color(0xFFA92238); // From web destructive-700
  static const Color errorContainer = Color(
    0xFFFFCCD6,
  ); // From web destructive-100

  static const Color warning = Color(
    0xFFFF9900,
  ); // Warm orange - from web warning
  static const Color warningLight = Color(0xFFFFB366); // From web warning-300
  static const Color warningDark = Color(0xFFA96600); // From web warning-700
  static const Color warningContainer = Color(
    0xFFFFE6CC,
  ); // From web warning-100

  // Neutral Colors - Updated to match web neutral system
  static const Color surface = Color(0xFFFFFFFF); // Pure white for light mode
  static const Color surfaceVariant = Color(0xFFF1F3F4); // From web neutral-100
  static const Color surfaceDim = Color(0xFFE8EAED); // From web neutral-200
  static const Color surfaceBright = Color(0xFFFFFBFF);

  static const Color onSurface = Color(0xFF202124); // From web neutral-800
  static const Color onSurfaceVariant = Color(
    0xFF5F6368,
  ); // From web neutral-600
  static const Color outline = Color(0xFFBDC1C6); // From web neutral-400
  static const Color outlineVariant = Color(0xFFDADCE0); // From web neutral-300

  // Dark Theme Colors - Enhanced dark mode system
  static const Color surfaceDark = Color(0xFF0A0F2D); // From web neutral-900
  static const Color surfaceVariantDark = Color(
    0xFF202124,
  ); // From web neutral-800
  static const Color onSurfaceDark = Color(
    0xFFF1F3F4,
  ); // Light text on dark surface
  static const Color onSurfaceVariantDark = Color(
    0xFFBDC1C6,
  ); // From web neutral-400

  // Gradient Colors for Premium Feel - Updated to match web gradients
  static const List<Color> primaryGradient = [
    Color(0xFF6E3BFF), // Primary
    Color(0xFF00C2FF), // Secondary - creates the signature brand gradient
  ];

  static const List<Color> successGradient = [
    Color(0xFF00D95F), // Success
    Color(0xFF00C2FF), // Secondary
  ];

  static const List<Color> premiumGradient = [
    Color(0xFFFFD700), // Gold - from web warning colors
    Color(0xFFFF9900), // Orange - from web warning
  ];

  // Dating App Specific Colors - Updated to use new color system
  static const Color like = success; // Green for likes (#00D95F)
  static const Color superLike = Color(0xFF00C2FF); // Blue for super likes
  static const Color nope = Color(0xFFBDC1C6); // Neutral gray for pass
  static const Color match = Color(0xFFFF3B5C); // Red/pink for matches
  static const Color online = success; // Online status
  static const Color recently = warning; // Recently active
  static const Color offline = Color(0xFF8C8CA1); // From web neutral-500

  // Chat & Message Colors - Enhanced for better UX
  static const Color sentMessage = primary; // Purple for sent messages
  static const Color receivedMessage = Color(
    0xFFF1F3F4,
  ); // Light gray for received
  static const Color unreadBadge = Color(0xFFFF3B5C); // Match color for urgency
  static const Color typing = secondary; // Cyan for typing indicator

  // Photo & Media Colors
  static const Color photoOverlay = Color(0x80000000); // Semi-transparent black
  static const Color photoPlaceholder = Color(
    0xFFE8EAED,
  ); // From web neutral-200
  static const Color videoOverlay = Color(0xBF000000); // More opaque for video
}

/// Typography scale following Material Design 3 principles
class PulseTextStyles {
  PulseTextStyles._();

  // Display styles - Large, impactful text
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline styles - Medium emphasis
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title styles - High emphasis
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body styles - Regular text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label styles - Supportive text
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Dating App Specific Styles
  static const TextStyle profileName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle profileAge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle matchPercentage = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  static const TextStyle chatMessage = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.4,
  );

  static const TextStyle timestamp = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
}

/// Spacing constants following 8pt grid system
class PulseSpacing {
  PulseSpacing._();

  // Base spacing unit (8pt grid)
  static const double xs = 4.0; // Extra small
  static const double sm = 8.0; // Small
  static const double md = 16.0; // Medium
  static const double lg = 24.0; // Large
  static const double xl = 32.0; // Extra large
  static const double xxl = 48.0; // Extra extra large

  // Component specific spacing
  static const double cardPadding = md;
  static const double screenPadding = md;
  static const double buttonPadding = md;
  static const double listItemPadding = md;
  static const double inputPadding = md;

  // Layout spacing
  static const double sectionSpacing = xl;
  static const double componentSpacing = lg;
  static const double elementSpacing = md;
  static const double tightSpacing = sm;
}

/// Border radius constants for consistent rounded corners
class PulseRadii {
  PulseRadii._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  // Component specific radii
  static const double button = md;
  static const double card = lg;
  static const double bottomSheet = xl;
  static const double dialog = lg;
  static const double input = md;
  static const double avatar = lg;
  static const circular = 999.0; // For fully circular elements
}

/// Animation duration constants for consistent motion
class PulseAnimations {
  PulseAnimations._();

  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);

  // Specific animation durations
  static const Duration buttonPress = quick;
  static const Duration cardSwipe = normal;
  static const Duration pageTransition = normal;
  static const Duration shimmer = slower;
  static const Duration heartBeat = Duration(milliseconds: 600);
  static const Duration matchCelebration = Duration(milliseconds: 1200);
}

/// Elevation levels for Material Design shadows
class PulseElevations {
  PulseElevations._();

  static const double none = 0.0;
  static const double low = 2.0;
  static const double medium = 4.0;
  static const double high = 8.0;
  static const double higher = 12.0;
  static const double highest = 16.0;

  // Component specific elevations
  static const double card = low;
  static const double button = medium;
  static const double fab = high;
  static const double modal = higher;
  static const double tooltip = highest;
}
