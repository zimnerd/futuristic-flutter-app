import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/pulse_colors.dart' hide PulseTextStyles;
import '../../theme/pulse_theme.dart';
import '../../blocs/block_report/block_report_bloc.dart';
import '../common/pulse_toast.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';

/// Dialog for reporting a user
class ReportUserDialog extends StatefulWidget {
  final String userId;
  final String userName;

  const ReportUserDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedReason;
  bool _isReporting = false;

  final List<String> _reportReasons = [
    'Harassment or bullying',
    'Inappropriate content',
    'Fake profile',
    'Spam or scam',
    'Underage user',
    'Hate speech',
    'Violence or threats',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleReport() async {
    if (_selectedReason == null) {
      PulseToast.error(
        context,
        message: 'Please select a reason for reporting',
      );
      return;
    }

    setState(() {
      _isReporting = true;
    });

    context.read<BlockReportBloc>().add(
      ReportUser(
        reportedUserId: widget.userId,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      ),
    );

    // Close dialog after a short delay
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
          Icon(Icons.flag, color: PulseColors.error, size: 28),
          const SizedBox(width: 12),
          Text(
            'Report User',
            style: PulseTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help us understand what\'s wrong with ${widget.userName}\'s profile',
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
                    Icons.privacy_tip_outlined,
                    size: 20,
                    color: PulseColors.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your report is anonymous and will be reviewed by our team',
                      style: PulseTextStyles.bodySmall.copyWith(
                        color: PulseColors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Reason for reporting:',
              style: PulseTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: PulseColors.onSurface.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  hint: Text(
                    'Select a reason',
                    style: TextStyle(
                      color: PulseColors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  items: _reportReasons.map((reason) {
                    return DropdownMenuItem(value: reason, child: Text(reason));
                  }).toList(),
                  onChanged: _isReporting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Additional details (optional):',
              style: PulseTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              enabled: !_isReporting,
              decoration: InputDecoration(
                hintText: 'Provide more context about why you\'re reporting...',
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
      ),
      actions: [
        TextButton(
          onPressed: _isReporting
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: PulseTextStyles.labelLarge.copyWith(
              color: _isReporting
                  ? PulseColors.onSurface.withValues(alpha: 0.3)
                  : PulseColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isReporting ? null : _handleReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: PulseColors.error,
            foregroundColor: context.onSurfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isReporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Submit Report',
                  style: PulseTextStyles.labelLarge.copyWith(
                    color: context.onSurfaceColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}
