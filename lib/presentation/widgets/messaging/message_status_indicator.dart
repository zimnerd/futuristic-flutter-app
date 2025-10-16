import 'package:flutter/material.dart';

import '../../../data/models/chat_model.dart';

/// Visual indicator showing the message send status
///
/// Displays different icons for different message states:
/// - **Sending**: Clock icon (grey) - message queued for send
/// - **Sent**: Single check mark (grey) - server received
/// - **Delivered**: Double check mark (grey) - delivered to recipient(s)
/// - **Read**: Double check mark (blue) - read by recipient
/// - **Failed**: Error icon (red) with retry button - send failed
///
/// Usage:
/// ```dart
/// MessageStatusIndicator(
///   status: message.status,
///   onRetry: () => _retryFailedMessage(message),
///   size: 16.0,
/// )
/// ```
class MessageStatusIndicator extends StatelessWidget {
  const MessageStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
    this.size = 16.0,
    this.color,
    this.readColor,
    this.errorColor,
  });

  /// The current message status
  final MessageStatus status;

  /// Callback when retry button is tapped (for failed messages)
  final VoidCallback? onRetry;

  /// Icon size (default: 16.0)
  final double size;

  /// Default color for sent/delivered/sending states (defaults to grey)
  final Color? color;

  /// Color for read state (defaults to blue)
  final Color? readColor;

  /// Color for error state (defaults to red)
  final Color? errorColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = color ?? Colors.grey.shade600;
    final defaultReadColor = readColor ?? theme.primaryColor;
    final defaultErrorColor = errorColor ?? Colors.red;

    return switch (status) {
      MessageStatus.sending => _buildSendingIndicator(defaultColor),
      MessageStatus.sent => _buildSentIndicator(defaultColor),
      MessageStatus.delivered => _buildDeliveredIndicator(defaultColor),
      MessageStatus.read => _buildReadIndicator(defaultReadColor),
      MessageStatus.failed => _buildFailedIndicator(defaultErrorColor),
    };
  }

  /// Sending state: clock icon (message queued/sending)
  Widget _buildSendingIndicator(Color color) {
    return Icon(
      Icons.schedule,
      size: size,
      color: color,
    );
  }

  /// Sent state: single check mark (server received)
  Widget _buildSentIndicator(Color color) {
    return Icon(
      Icons.check,
      size: size,
      color: color,
    );
  }

  /// Delivered state: double check mark grey (delivered to recipient device)
  Widget _buildDeliveredIndicator(Color color) {
    return Icon(
      Icons.done_all,
      size: size,
      color: color,
    );
  }

  /// Read state: double check mark blue (read by recipient)
  Widget _buildReadIndicator(Color color) {
    return Icon(
      Icons.done_all,
      size: size,
      color: color,
    );
  }

  /// Failed state: error icon with retry button
  Widget _buildFailedIndicator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: size,
          color: color,
        ),
        if (onRetry != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.refresh,
                size: size,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Extension to get human-readable status text
extension MessageStatusExtension on MessageStatus {
  String get displayText {
    return switch (this) {
      MessageStatus.sending => 'Sending...',
      MessageStatus.sent => 'Sent',
      MessageStatus.delivered => 'Delivered',
      MessageStatus.read => 'Read',
      MessageStatus.failed => 'Failed to send',
    };
  }

  /// Whether this status indicates a problem
  bool get isError => this == MessageStatus.failed;

  /// Whether this status indicates in-progress
  bool get isPending => this == MessageStatus.sending;

  /// Whether this status indicates successful delivery
  bool get isDelivered =>
      this == MessageStatus.delivered ||
      this == MessageStatus.read ||
      this == MessageStatus.sent;
}
