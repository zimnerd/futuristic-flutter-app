import 'package:flutter/material.dart';

/// App color constants following the PulseLink brand palette
/// Exactly matching web brand colors (#6E3BFF, #00C2FF, #00D95F)
class AppColors {
  // Brand Colors - Exact match with web
  static const Color primary = Color(0xFF6E3BFF); // Purple gradient brand color
  static const Color primaryDark = Color(0xFF4A26B0); // From web primary-700
  static const Color primaryLight = Color(0xFFA777FF); // From web primary-400

  static const Color accent = Color(0xFF00C2FF); // Cyan highlights
  static const Color accentDark = Color(0xFF0074A9); // From web accent-700
  static const Color accentLight = Color(0xFF33CAFF); // From web accent-400

  static const Color success = Color(
    0xFF00D95F,
  ); // Green confirmations - updated
  static const Color warning = Color(0xFFFF9900); // From web warning
  static const Color error = Color(0xFFFF3B5C); // From web destructive
  static const Color info = Color(0xFF00C2FF); // Use accent for info

  // Background Colors - Enhanced for modern dark mode
  static const Color background = Color(0xFF0A0F2D); // From web neutral-900
  static const Color surface = Color(0xFF202124); // From web neutral-800
  static const Color surfaceVariant = Color(0xFF3C4043); // From web neutral-700

  // Text Colors - Improved contrast and hierarchy
  static const Color textPrimary = Color(0xFFF1F3F4); // From web neutral-100
  static const Color textSecondary = Color(0xFFBDC1C6); // From web neutral-400
  static const Color textTertiary = Color(0xFF8C8CA1); // From web neutral-500
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFFF1F3F4);

  // Border Colors - Subtle and refined
  static const Color border = Color(0xFF5F6368); // From web neutral-600
  static const Color borderLight = Color(0xFFBDC1C6); // From web neutral-400
  static const Color cardBorder = Color(0xFF3C4043); // From web neutral-700

  // Glass morphism effects - Enhanced transparency
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Gradients - Matching web brand gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Brand gradient matching web's gradient-primary
  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF6E3BFF), Color(0xFF00C2FF)], // Exact web gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Success gradient matching web
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00D95F), Color(0xFF00C2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF202124)], // Updated to use web neutral
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadow Colors - Enhanced for depth
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Status Colors - Updated to match new palette
  static const Color online = Color(0xFF00D95F); // Updated success color
  static const Color offline = Color(0xFF8C8CA1); // From web neutral-500
  static const Color away = Color(0xFFFF9900); // Updated warning color
  static const Color busy = Color(0xFFFF3B5C); // Updated error color

  // Chat Colors - Enhanced for better UX
  static const Color messageBubbleOwn = primary;
  static const Color messageBubbleOther = surfaceVariant;
  static const Color messageText = textPrimary;
  static const Color messageTime = textSecondary;

  // Premium Colors - Refined gold system
  static const Color premium = Color(0xFFFFD700); // Gold
  static const Color premiumDark = Color(0xFFCC9200); // From web warning-800
  static const Color premiumLight = Color(0xFFFFE033);

  // Disabled Colors - Better accessibility
  static const Color disabled = Color(0xFF5F6368); // From web neutral-600
  static const Color disabledText = Color(0xFF8C8CA1); // From web neutral-500

  // Transparent
  static const Color transparent = Colors.transparent;
}
