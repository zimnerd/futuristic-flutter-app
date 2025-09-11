import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';

/// Payment methods enum
enum PaymentMethod {
  creditCard,
  debitCard,
  applePay,
  googlePay,
  paypal,
  stripe,
}

/// Payment status enum
enum PaymentStatus {
  pending,
  processing,
  succeeded,
  failed,
  cancelled,
  refunded,
}

/// Payment service for handling transactions
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  PaymentService._();

  String? _authToken;

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Create payment method
  Future<Map<String, dynamic>> createPaymentMethod({
    required PaymentMethod type,
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/methods'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'type': type.name,
          'paymentData': paymentData,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['paymentMethod'] as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw PaymentException(errorData['message'] ?? 'Failed to create payment method');
      }
    } catch (e) {
      AppLogger.error('Error creating payment method: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to create payment method: $e');
    }
  }

  /// Get user payment methods
  Future<List<Map<String, dynamic>>> getUserPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/methods'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['paymentMethods'] as List).cast<Map<String, dynamic>>();
      } else {
        throw PaymentException('Failed to load payment methods: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching payment methods: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to load payment methods: $e');
    }
  }

  /// Process payment for subscription
  Future<Map<String, dynamic>> processSubscriptionPayment({
    required String planId,
    required String paymentMethodId,
    String? promoCode,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/subscription'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'planId': planId,
          'paymentMethodId': paymentMethodId,
          'promoCode': promoCode,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw PaymentException(errorData['message'] ?? 'Payment failed');
      }
    } catch (e) {
      AppLogger.error('Error processing subscription payment: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Payment processing failed: $e');
    }
  }

  /// Process one-time payment (for boosts, etc.)
  Future<Map<String, dynamic>> processOneTimePayment({
    required double amount,
    required String currency,
    required String paymentMethodId,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/one-time'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'paymentMethodId': paymentMethodId,
          'description': description,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } else {
        final errorData = json.decode(response.body);
        throw PaymentException(errorData['message'] ?? 'Payment failed');
      }
    } catch (e) {
      AppLogger.error('Error processing one-time payment: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Payment processing failed: $e');
    }
  }

  /// Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/history')
            .replace(queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        }),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['payments'] as List).cast<Map<String, dynamic>>();
      } else {
        throw PaymentException('Failed to load payment history: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching payment history: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to load payment history: $e');
    }
  }

  /// Validate promo code
  Future<Map<String, dynamic>?> validatePromoCode(String promoCode) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/promo/validate'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'promoCode': promoCode}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['promoCode'] as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null; // Invalid promo code
      } else {
        throw PaymentException('Failed to validate promo code: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error validating promo code: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to validate promo code: $e');
    }
  }

  /// Request refund
  Future<void> requestRefund({
    required String paymentId,
    String? reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/refund'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentId': paymentId,
          'reason': reason,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw PaymentException(errorData['message'] ?? 'Failed to request refund');
      }
    } catch (e) {
      AppLogger.error('Error requesting refund: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to request refund: $e');
    }
  }

  /// Delete payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/methods/$paymentMethodId'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw PaymentException(errorData['message'] ?? 'Failed to delete payment method');
      }
    } catch (e) {
      AppLogger.error('Error deleting payment method: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to delete payment method: $e');
    }
  }
}

/// Custom exception for payment-related errors
class PaymentException implements Exception {
  final String message;
  
  const PaymentException(this.message);
  
  @override
  String toString() => 'PaymentException: $message';
}
