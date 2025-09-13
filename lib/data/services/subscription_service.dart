import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subscription.dart';
import '../models/subscription_plan.dart';
import '../models/subscription_usage.dart';
import '../models/api_response.dart';
import 'saved_payment_methods_service.dart';

/// Subscription service for managing user subscriptions
class SubscriptionService {
  final SavedPaymentMethodsService _savedMethodsService;
  
  // Logger instance
  final Logger _logger = Logger();
  
  // Stream controllers for reactive updates
  final StreamController<Subscription?> _subscriptionController = StreamController<Subscription?>.broadcast();
  final StreamController<SubscriptionUsage?> _usageController = StreamController<SubscriptionUsage?>.broadcast();

  SubscriptionService({
    required SavedPaymentMethodsService savedMethodsService,
  }) : _savedMethodsService = savedMethodsService;

  // Streams
  Stream<Subscription?> get subscriptionStream => _subscriptionController.stream;
  Stream<SubscriptionUsage?> get usageStream => _usageController.stream;

  /// Get current active subscription
  Future<Subscription?> getCurrentSubscription() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriptionData = prefs.getString('current_subscription');
      
      if (subscriptionData != null) {
        final json = jsonDecode(subscriptionData) as Map<String, dynamic>;
        return Subscription.fromJson(json);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error getting current subscription: $e');
      return null;
    }
  }

  /// Subscribe to a plan using saved payment method
  Future<ApiResponse<Subscription>> subscribeToPlan({
    required SubscriptionPlan plan,
    required String paymentMethodId,
    String? promoCode,
  }) async {
    try {
      // Validate payment method exists
      final paymentMethod = await _savedMethodsService.getPaymentMethodById(paymentMethodId);
      if (paymentMethod == null) {
        return ApiResponse.error('Payment method not found');
      }

      // Calculate pricing (simplified for now)
      final finalAmount = plan.amount; // TODO: Apply promo code discounts

      // Process initial payment
      final paymentResult = await _savedMethodsService.payWithSavedMethod(
        methodId: paymentMethodId,
        amount: finalAmount,
        currency: plan.currency,
        description: 'Subscription: ${plan.name}',
        metadata: {
          'subscription_plan_id': plan.id,
          'billing_cycle': plan.billingCycle.name,
          'promo_code': promoCode,
        },
      );

      if (!paymentResult['success']) {
        return ApiResponse.error(paymentResult['error'] ?? 'Payment failed');
      }

      // Create subscription record
      final subscription = Subscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user', // TODO: Get from auth service
        planId: plan.id,
        status: SubscriptionStatus.active,
        startDate: DateTime.now(),
        endDate: _calculateNextBillingDate(plan.billingCycle),
        paymentMethodId: paymentMethodId,
        amountPaid: finalAmount,
        currency: plan.currency,
        autoRenew: true,
        metadata: {
          'payment_id': paymentResult['payment_id'],
          'promo_code': promoCode,
          'plan_name': plan.name,
          'billing_cycle': plan.billingCycle.name,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save subscription
      await _saveSubscription(subscription);
      _subscriptionController.add(subscription);

      // Initialize usage tracking
      await _initializeUsageTracking(subscription, plan);

      return ApiResponse.success(subscription);
    } catch (e) {
      return ApiResponse.error('Subscription failed: $e');
    }
  }

  /// Cancel subscription
  Future<ApiResponse<Subscription>> cancelSubscription({
    bool cancelImmediately = false,
    String? reason,
  }) async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        return ApiResponse.error('No active subscription found');
      }

      if (subscription.status == SubscriptionStatus.cancelled) {
        return ApiResponse.error('Subscription already cancelled');
      }

      // Update subscription status
      final updatedSubscription = subscription.copyWith(
        status: cancelImmediately ? SubscriptionStatus.cancelled : SubscriptionStatus.pendingCancellation,
        cancelledAt: DateTime.now(),
        cancellationReason: reason,
        autoRenew: false,
        updatedAt: DateTime.now(),
      );

      await _saveSubscription(updatedSubscription);
      _subscriptionController.add(updatedSubscription);

      return ApiResponse.success(updatedSubscription);
    } catch (e) {
      return ApiResponse.error('Cancellation failed: $e');
    }
  }

  /// Resume cancelled subscription
  Future<ApiResponse<Subscription>> resumeSubscription() async {
    try {
      final subscription = await getCurrentSubscription();
      if (subscription == null) {
        return ApiResponse.error('No subscription found');
      }

      if (subscription.status != SubscriptionStatus.pendingCancellation) {
        return ApiResponse.error('Subscription cannot be resumed');
      }

      final updatedSubscription = subscription.copyWith(
        status: SubscriptionStatus.active,
        cancelledAt: null,
        cancellationReason: null,
        autoRenew: true,
        updatedAt: DateTime.now(),
      );

      await _saveSubscription(updatedSubscription);
      _subscriptionController.add(updatedSubscription);

      return ApiResponse.success(updatedSubscription);
    } catch (e) {
      return ApiResponse.error('Resume failed: $e');
    }
  }

  /// Change subscription plan
  Future<ApiResponse<Subscription>> changePlan({
    required SubscriptionPlan newPlan,
    bool prorated = true,
  }) async {
    try {
      final currentSubscription = await getCurrentSubscription();
      if (currentSubscription == null) {
        return ApiResponse.error('No active subscription found');
      }

      if (currentSubscription.planId == newPlan.id) {
        return ApiResponse.error('Already subscribed to this plan');
      }

      // Calculate prorated amount if upgrading
      double proratedAmount = 0;
      if (prorated && newPlan.amount > currentSubscription.amountPaid) {
        proratedAmount = _calculateProratedAmount(currentSubscription, newPlan);
      }

      // Process prorated payment if needed
      if (proratedAmount > 0 && currentSubscription.paymentMethodId != null) {
        final paymentResult = await _savedMethodsService.payWithSavedMethod(
          methodId: currentSubscription.paymentMethodId!,
          amount: proratedAmount,
          currency: newPlan.currency,
          description: 'Plan upgrade: ${newPlan.name}',
        );

        if (!paymentResult['success']) {
          return ApiResponse.error('Payment for plan upgrade failed');
        }
      }

      // Update subscription
      final updatedSubscription = currentSubscription.copyWith(
        planId: newPlan.id,
        amountPaid: newPlan.amount,
        currency: newPlan.currency,
        endDate: _calculateNextBillingDate(newPlan.billingCycle),
        metadata: {
          ...?currentSubscription.metadata,
          'plan_name': newPlan.name,
          'billing_cycle': newPlan.billingCycle.name,
          'upgraded_at': DateTime.now().toIso8601String(),
        },
        updatedAt: DateTime.now(),
      );

      await _saveSubscription(updatedSubscription);
      _subscriptionController.add(updatedSubscription);

      // Update usage limits for new plan
      await _updateUsageLimits(updatedSubscription, newPlan);

      return ApiResponse.success(updatedSubscription);
    } catch (e) {
      return ApiResponse.error('Plan change failed: $e');
    }
  }

  /// Get subscription usage
  Future<SubscriptionUsage?> getSubscriptionUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageData = prefs.getString('subscription_usage');
      
      if (usageData != null) {
        final json = jsonDecode(usageData) as Map<String, dynamic>;
        return SubscriptionUsage.fromJson(json);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error getting subscription usage: $e');
      return null;
    }
  }

  /// Track feature usage
  Future<bool> trackFeatureUsage(String feature, {int increment = 1}) async {
    try {
      final subscription = await getCurrentSubscription();
      final usage = await getSubscriptionUsage() ?? SubscriptionUsage.empty();
      
      if (subscription == null) return false;

      // Get current usage for this feature
      final currentCounter = usage.getFeatureUsage(feature);
      final newCounter = currentCounter.increment();

      // Update usage
      final updatedUsage = usage.copyWith(
        usage: {...usage.usage, feature: newCounter},
        lastUpdated: DateTime.now(),
      );

      await _saveUsage(updatedUsage);
      _usageController.add(updatedUsage);

      return true;
    } catch (e) {
      _logger.e('Error tracking feature usage: $e');
      return false;
    }
  }

  /// Check if feature is available
  Future<bool> isFeatureAvailable(String feature, {int amount = 1}) async {
    try {
      final subscription = await getCurrentSubscription();
      final usage = await getSubscriptionUsage();
      
      if (subscription == null || subscription.status != SubscriptionStatus.active) {
        return false;
      }

      if (usage == null) return true; // No limits tracked yet

      final counter = usage.getFeatureUsage(feature);
      return !counter.isLimitReached;
    } catch (e) {
      _logger.e('Error checking feature availability: $e');
      return false;
    }
  }

  /// Get remaining feature usage
  Future<int> getRemainingUsage(String feature) async {
    try {
      final usage = await getSubscriptionUsage();
      if (usage == null) return -1; // Unlimited

      final counter = usage.getFeatureUsage(feature);
      return counter.remaining;
    } catch (e) {
      _logger.e('Error getting remaining usage: $e');
      return 0;
    }
  }

  /// Process subscription renewal
  Future<bool> processRenewal(Subscription subscription) async {
    try {
      if (subscription.paymentMethodId == null) {
        return false;
      }

      // Process renewal payment
      final paymentResult = await _savedMethodsService.payWithSavedMethod(
        methodId: subscription.paymentMethodId!,
        amount: subscription.amountPaid,
        currency: subscription.currency,
        description: 'Subscription renewal',
      );

      if (!paymentResult['success']) {
        // Mark subscription as past due
        final updatedSubscription = subscription.copyWith(
          status: SubscriptionStatus.pastDue,
          updatedAt: DateTime.now(),
        );
        await _saveSubscription(updatedSubscription);
        return false;
      }

      // Successful renewal
      final renewedSubscription = subscription.copyWith(
        startDate: subscription.endDate ?? DateTime.now(),
        endDate: _calculateNextBillingDate(_getBillingCycleFromMetadata(subscription)),
        status: SubscriptionStatus.active,
        metadata: {
          ...?subscription.metadata,
          'last_renewal': DateTime.now().toIso8601String(),
          'payment_id': paymentResult['payment_id'],
        },
        updatedAt: DateTime.now(),
      );

      await _saveSubscription(renewedSubscription);
      _subscriptionController.add(renewedSubscription);

      // Reset usage for new billing period
      await _resetUsageForNewPeriod(renewedSubscription);

      return true;
    } catch (e) {
      _logger.e('Error processing renewal: $e');
      return false;
    }
  }

  /// Check if subscription is expired
  bool isSubscriptionExpired(Subscription subscription) {
    if (subscription.endDate == null) return false;
    return DateTime.now().isAfter(subscription.endDate!);
  }

  /// Get days until renewal
  int getDaysUntilRenewal(Subscription subscription) {
    if (subscription.endDate == null) return -1;
    return subscription.endDate!.difference(DateTime.now()).inDays;
  }

  /// Helper methods
  DateTime _calculateNextBillingDate(BillingCycle cycle) {
    final now = DateTime.now();
    switch (cycle) {
      case BillingCycle.weekly:
        return DateTime(now.year, now.month, now.day + 7);
      case BillingCycle.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case BillingCycle.quarterly:
        return DateTime(now.year, now.month + 3, now.day);
      case BillingCycle.yearly:
        return DateTime(now.year + 1, now.month, now.day);
    }
  }

  BillingCycle _getBillingCycleFromMetadata(Subscription subscription) {
    final cycleString = subscription.metadata?['billing_cycle'] as String?;
    switch (cycleString) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'quarterly':
        return BillingCycle.quarterly;
      case 'yearly':
        return BillingCycle.yearly;
      default:
        return BillingCycle.monthly;
    }
  }

  double _calculateProratedAmount(Subscription current, SubscriptionPlan newPlan) {
    if (current.endDate == null) return newPlan.amount;
    
    final now = DateTime.now();
    final remainingDays = current.endDate!.difference(now).inDays;
    final totalDays = current.endDate!.difference(current.startDate).inDays;
    
    if (totalDays <= 0) return newPlan.amount;
    
    final remainingValue = (current.amountPaid * remainingDays) / totalDays;
    return (newPlan.amount - remainingValue).clamp(0, newPlan.amount);
  }

  Future<void> _saveSubscription(Subscription subscription) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_subscription', jsonEncode(subscription.toJson()));
  }

  Future<void> _saveUsage(SubscriptionUsage usage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subscription_usage', jsonEncode(usage.toJson()));
  }

  Future<void> _initializeUsageTracking(Subscription subscription, SubscriptionPlan plan) async {
    final usage = SubscriptionUsage(
      subscriptionId: subscription.id,
      planId: plan.id,
      periodStart: subscription.startDate,
      periodEnd: subscription.endDate ?? _calculateNextBillingDate(_getBillingCycleFromMetadata(subscription)),
      usage: {},
      lastUpdated: DateTime.now(),
    );

    await _saveUsage(usage);
    _usageController.add(usage);
  }

  Future<void> _updateUsageLimits(Subscription subscription, SubscriptionPlan plan) async {
    // Implementation would update usage limits based on new plan
    // For now, just reset usage tracking
    await _initializeUsageTracking(subscription, plan);
  }

  Future<void> _resetUsageForNewPeriod(Subscription subscription) async {
    final usage = SubscriptionUsage(
      subscriptionId: subscription.id,
      planId: subscription.planId,
      periodStart: subscription.startDate,
      periodEnd: subscription.endDate ?? DateTime.now(),
      usage: {}, // Reset all usage counters
      lastUpdated: DateTime.now(),
    );

    await _saveUsage(usage);
    _usageController.add(usage);
  }

  /// Dispose resources
  void dispose() {
    _subscriptionController.close();
    _usageController.close();
  }
}
