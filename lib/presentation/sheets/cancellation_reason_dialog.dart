import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../theme/theme_extensions.dart';

/// Dialog for collecting cancellation reasons and offering retention
class CancellationReasonDialog extends StatefulWidget {
  const CancellationReasonDialog({super.key});

  @override
  State<CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<CancellationReasonDialog> {
  String? _selectedReason;
  final TextEditingController _feedbackController = TextEditingController();
  bool _showRetentionOffer = false;
  bool _offerAccepted = false;

  final List<CancellationReason> _reasons = [
    CancellationReason(
      id: 'too_expensive',
      label: 'Too expensive',
      icon: Icons.attach_money,
      showOffer: true,
    ),
    CancellationReason(
      id: 'not_using',
      label: 'Not using the features',
      icon: Icons.block,
      showOffer: false,
    ),
    CancellationReason(
      id: 'found_someone',
      label: 'Found someone special',
      icon: Icons.favorite,
      showOffer: false,
    ),
    CancellationReason(
      id: 'technical_issues',
      label: 'Technical issues',
      icon: Icons.bug_report,
      showOffer: false,
    ),
    CancellationReason(
      id: 'other',
      label: 'Other',
      icon: Icons.more_horiz,
      showOffer: false,
    ),
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showRetentionOffer) {
      return _buildRetentionOfferDialog();
    }

    return AlertDialog(
      title: Column(
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          const Text(
            'We\'re sorry to see you go',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before you cancel, could you tell us why?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Cancellation reasons
            ..._reasons.map((reason) => _buildReasonOption(reason)),

            const SizedBox(height: 20),

            // Feedback text field
            const Text(
              'Additional feedback (optional):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Tell us more...',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.all(12),
                hintStyle: TextStyle(color: context.onSurfaceVariantColor),
              ),
              maxLines: 3,
              maxLength: 500,
            ),

            const SizedBox(height: 12),

            // Important notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your premium features will remain active until the end of your current billing period.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Subscription'),
        ),
        TextButton(
          onPressed: _handleContinueCancellation,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Continue to Cancel'),
        ),
      ],
    );
  }

  Widget _buildReasonOption(CancellationReason reason) {
    final isSelected = _selectedReason == reason.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedReason = reason.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : context.surfaceVariantColor,
            border: Border.all(
              color: isSelected ? AppColors.primary : context.outlineColor,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                reason.icon,
                color: isSelected ? AppColors.primary : context.onSurfaceVariantColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  reason.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected ? AppColors.primary : context.onSurfaceColor,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetentionOfferDialog() {
    if (_offerAccepted) {
      return AlertDialog(
        title: Column(
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: context.successColor,
            ),
            const SizedBox(height: 12),
            const Text(
              'Offer Applied!',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Great! We\'ve applied 50% off your next month.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your subscription will continue at the discounted rate.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.onSurfaceVariantColor,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, {
                'confirmed': false,
                'offerAccepted': true,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.theme.colorScheme.onPrimary,
            ),
            child: const Text('Awesome!'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Column(
        children: [
          Icon(Icons.card_giftcard, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Wait! Special Offer',
            style: TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF9D4EDD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '50% OFF',
                  style: TextStyle(
                    color: context.theme.colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Next Month',
                  style: TextStyle(
                    color: context.theme.colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'We understand that price matters. Stay with us and enjoy 50% off your next billing cycle!',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: context.successColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'One-time offer, valid for 1 month',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _handleDeclineOffer,
          style: TextButton.styleFrom(
            foregroundColor: context.onSurfaceVariantColor,
          ),
          child: const Text('No thanks, cancel anyway'),
        ),
        ElevatedButton(
          onPressed: _handleAcceptOffer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: context.theme.colorScheme.onPrimary,
          ),
          child: const Text('Accept Offer'),
        ),
      ],
    );
  }

  void _handleContinueCancellation() {
    if (_selectedReason == null) {
      // Show error - must select a reason
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a reason for cancellation'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Check if we should show retention offer
    final reason = _reasons.firstWhere((r) => r.id == _selectedReason);
    if (reason.showOffer) {
      setState(() {
        _showRetentionOffer = true;
      });
    } else {
      // Proceed with cancellation
      _confirmCancellation();
    }
  }

  void _handleAcceptOffer() {
    setState(() {
      _offerAccepted = true;
    });
  }

  void _handleDeclineOffer() {
    _confirmCancellation();
  }

  void _confirmCancellation() {
    Navigator.pop(context, {
      'confirmed': true,
      'reason': _selectedReason,
      'feedback': _feedbackController.text.trim(),
    });
  }
}

/// Cancellation reason model
class CancellationReason {
  final String id;
  final String label;
  final IconData icon;
  final bool showOffer;

  CancellationReason({
    required this.id,
    required this.label,
    required this.icon,
    required this.showOffer,
  });
}
