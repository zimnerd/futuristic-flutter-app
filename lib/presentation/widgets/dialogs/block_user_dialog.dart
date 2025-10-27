import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/pulse_colors.dart' hide PulseTextStyles;
import '../../theme/pulse_theme.dart';
import '../../blocs/block_report/block_report_bloc.dart';
import '../common/pulse_button.dart';

/// Dialog for blocking a user
class BlockUserDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const BlockUserDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<BlockUserDialog> createState() => _BlockUserDialogState();
}

class _BlockUserDialogState extends State<BlockUserDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isBlocking = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleBlock() async {
    setState(() {
      _isBlocking = true;
    });

    context.read<BlockReportBloc>().add(
      BlockUser(
        blockedUserId: widget.userId,
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      ),
    );

    // Close dialog after a short delay to show loading state
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.block, color: PulseColors.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'Block User',
            style: PulseTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to block ${widget.userName}?',
            style: PulseTextStyles.bodyMedium.copyWith(
              color: PulseColors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: PulseColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: PulseColors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'They won\'t be able to see your profile or contact you',
                    style: PulseTextStyles.bodySmall.copyWith(
                      color: PulseColors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Reason (optional):',
            style: PulseTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            maxLength: 200,
            enabled: !_isBlocking,
            decoration: InputDecoration(
              hintText: 'Why are you blocking this user?',
              hintStyle: TextStyle(
                color: PulseColors.onSurface.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: PulseColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
      actions: [
        PulseButton(
          text: 'Cancel',
          onPressed: _isBlocking
              ? null
              : () => Navigator.of(context).pop(false),
          variant: PulseButtonVariant.tertiary,
          size: PulseButtonSize.medium,
          isDisabled: _isBlocking,
        ),
        PulseButton(
          text: 'Block',
          onPressed: _isBlocking ? null : _handleBlock,
          variant: PulseButtonVariant.danger,
          size: PulseButtonSize.medium,
          isDisabled: _isBlocking,
          isLoading: _isBlocking,
        ),
      ],
    );
  }
}
