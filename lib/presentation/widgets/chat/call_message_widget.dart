import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/chat_model.dart';
import '../../theme/pulse_colors.dart';

/// WhatsApp-style call message widget for chat bubbles
/// Displays call history with type, status, duration, and action buttons
class CallMessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback? onCallBack;
  final VoidCallback? onViewDetails;

  const CallMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onCallBack,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final callMetadata = message.metadata ?? {};
    final callType = callMetadata['callType'] as String? ?? 'audio';
    final isIncoming = callMetadata['isIncoming'] as bool? ?? false;
    final isMissed = callMetadata['isMissed'] as bool? ?? false;
    final duration = callMetadata['duration'] as int? ?? 0;

    final isVideo = callType.toLowerCase() == 'video';
    final callStatus = _getCallStatus(isIncoming, isMissed, duration);
    final statusColor = _getStatusColor(callStatus);
    final iconData = _getCallIcon(isVideo, callStatus);

    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 60 : 12,
        right: isMe ? 12 : 60,
        top: 4,
        bottom: 4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? PulseColors.primary.withValues(alpha: 0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Call type and status row
          Row(
            children: [
              // Call icon with status color
              Icon(
                iconData,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),

              // Call type and status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCallTypeText(isVideo),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(callStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Duration if call was connected
              if (duration > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Timestamp
          const SizedBox(height: 8),
          Text(
            _formatTimestamp(message.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),

          // Action buttons
          if (onCallBack != null || onViewDetails != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              children: [
                // Call back button
                if (onCallBack != null)
                  Expanded(
                    child: _ActionButton(
                      icon: isVideo ? Icons.videocam : Icons.phone,
                      label: 'Call Back',
                      color: PulseColors.primary,
                      onTap: onCallBack!,
                    ),
                  ),

                // Spacer between buttons
                if (onCallBack != null && onViewDetails != null)
                  const SizedBox(width: 8),

                // View details button
                if (onViewDetails != null)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.info_outline,
                      label: 'Details',
                      color: Colors.grey[700]!,
                      onTap: onViewDetails!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods

  CallStatus _getCallStatus(bool isIncoming, bool isMissed, int duration) {
    if (isMissed) {
      return isIncoming ? CallStatus.missedIncoming : CallStatus.missedOutgoing;
    } else if (duration > 0) {
      return isIncoming ? CallStatus.completedIncoming : CallStatus.completedOutgoing;
    } else {
      return CallStatus.failed;
    }
  }

  Color _getStatusColor(CallStatus status) {
    switch (status) {
      case CallStatus.missedIncoming:
        return Colors.red[700]!;
      case CallStatus.missedOutgoing:
        return Colors.orange[700]!;
      case CallStatus.completedIncoming:
      case CallStatus.completedOutgoing:
        return Colors.green[700]!;
      case CallStatus.failed:
        return Colors.grey[700]!;
    }
  }

  IconData _getCallIcon(bool isVideo, CallStatus status) {
    if (isVideo) {
      return Icons.videocam;
    }

    switch (status) {
      case CallStatus.missedIncoming:
        return Icons.call_missed;
      case CallStatus.missedOutgoing:
        return Icons.phone_missed;
      case CallStatus.completedIncoming:
        return Icons.call_received;
      case CallStatus.completedOutgoing:
        return Icons.call_made;
      case CallStatus.failed:
        return Icons.phone_disabled;
    }
  }

  String _getCallTypeText(bool isVideo) {
    return isVideo ? 'Video Call' : 'Audio Call';
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.missedIncoming:
        return 'Missed call';
      case CallStatus.missedOutgoing:
        return 'Call not answered';
      case CallStatus.completedIncoming:
        return 'Incoming call';
      case CallStatus.completedOutgoing:
        return 'Outgoing call';
      case CallStatus.failed:
        return 'Call failed';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes < 60) {
      return remainingSeconds > 0
          ? '$minutes:${remainingSeconds.toString().padLeft(2, '0')}'
          : '${minutes}m';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return 'Today at ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday at ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays < 7) {
      // This week - show day name
      return '${DateFormat('EEEE').format(timestamp)} at ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      // Older - show full date
      return DateFormat('MMM d, yyyy • HH:mm').format(timestamp);
    }
  }
}

/// Action button widget for call back and details
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Call status enum for internal use
enum CallStatus {
  missedIncoming,
  missedOutgoing,
  completedIncoming,
  completedOutgoing,
  failed,
}
