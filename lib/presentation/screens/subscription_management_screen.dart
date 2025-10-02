import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/subscription.dart';
import '../../data/models/subscription_plan.dart';
import '../../data/models/subscription_usage.dart';
import '../../data/services/subscription_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/usage_indicator.dart';
import '../widgets/subscription_status_card.dart';

/// Main subscription management screen
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late SubscriptionService _subscriptionService;
  
  Subscription? _currentSubscription;
  SubscriptionUsage? _currentUsage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _subscriptionService = context.read<SubscriptionService>();
    _loadSubscriptionData();
    _setupStreamListeners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupStreamListeners() {
    _subscriptionService.subscriptionStream.listen((subscription) {
      if (mounted) {
        setState(() {
          _currentSubscription = subscription;
        });
      }
    });

    _subscriptionService.usageStream.listen((usage) {
      if (mounted) {
        setState(() {
          _currentUsage = usage;
        });
      }
    });
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);
    
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      final usage = await _subscriptionService.getSubscriptionUsage();
      
      setState(() {
        _currentSubscription = subscription;
        _currentUsage = usage;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load subscription data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Subscription',
          style: AppTextStyles.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Plan'),
            Tab(text: 'Usage'),
            Tab(text: 'Plans'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCurrentPlanTab(),
                _buildUsageTab(),
                _buildPlansTab(),
              ],
            ),
    );
  }

  Widget _buildCurrentPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentSubscription != null) ...[
            SubscriptionStatusCard(
              subscription: _currentSubscription!,
              onCancel: _handleCancelSubscription,
              onResume: _handleResumeSubscription,
            ),
            const SizedBox(height: 24),
            _buildQuickActions(),
          ] else ...[
            _buildNoSubscriptionCard(),
          ],
          const SizedBox(height: 24),
          _buildSubscriptionHistory(),
        ],
      ),
    );
  }

  Widget _buildUsageTab() {
    if (_currentSubscription == null) {
      return _buildNoSubscriptionMessage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Overview',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (_currentUsage != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: UsageIndicator(
                usage: _currentUsage!,
              ),
            ),
          ] else ...[
            _buildEmptyUsageCard(),
          ],
          const SizedBox(height: 24),
          _buildUsageInsights(),
        ],
      ),
    );
  }

  Widget _buildPlansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Plans',
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...PredefinedPlans.plans.map((plan) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SubscriptionPlanCard(
              plan: plan,
              isCurrentPlan: _currentSubscription?.planId == plan.id,
              onSelect: () => _handleSubscribeToPlan(plan),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.card_membership_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Subscription',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Subscribe to a plan to unlock premium features',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          AppButton(
            text: 'View Plans',
            onPressed: () => _tabController.animateTo(2),
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Usage Data',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Subscribe to a plan to track your usage',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Change Plan',
                  onPressed: () => _tabController.animateTo(2),
                  variant: AppButtonVariant.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'View History',
                  onPressed: () => _tabController.animateTo(3),
                  variant: AppButtonVariant.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _navigateToPaymentHistory,
                child: Text(
                  'View All',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            'Subscription Renewed',
            'Dec 15, 2024',
            '\$19.99',
            Icons.refresh,
          ),
          _buildHistoryItem(
            'Plan Upgraded',
            'Nov 20, 2024',
            '\$29.99',
            Icons.arrow_upward,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String amount, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  date,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUsageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Usage Data Yet',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start using premium features to see your usage statistics',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageInsights() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Insights',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Peak Usage',
            'Weekends are your most active time',
            Icons.schedule,
          ),
          _buildInsightItem(
            'Trending Up',
            '15% increase from last month',
            Icons.trending_up,
          ),
          _buildInsightItem(
            'Feature Suggestion',
            'Consider upgrading for unlimited matches',
            Icons.lightbulb_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Action handlers
  Future<void> _handleCancelSubscription() async {
    final confirmed = await _showCancelConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isLoading = true);
    
    try {
      final result = await _subscriptionService.cancelSubscription(
        reason: 'User requested cancellation',
      );
      
      if (result.success) {
        _showSuccessSnackBar('Subscription cancelled successfully');
      } else {
        _showErrorSnackBar(result.error ?? 'Failed to cancel subscription');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to cancel subscription');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResumeSubscription() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _subscriptionService.resumeSubscription();
      
      if (result.success) {
        _showSuccessSnackBar('Subscription resumed successfully');
      } else {
        _showErrorSnackBar(result.error ?? 'Failed to resume subscription');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to resume subscription');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubscribeToPlan(SubscriptionPlan plan) async {
    // Navigate to payment method selection or subscription flow
    // This would integrate with your existing payment flow
    _showErrorSnackBar('Subscription flow not implemented yet');
  }

  void _navigateToPaymentHistory() {
    context.push('/payment-history');
  }

  Future<bool> _showCancelConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
}
