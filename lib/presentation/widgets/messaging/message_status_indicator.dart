import 'package:flutter/material.dart';

import '../../../data/models/chat_model.dart';

/// Visual indicator showing the message send status
///
/// Displays different icons for different message states:
/// - **Sending**: Clock icon (grey) - message queued for send
/// - **Sent**: Single check mark (grey) - server received
/// - **Delivered**: Double check mark (grey) - delivered to recipient(s)
/// - **Read**: Double check mark (BLUE - prominent) - read by recipient
/// - **Failed**: Error icon (red) with retry button - send failed
///
/// QUICK WIN Feature 4: Enhanced with:
/// - More prominent blue color for read status
/// - Subtle animation when status changes
/// - Better visual progression
///
/// Usage:
/// ```dart
/// MessageStatusIndicator(
///   status: message.status,
///   onRetry: () => _retryFailedMessage(message),
///   size: 16.0,
/// )
/// ```
class MessageStatusIndicator extends StatefulWidget {
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

  /// Color for read state (defaults to prominent blue)
  final Color? readColor;

  /// Color for error state (defaults to red)
  final Color? errorColor;

  @override
  State<MessageStatusIndicator> createState() => _MessageStatusIndicatorState();
}

class _MessageStatusIndicatorState extends State<MessageStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(MessageStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate when status changes
    if (oldWidget.status != widget.status) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultColor = widget.color ?? Colors.grey.shade600;
    // More prominent blue for read status
    final defaultReadColor = widget.readColor ?? const Color(0xFF2196F3); // Material Blue
    final defaultErrorColor = widget.errorColor ?? Colors.red;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: switch (widget.status) {
        MessageStatus.sending => _buildSendingIndicator(defaultColor),
        MessageStatus.sent => _buildSentIndicator(defaultColor),
        MessageStatus.delivered => _buildDeliveredIndicator(defaultColor),
        MessageStatus.read => _buildReadIndicator(defaultReadColor),
        MessageStatus.failed => _buildFailedIndicator(defaultErrorColor),
      },
    );
  }

  /// Sending state: clock icon (message queued/sending)
  Widget _buildSendingIndicator(Color color) {
    return Icon(
      Icons.schedule,
      size: widget.size,
      color: color,
    );
  }

  /// Sent state: single check mark (server received)
  Widget _buildSentIndicator(Color color) {
    return Icon(
      Icons.check,
      size: widget.size,
      color: color,
    );
  }

  /// Delivered state: double check mark grey (delivered to recipient device)
  Widget _buildDeliveredIndicator(Color color) {
    return Icon(
      Icons.done_all,
      size: widget.size,
      color: color,
    );
  }

  /// Read state: double check mark BLUE (read by recipient) - PROMINENT
  Widget _buildReadIndicator(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: Icon(
        Icons.done_all,
        size: widget.size,
        color: color,
      ),
    );
  }

  /// Failed state: error icon with retry button
  Widget _buildFailedIndicator(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: widget.size,
          color: color,
        ),
        if (widget.onRetry != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: widget.onRetry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.refresh,
                size: widget.size,
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
