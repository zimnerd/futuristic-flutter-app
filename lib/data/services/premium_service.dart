import 'package:logger/logger.dart';
import '../models/premium.dart';
import 'api_service_impl.dart';

/// Service for handling premium features and subscriptions
class PremiumService {
  final ApiServiceImpl _apiService;
  final Logger _logger = Logger();

  PremiumService(this._apiService);

  /// Get available premium plans
  Future<List<PremiumPlan>> getAvailablePlans() async {
    try {
      final response = await _apiService.get('/api/premium/plans');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['plans'] ?? [];
        final plans = data.map((json) => PremiumPlan.fromJson(json)).toList();
        
        _logger.d('Retrieved ${plans.length} premium plans');
        return plans;
      } else {
        _logger.e('Failed to get premium plans: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting premium plans: $e');
      return [];
    }
  }

  /// Get current user's subscription status
  Future<UserSubscription?> getCurrentSubscription() async {
    try {
      final response = await _apiService.get('/api/premium/subscription');

      if (response.statusCode == 200 && response.data != null) {
        final subscription = UserSubscription.fromJson(response.data!);
        _logger.d('Retrieved current subscription: ${subscription.planId}');
        return subscription;
      } else if (response.statusCode == 404) {
        _logger.d('No active subscription found');
        return null;
      } else {
        _logger.e('Failed to get current subscription: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting current subscription: $e');
      return null;
    }
  }

  /// Subscribe to a premium plan
  Future<UserSubscription?> subscribeToPlan({
    required String planId,
    required String paymentMethodId,
    String? promoCode,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/premium/subscribe',
        data: {
          'planId': planId,
          'paymentMethodId': paymentMethodId,
          'promoCode': promoCode,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final subscription = UserSubscription.fromJson(response.data!);
        _logger.d('Successfully subscribed to plan: $planId');
        return subscription;
      } else {
        _logger.e('Failed to subscribe to plan: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error subscribing to plan: $e');
      return null;
    }
  }

  /// Cancel current subscription
  Future<bool> cancelSubscription({String? reason}) async {
    try {
      final response = await _apiService.post(
        '/api/premium/cancel',
        data: {
          'reason': reason,
          'cancelledAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Subscription cancelled successfully');
        return true;
      } else {
        _logger.e('Failed to cancel subscription: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Reactivate cancelled subscription
  Future<UserSubscription?> reactivateSubscription() async {
    try {
      final response = await _apiService.post('/api/premium/reactivate');

      if (response.statusCode == 200 && response.data != null) {
        final subscription = UserSubscription.fromJson(response.data!);
        _logger.d('Subscription reactivated successfully');
        return subscription;
      } else {
        _logger.e('Failed to reactivate subscription: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error reactivating subscription: $e');
      return null;
    }
  }

  /// Purchase premium coins
  Future<PurchaseResult?> purchaseCoins({
    required String coinPackageId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/premium/purchase-coins',
        data: {
          'coinPackageId': coinPackageId,
          'paymentMethodId': paymentMethodId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = PurchaseResult.fromJson(response.data!);
        _logger.d('Coins purchased successfully: ${result.amount}');
        return result;
      } else {
        _logger.e('Failed to purchase coins: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error purchasing coins: $e');
      return null;
    }
  }

  /// Get user's coin balance
  Future<CoinBalance?> getCoinBalance() async {
    try {
      final response = await _apiService.get('/api/premium/coins/balance');

      if (response.statusCode == 200 && response.data != null) {
        final balance = CoinBalance.fromJson(response.data!);
        _logger.d('Retrieved coin balance: ${balance.totalCoins}');
        return balance;
      } else {
        _logger.e('Failed to get coin balance: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting coin balance: $e');
      return null;
    }
  }

  /// Get coin transaction history
  Future<List<CoinTransaction>> getCoinTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/api/premium/coins/transactions',
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['transactions'] ?? [];
        final transactions = data.map((json) => CoinTransaction.fromJson(json)).toList();
        
        _logger.d('Retrieved ${transactions.length} coin transactions (page $page)');
        return transactions;
      } else {
        _logger.e('Failed to get coin transactions: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting coin transactions: $e');
      return [];
    }
  }

  /// Use premium feature (boost, super like, etc.)
  Future<bool> usePremiumFeature({
    required PremiumFeatureType featureType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _apiService.post(
        '/api/premium/use-feature',
        data: {
          'featureType': featureType.name,
          'parameters': parameters ?? {},
          'usedAt': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        _logger.d('Premium feature used: ${featureType.name}');
        return true;
      } else {
        _logger.e('Failed to use premium feature: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error using premium feature: $e');
      return false;
    }
  }

  /// Get available premium features for current subscription
  Future<List<PremiumFeature>> getAvailableFeatures() async {
    try {
      final response = await _apiService.get('/api/premium/features');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['features'] ?? [];
        final features = data.map((json) => PremiumFeature.fromJson(json)).toList();
        
        _logger.d('Retrieved ${features.length} premium features');
        return features;
      } else {
        _logger.e('Failed to get premium features: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting premium features: $e');
      return [];
    }
  }

  /// Get premium feature usage stats
  Future<Map<String, dynamic>?> getFeatureUsageStats() async {
    try {
      final response = await _apiService.get('/api/premium/usage-stats');

      if (response.statusCode == 200 && response.data != null) {
        final stats = {
          'boostsUsed': response.data['boostsUsed'] ?? 0,
          'superLikesUsed': response.data['superLikesUsed'] ?? 0,
          'rewindsUsed': response.data['rewindsUsed'] ?? 0,
          'readReceiptsUsed': response.data['readReceiptsUsed'] ?? 0,
          'unlimitedLikesUsed': response.data['unlimitedLikesUsed'] ?? 0,
          'boostsRemaining': response.data['boostsRemaining'] ?? 0,
          'superLikesRemaining': response.data['superLikesRemaining'] ?? 0,
          'rewindsRemaining': response.data['rewindsRemaining'] ?? 0,
          'currentPeriodStart': response.data['currentPeriodStart'],
          'currentPeriodEnd': response.data['currentPeriodEnd'],
        };
        
        _logger.d('Retrieved premium feature usage stats');
        return stats;
      } else {
        _logger.e('Failed to get feature usage stats: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting feature usage stats: $e');
      return null;
    }
  }

  /// Apply promo code
  Future<PromoCodeResult?> applyPromoCode(String promoCode) async {
    try {
      final response = await _apiService.post(
        '/api/premium/promo-code',
        data: {'promoCode': promoCode},
      );

      if (response.statusCode == 200 && response.data != null) {
        final result = PromoCodeResult.fromJson(response.data!);
        _logger.d('Promo code applied successfully: $promoCode');
        return result;
      } else {
        _logger.e('Failed to apply promo code: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error applying promo code: $e');
      return null;
    }
  }

  /// Get subscription history
  Future<List<UserSubscription>> getSubscriptionHistory() async {
    try {
      final response = await _apiService.get('/api/premium/subscription-history');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['subscriptions'] ?? [];
        final subscriptions = data.map((json) => UserSubscription.fromJson(json)).toList();
        
        _logger.d('Retrieved ${subscriptions.length} subscription records');
        return subscriptions;
      } else {
        _logger.e('Failed to get subscription history: ${response.statusMessage}');
        return [];
      }
    } catch (e) {
      _logger.e('Error getting subscription history: $e');
      return [];
    }
  }

  /// Update payment method
  Future<bool> updatePaymentMethod(String paymentMethodId) async {
    try {
      final response = await _apiService.put(
        '/api/premium/payment-method',
        data: {'paymentMethodId': paymentMethodId},
      );

      if (response.statusCode == 200) {
        _logger.d('Payment method updated successfully');
        return true;
      } else {
        _logger.e('Failed to update payment method: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error updating payment method: $e');
      return false;
    }
  }

  /// Get billing information
  Future<Map<String, dynamic>?> getBillingInfo() async {
    try {
      final response = await _apiService.get('/api/premium/billing-info');

      if (response.statusCode == 200 && response.data != null) {
        final billingInfo = {
          'nextBillingDate': response.data['nextBillingDate'],
          'billingAmount': response.data['billingAmount'],
          'currency': response.data['currency'] ?? 'USD',
          'paymentMethod': response.data['paymentMethod'],
          'billingAddress': response.data['billingAddress'],
          'taxAmount': response.data['taxAmount'],
          'totalAmount': response.data['totalAmount'],
        };
        
        _logger.d('Retrieved billing information');
        return billingInfo;
      } else {
        _logger.e('Failed to get billing info: ${response.statusMessage}');
        return null;
      }
    } catch (e) {
      _logger.e('Error getting billing info: $e');
      return null;
    }
  }

  /// Check if user has access to specific premium feature
  Future<bool> hasFeatureAccess(PremiumFeatureType featureType) async {
    try {
      final response = await _apiService.get('/api/premium/feature-access/${featureType.name}');

      if (response.statusCode == 200 && response.data != null) {
        final hasAccess = response.data['hasAccess'] as bool? ?? false;
        _logger.d('Feature access check for ${featureType.name}: $hasAccess');
        return hasAccess;
      } else {
        _logger.e('Failed to check feature access: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      _logger.e('Error checking feature access: $e');
      return false;
    }
  }
}
