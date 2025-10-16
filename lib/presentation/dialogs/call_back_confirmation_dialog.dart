import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../theme/pulse_colors.dart';

/// Confirmation dialog shown before calling back from a call message
/// Prevents accidental calls and allows user to choose audio vs video
class CallBackConfirmationDialog extends StatelessWidget {
  final MessageModel callMessage;
  final UserModel? otherUser;
  final Function(bool isVideo) onConfirm;

  const CallBackConfirmationDialog({
    super.key,
    required this.callMessage,
    this.otherUser,
    required this.onConfirm,
  });

  /// Show the call back confirmation dialog
  static Future<void> show(
    BuildContext context, {
    required MessageModel callMessage,
    UserModel? otherUser,
    required Function(bool isVideo) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => CallBackConfirmationDialog(
        callMessage: callMessage,
        otherUser: otherUser,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final callMetadata = callMessage.metadata ?? {};
    final callType = callMetadata['callType'] as String? ?? 'audio';
    final isMissed = callMetadata['isMissed'] as bool? ?? false;
    final isVideo = callType.toLowerCase() == 'video';

    final userName = otherUser?.firstName ?? 'this person';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            isVideo ? Icons.videocam : Icons.phone,
            color: PulseColors.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Call Back?'),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you want to call $userName?',
            style: const TextStyle(fontSize: 15),
          ),
          
          if (isMissed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This was a missed call',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isVideo) ...[
            const SizedBox(height: 16),
            Text(
              'Choose call type:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),

        // Call buttons
        if (isVideo) ...[
          // Audio call option for video calls
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm(false);
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Audio'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green[700],
            ),
          ),
          
          // Video call option
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm(true);
            },
            icon: const Icon(Icons.videocam, size: 18),
            label: const Text('Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ] else
          // Single audio call button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm(false);
            },
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}
