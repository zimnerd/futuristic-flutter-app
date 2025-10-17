import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import '../models/premium_plan.dart';
import '../models/subscription.dart';

/// Service for premium subscription API integration with NestJS backend
class PremiumApiService {
  static PremiumApiService? _instance;
  static PremiumApiService get instance => _instance ??= PremiumApiService._();
  PremiumApiService._();

  String? _authToken;

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Get available premium plans
  Future<List<PremiumPlan>> getAvailablePlans() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/plans'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['plans'] as List)
            .map((json) => PremiumPlan.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load premium plans: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching premium plans: $e');
      rethrow;
    }
  }

  /// Get user's current subscription
  Future<Subscription?> getCurrentSubscription(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/subscription/$userId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['subscription'] != null
            ? Subscription.fromJson(data['subscription'])
            : null;
      } else if (response.statusCode == 404) {
        return null; // No active subscription
      } else {
        throw Exception('Failed to load subscription: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/subscribe'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'planId': planId,
          'paymentMethodId': paymentMethodId,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Subscription.fromJson(data['subscription']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to subscribe to plan');
      }
    } catch (e) {
      AppLogger.error('Error subscribing to plan: $e');
      rethrow;
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/subscription/$subscriptionId/cancel'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel subscription');
      }
    } catch (e) {
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
      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/subscription/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (planId != null) 'planId': planId,
          if (metadata != null) 'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Subscription.fromJson(data['subscription']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update subscription');
      }
    } catch (e) {
      AppLogger.error('Error updating subscription: $e');
      rethrow;
    }
  }

  /// Get subscription history
  Future<List<Subscription>> getSubscriptionHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/subscription/$userId/history'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['subscriptions'] as List)
            .map((json) => Subscription.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load subscription history: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching subscription history: $e');
      rethrow;
    }
  }

  /// Get premium features
  Future<Map<String, dynamic>> getPremiumFeatures() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/features'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['features'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load premium features: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/boost'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'boostType': boostType,
          'quantity': quantity,
          'paymentMethodId': paymentMethodId,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to purchase boost');
      }
    } catch (e) {
      AppLogger.error('Error purchasing boost: $e');
      rethrow;
    }
  }

  /// Get boost credits
  Future<Map<String, int>> getBoostCredits(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/boost/$userId/credits'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Map<String, int>.from(data['credits']);
      } else {
        throw Exception('Failed to load boost credits: ${response.statusCode}');
      }
    } catch (e) {
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
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/boost/use'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'boostType': boostType,
          'targetData': targetData,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to use boost');
      }
    } catch (e) {
      AppLogger.error('Error using boost: $e');
      rethrow;
    }
  }

  /// Cancel active boost
  Future<Map<String, dynamic>> cancelBoost() async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.premium}/boost'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to cancel boost');
      }
    } catch (e) {
      AppLogger.error('Error canceling boost: $e');
      rethrow;
    }
  }
}
