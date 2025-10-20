import 'package:flutter/material.dart';
import '../../../core/theme/pulse_design_system.dart';
import '../../../core/utils/haptic_feedback_utils.dart';
import '../../../core/utils/logger.dart';

/// Modern Toast Notification System for PulseLink
///
/// Provides beautiful, non-intrusive toast notifications with:
/// - 4 types: Success, Error, Info, Warning
/// - Auto-dismiss with configurable duration
/// - Icon + message + optional action
/// - Smooth animations (slide up from bottom)
/// - Haptic feedback
/// - Material Design 3 styling
///
/// Usage:
/// ```dart
/// // Success toast
/// PulseToast.success(
///   context,
///   message: 'Profile saved successfully!',
/// );
///
/// // Error toast
/// PulseToast.error(
///   context,
///   message: 'Failed to send message',
///   action: ToastAction(label: 'Retry', onPressed: () => retry()),
/// );
///
/// // Info toast
/// PulseToast.info(
///   context,
///   message: 'New matches available',
/// );
///
/// // Warning toast
/// PulseToast.warning(
///   context,
///   message: 'Profile incomplete',
///   action: ToastAction(label: 'Complete', onPressed: () => goToProfile()),
/// );
/// ```
class PulseToast {
  /// Show success toast (green, checkmark icon)
  static void success(
    BuildContext context, {
    required String message,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    PulseHaptics.success();
    _showToast(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: PulseColors.success,
      action: action,
      duration: duration,
    );
  }

  /// Show error toast (red, error icon)
  static void error(
    BuildContext context, {
    required String message,
    ToastAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    PulseHaptics.error();
    _showToast(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: PulseColors.reject,
      action: action,
      duration: duration,
    );
  }

  /// Show info toast (blue, info icon)
  static void info(
    BuildContext context, {
    required String message,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    PulseHaptics.light();
    _showToast(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: PulseColors.primary,
      action: action,
      duration: duration,
    );
  }

  /// Show warning toast (orange, warning icon)
  static void warning(
    BuildContext context, {
    required String message,
    ToastAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    PulseHaptics.medium();
    _showToast(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: PulseColors.rewind,
      action: action,
      duration: duration,
    );
  }

  /// Internal method to show toast with SnackBar
  static void _showToast(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    ToastAction? action,
    required Duration duration,
  }) {
    // Safety check: Only show toast if ScaffoldMessenger is available
    // This prevents errors when toast is called before MaterialApp is built
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) {
      AppLogger.warning(
        '⚠️ Cannot show toast: ScaffoldMessenger not available yet. Message: $message',
      );
      return;
    }

    final snackBar = SnackBar(
      content: _ToastContent(message: message, icon: icon),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(PulseSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: action != null
          ? SnackBarAction(
              label: action.label,
              textColor: Colors.white,
              onPressed: action.onPressed,
            )
          : null,
      elevation: 6,
    );

    scaffoldMessenger.showSnackBar(snackBar);
  }
}

/// Toast action button
class ToastAction {
  final String label;
  final VoidCallback onPressed;

  const ToastAction({required this.label, required this.onPressed});
}

/// Internal widget for toast content
class _ToastContent extends StatelessWidget {
  final String message;
  final IconData icon;

  const _ToastContent({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(width: PulseSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
