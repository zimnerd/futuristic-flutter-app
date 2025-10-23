import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';
import '../models/premium_plan.dart';
import '../models/subscription.dart';

/// Service for premium subscription API integration with NestJS backend
class PremiumApiService {
  static PremiumApiService? _instance;
  static PremiumApiService get instance => _instance ??= PremiumApiService._();
  PremiumApiService._();

  final ApiClient _apiClient = ApiClient.instance;

  /// Set authentication token
  void setAuthToken(String token) {
    // ApiClient handles authentication internally
  }

  /// Get available premium plans
  Future<List<PremiumPlan>> getAvailablePlans() async {
    try {
      final response = await _apiClient.get('${ApiConstants.premium}/plans');

      final data = response.data as Map<String, dynamic>;
      return (data['plans'] as List)
          .map((json) => PremiumPlan.fromJson(json))
          .toList();
    } on DioException catch (e) {
      AppLogger.error('Error fetching premium plans: $e');
      rethrow;
    }
  }

  /// Get user's current subscription
  Future<Subscription?> getCurrentSubscription(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.premium}/subscription/$userId',
      );

      final data = response.data as Map<String, dynamic>;
      return data['subscription'] != null
          ? Subscription.fromJson(data['subscription'])
          : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No active subscription
      }
      AppLogger.error('Error fetching current subscription: $e');
      rethrow;
    }
  }

  /// Subscribe to premium plan
  Future<Subscription> subscribeToPlan({
    required String planId,
    required String paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.premium}/subscribe',
        data: {
          'planId': planId,
          'paymentMethodId': paymentMethodId,
          'metadata': metadata,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return Subscription.fromJson(data['subscription']);
    } on DioException catch (e) {
      AppLogger.error('Error subscribing to plan: $e');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await _apiClient.patch(
        '${ApiConstants.premium}/subscription/$subscriptionId/cancel',
      );
    } on DioException catch (e) {
      AppLogger.error('Error cancelling subscription: $e');
      rethrow;
    }
  }

  /// Update subscription
  Future<Subscription> updateSubscription({
    required String subscriptionId,
    String? planId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConstants.premium}/subscription/$subscriptionId',
        data: {
          if (planId != null) 'planId': planId,
          if (metadata != null) 'metadata': metadata,
        },
      );

      final data = response.data as Map<String, dynamic>;
      return Subscription.fromJson(data['subscription']);
    } on DioException catch (e) {
      AppLogger.error('Error updating subscription: $e');
      rethrow;
    }
  }

  /// Get subscription history
  Future<List<Subscription>> getSubscriptionHistory(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.premium}/subscription/$userId/history',
      );

      final data = response.data as Map<String, dynamic>;
      return (data['subscriptions'] as List)
          .map((json) => Subscription.fromJson(json))
          .toList();
    } on DioException catch (e) {
      AppLogger.error('Error fetching subscription history: $e');
      rethrow;
    }
  }

  /// Get premium features
  Future<Map<String, dynamic>> getPremiumFeatures() async {
    try {
      final response = await _apiClient.get('${ApiConstants.premium}/features');

      final data = response.data as Map<String, dynamic>;
      return data['features'] as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.error('Error fetching premium features: $e');
      rethrow;
    }
  }

  /// Purchase boost
  Future<Map<String, dynamic>> purchaseBoost({
    required String boostType,
    required int quantity,
    required String paymentMethodId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.premium}/boost',
        data: {
          'boostType': boostType,
          'quantity': quantity,
          'paymentMethodId': paymentMethodId,
        },
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.error('Error purchasing boost: $e');
      rethrow;
    }
  }

  /// Get boost credits
  Future<Map<String, int>> getBoostCredits(String userId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConstants.premium}/boost/$userId/credits',
      );

      final data = response.data as Map<String, dynamic>;
      return Map<String, int>.from(data['credits']);
    } on DioException catch (e) {
      AppLogger.error('Error fetching boost credits: $e');
      rethrow;
    }
  }

  /// Use boost
  Future<void> useBoost({
    required String boostType,
    Map<String, dynamic>? targetData,
  }) async {
    try {
      await _apiClient.post(
        '${ApiConstants.premium}/boost/use',
        data: {'boostType': boostType, 'targetData': targetData,
        },
      );
    } on DioException catch (e) {
      AppLogger.error('Error using boost: $e');
      rethrow;
    }
  }

  /// Cancel active boost
  Future<Map<String, dynamic>> cancelBoost() async {
    try {
      final response = await _apiClient.delete('${ApiConstants.premium}/boost');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      AppLogger.error('Error canceling boost: $e');
      rethrow;
    }
  }
}
