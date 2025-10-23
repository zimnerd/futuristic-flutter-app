import 'package:flutter/material.dart';
import 'package:pulse_dating_app/core/utils/phone_utils.dart';
import 'package:pulse_dating_app/presentation/widgets/common/pulse_toast.dart';

/// Error handling widgets for displaying various types of errors
/// Mobile equivalent of web's error handling system (toast, modal, notification)

/// Utility class for showing different types of error notifications
class ErrorNotification {
  /// Show a toast error (using PulseToast system)
  static void showSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    // Migrated to PulseToast.error() for consistency
    PulseToast.error(context, message: message);
  }

  /// Show an error dialog (equivalent to web's error modal)
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? technicalDetails,
    String buttonText = 'OK',
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ErrorDialog(
          title: title,
          message: message,
          technicalDetails: technicalDetails,
          buttonText: buttonText,
        );
      },
    );
  }

  /// Show an in-page error banner (equivalent to web's in-page notification)
  static Widget buildErrorBanner(
    String message, {
    VoidCallback? onDismiss,
    String? technicalDetails,
  }) {
    return ErrorBanner(
      message: message,
      onDismiss: onDismiss,
      technicalDetails: technicalDetails,
    );
  }
}

/// Error dialog widget
class ErrorDialog extends StatelessWidget {
  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.technicalDetails,
    this.buttonText = 'OK',
  });

  final String title;
  final String message;
  final String? technicalDetails;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (technicalDetails != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Technical Details'),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    technicalDetails!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    );
  }
}

/// Error banner widget for in-page display
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.technicalDetails,
  });

  final String message;
  final VoidCallback? onDismiss;
  final String? technicalDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                ),
            ],
          ),
          if (technicalDetails != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: Text(
                'Technical Details',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    technicalDetails!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Form validation helpers
class ValidationHelpers {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate password strength (matching backend requirements)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }

    // Backend regex: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*?&#]/
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSpecialChar = RegExp(r'[@$!%*?&#]').hasMatch(value);

    if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!hasDigit) {
      return 'Password must contain at least one number';
    }
    if (!hasSpecialChar) {
      return 'Password must contain at least one special character (@\$!%*?&#)';
    }

    return null;
  }

  /// Validate username (matching backend requirements)
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }

    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (value.length > 30) {
      return 'Username must be less than 30 characters';
    }

    // Backend regex: /^[a-zA-Z0-9_]+$/
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    return null;
  }

  /// Validate phone number using PhoneUtils
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Use PhoneUtils for validation
    if (!PhoneUtils.isValidPhoneNumber(value)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  /// Validate optional name fields
  static String? validateOptionalName(String? value, String fieldName) {
    if (value != null && value.isNotEmpty && value.length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    return null;
  }

  /// Validate optional location field
  static String? validateOptionalLocation(String? value) {
    if (value != null && value.isNotEmpty && value.length > 200) {
      return 'Location must be less than 200 characters';
    }
    return null;
  }

  /// Validate gender selection
  static String? validateOptionalGender(String? value) {
    if (value != null && value.isNotEmpty) {
      const validGenders = [
        'male',
        'female',
        'non-binary',
        'prefer-not-to-say',
      ];
      if (!validGenders.contains(value.toLowerCase())) {
        return 'Please select a valid gender option';
      }
    }
    return null;
  }
}
