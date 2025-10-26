/// Profile Screen Color Palette
/// Based on PulseLink Profile Redesign Wireframe
/// Dark mode optimized, WCAG AA compliant
/// 
/// Design Source: PROFILE_REDESIGN_WIREFRAME.md

import 'package:flutter/material.dart';

class PulseProfileColors {
  // ===== BASE COLORS (Dark Mode) =====
  /// Main background - Navy black, less eye strain
  static const Color darkBackground = Color(0xFF0F1419);
  
  /// Card/Surface background - Slightly lighter for contrast
  static const Color darkSurface = Color(0xFF1A1F2E);
  
  /// Hover/Alternative surface
  static const Color darkSurfaceAlt = Color(0xFF2D3748);
  
  /// 1px borders and subtle lines
  static const Color darkBorder = Color(0xFF2D3748);
  
  /// Primary text - Near white for contrast
  static const Color darkTextPrimary = Color(0xFFF7FAFC);
  
  /// Secondary text - Muted gray
  static const Color darkTextSecondary = Color(0xFFA0AEC0);

  // ===== ACCENT COLORS (Strategic, Not Overused) =====
  /// Primary action buttons, highlights
  static const Color accentPrimary = Color(0xFF6E3BFF);
  
  /// Success/Like/Interests match
  static const Color accentSuccess = Color(0xFF00D95F);
  
  /// Verified badges, trust indicators
  static const Color accentVerified = Color(0xFF00C2FF);
  
  /// Premium badges, special features
  static const Color accentPremium = Color(0xFFFFB84D);
  
  /// Alert/Report/Block
  static const Color accentAlert = Color(0xFFFF5757);

  // ===== SECTION GRADIENTS (Subtle, Not Bright) =====
  /// About section - Neutral blue-gray
  static const List<Color> gradientAbout = [
    Color(0xFF1A1F2E),  // Start
    Color(0xFF2D3748),  // End
  ];
  
  /// Interests section - Subtle teal
  static const List<Color> gradientInterests = [
    Color(0xFF1F3A2D),  // Start (teal tint)
    Color(0xFF2D3748),  // End
  ];
  
  /// Lifestyle section - Subtle warm
  static const List<Color> gradientLifestyle = [
    Color(0xFF3A2F1A),  // Start (warm tint)
    Color(0xFF2D3748),  // End
  ];
  
  /// Goals section - Subtle purple
  static const List<Color> gradientGoals = [
    Color(0xFF2D1F3A),  // Start (purple tint)
    Color(0xFF2D3748),  // End
  ];
  
  /// Languages section - Subtle cool blue
  static const List<Color> gradientLanguages = [
    Color(0xFF1A2E3A),  // Start (cool blue tint)
    Color(0xFF2D3748),  // End
  ];
  
  /// Details section - Neutral (same as About)
  static const List<Color> gradientDetails = gradientAbout;
  
  /// Personality section - Same as Goals
  static const List<Color> gradientPersonality = gradientGoals;

  // ===== SECTION ICONS (Emoji-based) =====
  static const String iconAbout = '👤';
  static const String iconInterests = '❤️';
  static const String iconLifestyle = '🎭';
  static const String iconGoals = '🎯';
  static const String iconLanguages = '🗣️';
  static const String iconPhotos = '📸';
  static const String iconPrompts = '💬';
  static const String iconDetails = '📋';
  static const String iconPersonality = '✨';

  // ===== HELPER METHODS =====
  
  /// Get gradient for section by name
  static LinearGradient getGradient(String sectionName) {
    List<Color> colors;
    
    switch (sectionName.toLowerCase()) {
      case 'about':
        colors = gradientAbout;
        break;
      case 'interests':
        colors = gradientInterests;
        break;
      case 'lifestyle':
        colors = gradientLifestyle;
        break;
      case 'goals':
      case 'relationship goals':
        colors = gradientGoals;
        break;
      case 'languages':
        colors = gradientLanguages;
        break;
      case 'details':
        colors = gradientDetails;
        break;
      case 'personality':
      case 'personality traits':
        colors = gradientPersonality;
        break;
      default:
        colors = gradientAbout;
    }
    
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
  
  /// Get icon emoji for section
  static String getIcon(String sectionName) {
    switch (sectionName.toLowerCase()) {
      case 'about':
        return iconAbout;
      case 'interests':
        return iconInterests;
      case 'lifestyle':
        return iconLifestyle;
      case 'goals':
      case 'relationship goals':
        return iconGoals;
      case 'languages':
        return iconLanguages;
      case 'photos':
        return iconPhotos;
      case 'prompts':
        return iconPrompts;
      case 'details':
        return iconDetails;
      case 'personality':
      case 'personality traits':
        return iconPersonality;
      default:
        return '📌';
    }
  }
}
