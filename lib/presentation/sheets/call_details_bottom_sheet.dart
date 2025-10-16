import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../theme/pulse_colors.dart';

/// Bottom sheet showing comprehensive call details
/// Includes participants, duration, time, status, and action buttons
class CallDetailsBottomSheet extends StatelessWidget {
  final MessageModel callMessage;
  final UserModel? otherUser;
  final VoidCallback? onCallBack;

  const CallDetailsBottomSheet({
    super.key,
    required this.callMessage,
    this.otherUser,
    this.onCallBack,
  });

  /// Show the call details bottom sheet
  static Future<void> show(
    BuildContext context, {
    required MessageModel callMessage,
    UserModel? otherUser,
    VoidCallback? onCallBack,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CallDetailsBottomSheet(
        callMessage: callMessage,
        otherUser: otherUser,
        onCallBack: onCallBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final callMetadata = callMessage.metadata ?? {};
    final callType = callMetadata['callType'] as String? ?? 'audio';
    final isIncoming = callMetadata['isIncoming'] as bool? ?? false;
    final isMissed = callMetadata['isMissed'] as bool? ?? false;
    final duration = callMetadata['duration'] as int? ?? 0;

    final isVideo = callType.toLowerCase() == 'video';
    final userName = otherUser?.firstName ?? 'Unknown User';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PulseColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.phone,
                      color: PulseColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Details',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _getCallStatusText(isIncoming, isMissed, duration),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getStatusColor(isIncoming, isMissed, duration),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Call information
              _buildInfoSection(
                context,
                [
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'With',
                    value: userName,
                  ),
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Duration',
                    value: _formatDuration(duration),
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat('EEEE, MMMM d, yyyy').format(callMessage.createdAt),
                  ),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Time',
                    value: DateFormat('h:mm a').format(callMessage.createdAt),
                  ),
                  _InfoRow(
                    icon: isVideo ? Icons.videocam_outlined : Icons.phone_outlined,
                    label: 'Type',
                    value: isVideo ? 'Video Call' : 'Audio Call',
                  ),
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'Direction',
                    value: isIncoming ? 'Incoming' : 'Outgoing',
                  ),
                  if (isMissed)
                    _InfoRow(
                      icon: Icons.warning_amber_outlined,
                      label: 'Status',
                      value: 'Missed',
                      valueColor: Colors.red[700],
                    ),
                ],
              ),

              // Call back button
              if (onCallBack != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCallBack!();
                    },
                    icon: Icon(isVideo ? Icons.videocam : Icons.phone),
                    label: const Text('Call Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PulseColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, List<_InfoRow> rows) {
    return Column(
      children: rows.map((row) => _buildInfoRow(context, row)).toList(),
    );
  }

  Widget _buildInfoRow(BuildContext context, _InfoRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              row.icon,
              size: 20,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              row.label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: row.valueColor ?? Colors.grey[900],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getCallStatusText(bool isIncoming, bool isMissed, int duration) {
    if (isMissed) {
      return isIncoming ? 'Missed Incoming Call' : 'Unanswered Outgoing Call';
    } else if (duration > 0) {
      return isIncoming ? 'Completed Incoming Call' : 'Completed Outgoing Call';
    } else {
      return 'Call Failed';
    }
  }

  Color _getStatusColor(bool isIncoming, bool isMissed, int duration) {
    if (isMissed) {
      return Colors.red[700]!;
    } else if (duration > 0) {
      return Colors.green[700]!;
    } else {
      return Colors.grey[700]!;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) {
      return 'Not connected';
    }

    if (seconds < 60) {
      return '$seconds seconds';
    }

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    if (minutes < 60) {
      return remainingSeconds > 0
          ? '$minutes minutes $remainingSeconds seconds'
          : '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    return remainingMinutes > 0
        ? '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'}'
        : '$hours ${hours == 1 ? 'hour' : 'hours'}';
  }
}

/// Internal class for info row data
class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}
