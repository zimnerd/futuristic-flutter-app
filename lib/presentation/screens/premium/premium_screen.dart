import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/premium.dart';
import '../../blocs/premium/premium_bloc.dart';
import '../../blocs/premium/premium_event.dart';
import '../../blocs/premium/premium_state.dart';
import '../../theme/pulse_colors.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/common/pulse_loading_widget.dart';
import '../../widgets/common/pulse_error_widget.dart';
import '../../widgets/premium/subscription_plans_widget.dart';
import '../../widgets/premium/current_subscription_widget.dart';
import '../../widgets/premium/coin_balance_widget.dart';
import '../../widgets/premium/premium_features_widget.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
        backgroundColor: context.primaryColor,
        foregroundColor: context.onPrimaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.onPrimaryColor,
          unselectedLabelColor: context.onPrimaryColor.withValues(alpha: 0.7),
          indicatorColor: context.onPrimaryColor,
          tabs: const [
            Tab(text: 'Plans', icon: Icon(Icons.star)),
            Tab(text: 'Features', icon: Icon(Icons.featured_play_list)),
            Tab(text: 'Account', icon: Icon(Icons.account_circle)),
          ],
        ),
      ),
      body: BlocConsumer<PremiumBloc, PremiumState>(
        listener: (context, state) {
          if (state is PremiumError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: context.errorColor,
              ),
            );
          }
          
          if (state is PremiumSubscriptionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Subscription updated successfully!'),
                backgroundColor: context.successColor,
              ),
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

          return const Center(
            child: Text('Welcome to Premium!'),
          );
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
              onManageSubscription: () => _showSubscriptionManagement(state.subscription!),
            ),
          
          const SizedBox(height: 24),
          
          // Subscription plans
          Text(
            'Choose Your Plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SubscriptionPlansWidget(
            plans: state.plans,
            currentSubscription: state.subscription,
            onPlanSelected: _handlePlanSelection,
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
          
          PremiumFeaturesWidget(
            subscription: state.subscription,
          ),
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
            leading: const Icon(Icons.receipt_long),
            title: const Text('Billing History'),
            subtitle: const Text('View your payment history'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showBillingHistory(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Payment Methods'),
            subtitle: const Text('Manage your payment options'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showPaymentMethods(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Premium Support'),
            subtitle: const Text('Get help with your subscription'),
            trailing: const Icon(Icons.arrow_forward_ios),
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
              subtitle: const Text('Cancel your premium subscription'),
              trailing: const Icon(Icons.arrow_forward_ios),
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
            
            Icon(
              Icons.star,
              size: 64,
              color: PulseColors.primary,
            ),
            const SizedBox(height: 16),
            
            Text(
              'Upgrade to ${plan.name}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            ...plan.features.take(3).map((feature) => Padding(
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
            )),
            
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
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => _confirmPurchase(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: context.onPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Subscribe'),
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
        paymentMethodId: 'default_payment_method', // This would come from payment selection
      ),
    );
  }

  void _showSubscriptionManagement(UserSubscription subscription) {
    // Implementation for subscription management
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Subscription'),
        content: const Text('Subscription management functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCoinPurchaseDialog() {
    // Implementation for coin purchase
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Coins'),
        content: const Text('Coin purchase functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
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
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your premium subscription? '
          'You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PremiumBloc>().add(CancelSubscription());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}
