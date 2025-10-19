import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/models/subscription.dart';
import '../../data/models/payment_transaction.dart';
import '../../core/theme/app_colors.dart';
import '../blocs/subscription/subscription_bloc.dart';
import '../blocs/payment/payment_bloc.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/pulse_toast.dart';
import 'cancellation_reason_dialog.dart';

/// Bottom sheet for managing subscription
class SubscriptionManagementSheet extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionManagementSheet({
    super.key,
    required this.subscription,
  });

  @override
  State<SubscriptionManagementSheet> createState() =>
      _SubscriptionManagementSheetState();
}

class _SubscriptionManagementSheetState
    extends State<SubscriptionManagementSheet> {
  List<dynamic> _transactions = [];
  bool _isLoadingTransactions = true;

  @override
  void initState() {
    super.initState();
    _loadBillingHistory();
  }

  Future<void> _loadBillingHistory() async {
    // Load last 3 transactions related to this subscription
    context.read<PaymentBloc>().add(
          LoadPaymentHistoryEvent(
            subscriptionId: widget.subscription.id,
            limit: 3,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Manage Subscription',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content
          Expanded(
            child: BlocListener<SubscriptionBloc, SubscriptionState>(
              listener: (context, state) {
                if (state is SubscriptionSuccess) {
                  PulseToast.success(context, message: state.message);
                  Navigator.pop(context);
                } else if (state is SubscriptionError) {
                  PulseToast.error(context, message: state.message);
                }
              },
              child: BlocBuilder<PaymentBloc, PaymentState>(
                builder: (context, paymentState) {
                  if (paymentState is PaymentHistoryLoaded) {
                    _transactions = paymentState.transactions;
                    _isLoadingTransactions = false;
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current subscription card
                        _buildSubscriptionDetailsCard(),
                        const SizedBox(height: 24),

                        // Billing history
                        _buildBillingHistorySection(),
                        const SizedBox(height: 24),

                        // Subscription actions
                        _buildSubscriptionActionsSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetailsCard() {
    final subscription = widget.subscription;
    final isActive = subscription.status == SubscriptionStatus.active;
    final isPendingCancellation =
        subscription.status == SubscriptionStatus.pendingCancellation;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [AppColors.primary, Color(0xFF9D4EDD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey[400]!, Colors.grey[500]!],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.workspace_premium : Icons.pause_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subscription.plan?.name ?? 'Premium Plan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subscription.formattedAmountPaid,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subscription.statusText.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),

          // Subscription details
          _buildDetailRow(
            Icons.calendar_today,
            'Started',
            DateFormat('MMM dd, yyyy').format(subscription.startDate),
          ),
          const SizedBox(height: 12),
          if (subscription.endDate != null)
            _buildDetailRow(
              Icons.event_available,
              isPendingCancellation ? 'Expires' : 'Next Billing',
              DateFormat('MMM dd, yyyy').format(subscription.endDate!),
            ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.autorenew,
            'Auto-Renew',
            subscription.autoRenew ? 'Enabled' : 'Disabled',
          ),
          if (isPendingCancellation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your subscription will not renew. You can still use premium features until ${subscription.endDate != null ? DateFormat('MMM dd').format(subscription.endDate!) : 'the end of your billing period'}.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItemFromMap(Map<String, dynamic> transactionData) {
    final isCompleted = transactionData['status'] == 'completed';
    final isRefunded = transactionData['status'] == 'refunded';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green[50]
                  : isRefunded
                      ? Colors.orange[50]
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle
                  : isRefunded
                      ? Icons.refresh
                      : Icons.error_outline,
              color: isCompleted
                  ? Colors.green
                  : isRefunded
                      ? Colors.orange
                      : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transactionData['description'] ?? 'Transaction',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transactionData['date'] ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transactionData['currency'] ?? 'USD'} ${(transactionData['amount'] ?? 0.0).toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isRefunded ? Colors.orange : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (transactionData['status'] ?? 'PENDING').toString().toUpperCase(),
                style: TextStyle(
                  color: isCompleted
                      ? Colors.green
                      : isRefunded
                          ? Colors.orange
                          : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillingHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Billing History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full billing history screen
                Navigator.pushNamed(context, '/transaction-history');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingTransactions)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: LoadingIndicator(),
            ),
          )
        else if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No billing history available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          )
        else
          ..._transactions.map((transaction) {
            if (transaction is PaymentTransaction) {
              return _buildTransactionItem(transaction);
            } else if (transaction is Map<String, dynamic>) {
              return _buildTransactionItemFromMap(transaction);
            }
            return const SizedBox.shrink();
          }),
      ],
    );
  }

  Widget _buildTransactionItem(PaymentTransaction transaction) {
    final isCompleted = transaction.status == PaymentTransactionStatus.completed;
    final isRefunded = transaction.status == PaymentTransactionStatus.refunded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green[50]
                  : isRefunded
                      ? Colors.orange[50]
                      : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle
                  : isRefunded
                      ? Icons.refresh
                      : Icons.error_outline,
              color: isCompleted
                  ? Colors.green
                  : isRefunded
                      ? Colors.orange
                      : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.processedAt),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.currency} ${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isRefunded ? Colors.orange : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.status.name.toUpperCase(),
                style: TextStyle(
                  color: isCompleted
                      ? Colors.green
                      : isRefunded
                          ? Colors.orange
                          : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionActionsSection() {
    final subscription = widget.subscription;
    final isPaused = subscription.status == SubscriptionStatus.suspended;
    final isPendingCancellation =
        subscription.status == SubscriptionStatus.pendingCancellation;
    final isActive = subscription.status == SubscriptionStatus.active;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Resume subscription (if paused or pending cancellation)
        if (isPaused || isPendingCancellation)
          _buildActionButton(
            icon: Icons.play_circle_filled,
            label: isPaused ? 'Resume Subscription' : 'Reactivate Auto-Renew',
            color: AppColors.primary,
            onPressed: _resumeSubscription,
          ),

        // Pause subscription (if active)
        if (isActive && !isPendingCancellation)
          _buildActionButton(
            icon: Icons.pause_circle_outline,
            label: 'Pause Subscription',
            color: Colors.orange,
            onPressed: _showPauseOptions,
          ),

        if (isActive && !isPendingCancellation) const SizedBox(height: 12),

        // Change plan
        if (isActive)
          _buildActionButton(
            icon: Icons.swap_horiz,
            label: 'Change Plan',
            color: Colors.blue,
            onPressed: _showChangePlanOptions,
          ),

        if (isActive) const SizedBox(height: 12),

        // Cancel subscription (if active or paused)
        if (!isPendingCancellation)
          _buildActionButton(
            icon: Icons.cancel_outlined,
            label: 'Cancel Subscription',
            color: Colors.red,
            onPressed: _showCancellationDialog,
          ),

        const SizedBox(height: 24),

        // Support contact
        Center(
          child: Column(
            children: [
              Text(
                'Need help?',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Open support contact
                },
                child: const Text(
                  'Contact Support',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showPauseOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pause Subscription',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'How long would you like to pause your subscription?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildPauseOption('1 month', 1),
            _buildPauseOption('3 months', 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOption(String label, int months) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          _pauseSubscription(months);
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Text(label),
      ),
    );
  }

  void _pauseSubscription(int months) {
    context.read<SubscriptionBloc>().add(
          PauseSubscriptionEvent(months: months),
        );
  }

  void _resumeSubscription() {
    context.read<SubscriptionBloc>().add(ResumeSubscriptionEvent());
  }

  void _showChangePlanOptions() {
    // Navigate to plan selection screen
    Navigator.pushNamed(context, '/premium');
  }

  Future<void> _showCancellationDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CancellationReasonDialog(),
    );

    if (result != null && result['confirmed'] == true) {
      final reason = result['reason'] as String?;

      context.read<SubscriptionBloc>().add(
            CancelSubscriptionEvent(
              reason: reason ?? 'No reason provided',
            ),
          );
    }
  }
}
