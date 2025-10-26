import 'package:flutter/material.dart';
import '../../data/models/subscription.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';


/// Widget to display current subscription status and actions
class SubscriptionStatusCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback? onCancel;
  final VoidCallback? onResume;

  const SubscriptionStatusCard({
    super.key,
    required this.subscription,
    this.onCancel,
    this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPlanName(),
                      style: AppTextStyles.heading4.copyWith(
                        color: context.onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusChip(context),
                        const SizedBox(width: 8),
                        Text(
                          '\$${subscription.amountPaid.toStringAsFixed(2)}/${_getBillingCycleText()}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.onSurfaceVariantColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusIcon(context),
            ],
          ),
          const SizedBox(height: 16),
          _buildSubscriptionDetails(context),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final status = subscription.status;
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case SubscriptionStatus.active:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        text = 'Active';
        break;
      case SubscriptionStatus.cancelled:
        backgroundColor = context.errorColor.withValues(alpha: 0.1);
        textColor = context.errorColor;
        text = 'Cancelled';
        break;
      case SubscriptionStatus.pendingCancellation:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        text = 'Ends Soon';
        break;
      case SubscriptionStatus.expired:
        backgroundColor = context.errorColor.withValues(alpha: 0.1);
        textColor = context.errorColor;
        text = 'Expired';
        break;
      case SubscriptionStatus.pastDue:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        text = 'Past Due';
        break;
      default:
        backgroundColor = context.onSurfaceVariantColor.withValues(alpha: 0.1);
        textColor = context.onSurfaceVariantColor;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (subscription.status) {
      case SubscriptionStatus.active:
        icon = Icons.check_circle;
        color = AppColors.success;
        break;
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        icon = Icons.cancel;
        color = context.errorColor;
        break;
      case SubscriptionStatus.pendingCancellation:
        icon = Icons.schedule;
        color = AppColors.warning;
        break;
      case SubscriptionStatus.pastDue:
        icon = Icons.payment;
        color = AppColors.warning;
        break;
      default:
        icon = Icons.hourglass_empty;
        color = context.onSurfaceVariantColor;
    }

    return Icon(icon, size: 32, color: color);
  }

  Widget _buildSubscriptionDetails(BuildContext context) {
    return Column(
      children: [
        _buildDetailRow(
          context,
          'Start Date',
          _formatDate(subscription.startDate),
          Icons.event_available,
        ),
        if (subscription.endDate != null) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            subscription.status == SubscriptionStatus.pendingCancellation
                ? 'Ends On'
                : 'Next Billing',
            _formatDate(subscription.endDate!),
            Icons.event,
          ),
        ],
        if (subscription.cancelledAt != null) ...[
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Cancelled On',
            _formatDate(subscription.cancelledAt!),
            Icons.event_busy,
          ),
        ],
        const SizedBox(height: 12),
        _buildDetailRow(
          context,
          'Auto Renew',
          subscription.autoRenew ? 'Enabled' : 'Disabled',
          subscription.autoRenew ? Icons.refresh : Icons.pause_circle,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.onSurfaceVariantColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.onSurfaceVariantColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.onSurfaceColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final canCancel = subscription.status == SubscriptionStatus.active;
    final canResume =
        subscription.status == SubscriptionStatus.pendingCancellation;

    if (!canCancel && !canResume) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (canResume) ...[
          Expanded(
            child: AppButton(text: 'Resume Subscription', onPressed: onResume),
          ),
        ] else if (canCancel) ...[
          Expanded(
            child: AppButton(
              text: 'Cancel Subscription',
              onPressed: onCancel,
              variant: AppButtonVariant.outline,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusBorderColor(BuildContext context) {
    switch (subscription.status) {
      case SubscriptionStatus.active:
        return AppColors.success;
      case SubscriptionStatus.cancelled:
      case SubscriptionStatus.expired:
        return context.errorColor;
      case SubscriptionStatus.pendingCancellation:
      case SubscriptionStatus.pastDue:
        return AppColors.warning;
      default:
        return context.outlineColor;
    }
  }

  String _getPlanName() {
    // Try to get plan name from metadata first, fallback to plan ID
    return subscription.metadata?['plan_name'] as String? ??
        subscription.planId;
  }

  String _getBillingCycleText() {
    final cycle = subscription.metadata?['billing_cycle'] as String?;
    switch (cycle) {
      case 'weekly':
        return 'week';
      case 'quarterly':
        return 'quarter';
      case 'yearly':
        return 'year';
      default:
        return 'month';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
