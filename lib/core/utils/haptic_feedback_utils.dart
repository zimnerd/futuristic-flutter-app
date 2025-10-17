import 'package:flutter/services.dart';

/// Haptic Feedback Utility for PulseLink
///
/// Provides consistent haptic feedback across the app for enhanced user experience.
/// Uses Flutter's HapticFeedback API to provide tactile responses to user actions.
///
/// Usage:
/// ```dart
/// // Light feedback for subtle actions
/// PulseHaptics.light();
///
/// // Medium feedback for standard actions
/// PulseHaptics.medium();
///
/// // Heavy feedback for important actions
/// PulseHaptics.heavy();
///
/// // Success feedback for positive outcomes
/// PulseHaptics.success();
///
/// // Error feedback for negative outcomes
/// PulseHaptics.error();
/// ```
class PulseHaptics {
  /// Light haptic feedback - for subtle interactions
  ///
  /// Use for:
  /// - Swipe gesture start
  /// - Scrolling through content
  /// - Tab switches
  /// - Minor UI interactions
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback - for standard interactions
  ///
  /// Use for:
  /// - Button presses
  /// - Selections in lists
  /// - Card taps
  /// - Standard actions
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback - for important interactions
  ///
  /// Use for:
  /// - Super likes
  /// - Match confirmations
  /// - Critical actions
  /// - Delete/remove actions
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Success haptic feedback - for positive outcomes
  ///
  /// Use for:
  /// - Successful matches
  /// - Message sent successfully
  /// - Profile saved
  /// - Action completed successfully
  static Future<void> success() async {
    // Double light impact for success feel
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Error haptic feedback - for negative outcomes
  ///
  /// Use for:
  /// - Failed actions
  /// - Validation errors
  /// - Network errors
  /// - Insufficient permissions
  static Future<void> error() async {
    // Heavy then light for error feel
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Selection changed haptic feedback
  ///
  /// Use for:
  /// - Picker/selector changes
  /// - Filter selections
  /// - Toggle switches
  static Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }

  /// Vibrate haptic feedback - for notifications
  ///
  /// Use for:
  /// - New message notifications
  /// - New match notifications
  /// - Important alerts
  static Future<void> vibrate() async {
    await HapticFeedback.vibrate();
  }

  /// Swipe left (nope) haptic pattern
  ///
  /// Light feedback indicating rejection action
  static Future<void> swipeLeft() async {
    await HapticFeedback.lightImpact();
  }

  /// Swipe right (like) haptic pattern
  ///
  /// Medium feedback indicating positive action
  static Future<void> swipeRight() async {
    await HapticFeedback.mediumImpact();
  }

  /// Swipe up (super like) haptic pattern
  ///
  /// Heavy feedback indicating premium action
  static Future<void> swipeUp() async {
    await HapticFeedback.heavyImpact();
  }

  /// Match created haptic pattern
  ///
  /// Special pattern for match celebrations
  static Future<void> match() async {
    // Triple medium impact for celebration
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Message sent haptic pattern
  static Future<void> messageSent() async {
    await HapticFeedback.lightImpact();
  }

  /// Message received haptic pattern
  static Future<void> messageReceived() async {
    await HapticFeedback.mediumImpact();
  }
}
