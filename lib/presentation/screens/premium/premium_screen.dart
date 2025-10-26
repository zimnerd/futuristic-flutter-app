import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../data/models/premium.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/premium_service.dart';
import '../../blocs/coin_purchase/coin_purchase_bloc.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../../blocs/premium/premium_state.dart';
import '../../sheets/coin_purchase_sheet.dart';
import '../../theme/pulse_colors.dart';
import 'package:pulse_dating_app/core/theme/theme_extensions.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/premium/subscription_plans_widget.dart';
import '../../widgets/premium/current_subscription_widget.dart';
import '../../widgets/premium/coin_balance_widget.dart';
import '../../widgets/premium/premium_features_widget.dart';
import '../../widgets/common/pulse_toast.dart';

/// Main screen for premium subscription management
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load premium data
    context.read<PremiumBloc>().add(LoadPremiumData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: Text('Premium'),
        backgroundColor: context.primaryColor,
        foregroundColor: context.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.primaryColor,
          unselectedLabelColor: context.primaryColor.withValues(alpha: 0.7),
          indicatorColor: context.primaryColor,
          tabs: isSmallScreen
              ? const [
                  Tab(icon: Icon(Icons.star)),
                  Tab(icon: Icon(Icons.featured_play_list)),
                  Tab(icon: Icon(Icons.account_circle)),
                ]
              : const [
                  Tab(text: 'Plans', icon: Icon(Icons.star)),
                  Tab(text: 'Features', icon: Icon(Icons.featured_play_list)),
                  Tab(text: 'Account', icon: Icon(Icons.account_circle)),
                ],
        ),
      ),
      body: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          if (state is PremiumError) {
            PulseToast.error(context, message: state.message);
          }

          if (state is PremiumSubscriptionSuccess) {
            PulseToast.success(
              context,
              message: 'Subscription updated successfully!',
            );
          }
        },
        builder: (context, state) {
          if (state is PremiumLoading) {
            return const PulseLoadingWidget();
          }

          if (state is PremiumError) {
            return PulseErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<PremiumBloc>().add(LoadPremiumData());
              },
            );
          }

          if (state is PremiumLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildPlansTab(state),
                _buildFeaturesTab(state),
                _buildAccountTab(state),
              ],
            );
          }

          return Center(child: Text('Welcome to Premium!'));
        },
      ),
    );
  }

  Widget _buildPlansTab(PremiumLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current subscription status
          if (state.subscription != null)
            CurrentSubscriptionWidget(
              subscription: state.subscription!,
              onManageSubscription: () =>
                  _showSubscriptionManagement(state.subscription!),
            ),

          const SizedBox(height: 24),

          // Subscription plans
          Text(
            'Choose Your Plan',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Upgrade to unlock premium features and connect with more people',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
          ),
          const SizedBox(height: 16),

          // Plans list or empty state
          if (state.plans.isEmpty)
            _buildNoPlansSplash(context)
          else
            SubscriptionPlansWidget(
              plans: state.plans,
              currentSubscription: state.subscription,
              onPlanSelected: _handlePlanSelection,
            ),
        ],
      ),
    );
  }

  Widget _buildNoPlansSplash(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.outlineColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: context.onSurfaceVariantColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Premium Plans Unavailable',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium subscription plans are currently unavailable. Please try again later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.onSurfaceVariantColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<PremiumBloc>().add(LoadPremiumData());
            },
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(PremiumLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurrentSubscriptionWidget(
            subscription: state.subscription,
            onManageSubscription: state.subscription != null
                ? () => _showSubscriptionManagement(state.subscription!)
                : null,
          ),

          PremiumFeaturesWidget(subscription: state.subscription),
        ],
      ),
    );
  }

  Widget _buildAccountTab(PremiumLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coin balance
          CoinBalanceWidget(
            coinBalance: state.coinBalance,
            onBuyCoins: () => _showCoinPurchaseDialog(),
          ),

          const SizedBox(height: 24),

          // Account settings
          _buildAccountSettings(state),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(PremiumLoaded state) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.receipt_long),
            title: Text(
              'Billing History',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'View your payment history',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showBillingHistory(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.credit_card),
            title: Text(
              'Payment Methods',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Manage your payment options',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showPaymentMethods(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.help_outline),
            title: Text(
              'Premium Support',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Get help with your subscription',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () => _showPremiumSupport(),
          ),
          if (state.subscription != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.cancel, color: context.errorColor),
              title: Text(
                'Cancel Subscription',
                style: TextStyle(color: context.errorColor),
              ),
              subtitle: Text(
                'Cancel your premium subscription',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => _showCancellationDialog(state.subscription!),
            ),
          ],
        ],
      ),
    );
  }

  void _handlePlanSelection(PremiumPlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPurchaseBottomSheet(plan),
    );
  }

  Widget _buildPurchaseBottomSheet(PremiumPlan plan) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.outlineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Icon(Icons.star, size: 64, color: PulseColors.primary),
            const SizedBox(height: 16),

            Text(
              'Upgrade to ${plan.name}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Text(
              plan.formattedPrice,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: PulseColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Features list
            ...plan.features
                .take(3)
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          color: context.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _confirmPurchase(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Subscribe'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Cancel anytime. No commitment.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.onSurfaceVariantColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmPurchase(PremiumPlan plan) {
    Navigator.of(context).pop();
    context.read<PremiumBloc>().add(
      SubscribeToPlan(
        planId: plan.id,
        paymentMethodId:
            'default_payment_method', // This would come from payment selection
      ),
    );
  }

  void _showSubscriptionManagement(UserSubscription subscription) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: MediaQuery.of(context).viewInsets,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.outlineColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Manage Subscription',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Current plan info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: PulseColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PulseColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.onSurfaceVariantColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subscription.planName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: PulseColors.primary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildSubscriptionDetail(
                        'Started',
                        subscription.startDate.toString().split(' ')[0],
                      ),
                      if (subscription.nextBillingDate != null) ...[
                        const SizedBox(height: 8),
                        _buildSubscriptionDetail(
                          'Next Billing',
                          subscription.nextBillingDate.toString().split(' ')[0],
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildSubscriptionDetail(
                        'Auto-renewal',
                        subscription.autoRenew ? 'Enabled' : 'Disabled',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Auto-renewal toggle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceVariantColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-renewal',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Auto-renew at next billing date',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: context.onSurfaceVariantColor,
                                ),
                          ),
                        ],
                      ),
                      Switch(
                        value: subscription.autoRenew,
                        onChanged: (value) {
                          // TODO: Implement auto-renewal toggle
                          Navigator.of(context).pop();
                          PulseToast.info(
                            context,
                            message: 'Auto-renewal update coming soon',
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.onSurfaceVariantColor),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _showCoinPurchaseDialog() {
    // Show coin purchase sheet with BlocProvider to ensure bloc is available
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => BlocProvider(
        create: (context) => CoinPurchaseBloc(
          paymentService: PaymentService.instance,
          premiumService: PremiumService(ApiClient.instance),
        ),
        child: const CoinPurchaseSheet(),
      ),
    );
  }

  void _showBillingHistory() {
    // Implementation for billing history
  }

  void _showPaymentMethods() {
    // Implementation for payment methods
  }

  void _showPremiumSupport() {
    // Implementation for premium support
  }

  void _showCancellationDialog(UserSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Cancel Subscription',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel your premium subscription? '
          'You will lose access to premium features at the end of your billing period.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: PulseColors.primary),
            child: Text(
              'Keep Subscription',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PremiumBloc>().add(CancelSubscription());
            },
            style: TextButton.styleFrom(foregroundColor: context.errorColor),
            child: Text(
              'Cancel Subscription',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
