import 'package:flutter/material.dart';

/// App color constants following the PulseLink brand palette
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6E3BFF); // Purple gradient brand color
  static const Color primaryDark = Color(0xFF5A2FD9);
  static const Color primaryLight = Color(0xFF8B5CFF);
  
  static const Color accent = Color(0xFF00C2FF); // Cyan highlights
  static const Color accentDark = Color(0xFF00A8E6);
  static const Color accentLight = Color(0xFF33CCFF);
  
  static const Color success = Color(0xFF00D4AA); // Green confirmations
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF4757);
  static const Color info = Color(0xFF00A8FF);
  
  // Background Colors
  static const Color background = Color(0xFF0A0A0A); // Dark background
  static const Color surface = Color(0xFF1A1A1A); // Card surfaces
  static const Color surfaceVariant = Color(0xFF2A2A2A);
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary = Color(0xFFB0B0B0); // Gray text
  static const Color textTertiary = Color(0xFF666666); // Darker gray
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFFFFFFFF);
  
  // Border Colors
  static const Color border = Color(0xFF333333);
  static const Color borderLight = Color(0xFF444444);
  static const Color cardBorder = Color(0xFF2A2A2A);
  
  // Glass morphism effects
  static const Color glassSurface = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  
  // Gradients
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
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  
  // Status Colors
  static const Color online = Color(0xFF00D4AA);
  static const Color offline = Color(0xFF666666);
  static const Color away = Color(0xFFFFB800);
  static const Color busy = Color(0xFFFF4757);
  
  // Chat Colors
  static const Color messageBubbleOwn = primary;
  static const Color messageBubbleOther = surface;
  static const Color messageText = textPrimary;
  static const Color messageTime = textSecondary;
  
  // Premium Colors
  static const Color premium = Color(0xFFFFD700); // Gold
  static const Color premiumDark = Color(0xFFE6C200);
  static const Color premiumLight = Color(0xFFFFE033);
  
  // Disabled Colors
  static const Color disabled = Color(0xFF444444);
  static const Color disabledText = Color(0xFF666666);
  
  // Transparent
  static const Color transparent = Colors.transparent;
}
