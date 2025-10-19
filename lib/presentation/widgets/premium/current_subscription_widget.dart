import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/premium.dart';
import '../../theme/pulse_colors.dart';

class CurrentSubscriptionWidget extends StatelessWidget {
  final UserSubscription? subscription;
  final VoidCallback? onManageSubscription;

  const CurrentSubscriptionWidget({
    super.key,
    this.subscription,
    this.onManageSubscription,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: PulseColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Current Subscription',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onManageSubscription != null)
                  TextButton(
                    onPressed: onManageSubscription,
                    child: const Text('Manage'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            if (subscription == null) ...[
              _buildFreePlan(context),
            ] else ...[
              _buildActivePlan(context, subscription!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreePlan(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'FREE PLAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'You\'re currently on the free plan',
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 8),

        Text(
          'Upgrade to unlock premium features and enhance your dating experience.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onManageSubscription,
            style: ElevatedButton.styleFrom(
              backgroundColor: PulseColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Upgrade Now',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivePlan(BuildContext context, UserSubscription subscription) {
    final isActive = subscription.status == SubscriptionStatus.active;
    final statusColor = _getStatusColor(subscription.status);
    final statusText = _getStatusText(subscription.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            const Spacer(),
            if (subscription.autoRenew)
              Icon(Icons.autorenew, size: 16, color: Colors.green[600]),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          subscription.planName,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        if (subscription.nextBillingDate != null) ...[
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                isActive
                    ? 'Next billing: ${_formatDate(subscription.nextBillingDate!)}'
                    : 'Expires: ${_formatDate(subscription.nextBillingDate!)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              'Started: ${_formatDate(subscription.startDate)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Auto-renewal toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Auto-renewal',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Switch(
              value: subscription.autoRenew,
              onChanged: null, // Would be handled by parent
              activeThumbColor: PulseColors.primary,
            ),
          ],
        ),

        if (!isActive) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subscription.status == SubscriptionStatus.cancelled
                        ? 'Your subscription has been cancelled'
                        : 'Your subscription is not active',
                    style: TextStyle(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.expired:
        return Colors.grey;
      case SubscriptionStatus.inactive:
        return Colors.grey;
      case SubscriptionStatus.pastDue:
        return Colors.orange;
      case SubscriptionStatus.suspended:
        return Colors.red;
      case SubscriptionStatus.pending:
        return Colors.blue;
      case SubscriptionStatus.failed:
        return Colors.red;
      case SubscriptionStatus.pendingCancellation:
        return Colors.orange;
    }
  }

  String _getStatusText(SubscriptionStatus status) {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.inactive:
        return 'Inactive';
      case SubscriptionStatus.pastDue:
        return 'Past Due';
      case SubscriptionStatus.suspended:
        return 'Suspended';
      case SubscriptionStatus.pending:
        return 'Pending';
      case SubscriptionStatus.failed:
        return 'Failed';
      case SubscriptionStatus.pendingCancellation:
        return 'Cancelling';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
