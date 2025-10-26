import 'package:flutter/material.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/user_model.dart';
import '../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            isVideo ? Icons.videocam : Icons.phone,
            color: PulseColors.primary,
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Call Back?')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you want to call $userName?',
            style: TextStyle(
              fontSize: 15,
              color: context.onSurfaceVariantColor,
            ),
          ),

          if (isMissed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.errorColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: context.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This was a missed call',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.errorColor,
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
                color: context.onSurfaceVariantColor,
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
            style: TextStyle(color: context.onSurfaceVariantColor),
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
            icon: Icon(Icons.phone, size: 18),
            label: Text('Audio'),
            style: TextButton.styleFrom(
              foregroundColor: context.successColor,
            ),
          ),

          // Video call option
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm(true);
            },
            icon: Icon(Icons.videocam, size: 18),
            label: Text('Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: context.theme.colorScheme.onPrimary,
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
            icon: Icon(Icons.phone, size: 18),
            label: Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.successColor,
              foregroundColor: context.theme.colorScheme.onTertiary,
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
