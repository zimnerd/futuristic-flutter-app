import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/logger.dart';
import 'peach_payments_service.dart';

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
  final PeachPaymentsService _peachPayments = PeachPaymentsService.instance;
  String get _baseUrl => ApiConstants.baseUrl;

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Initialize PeachPayments with credentials
  void initializePeachPayments({
    required String entityId,
    required String accessToken,
  }) {
    _peachPayments.initialize(
      entityId: entityId,
      accessToken: accessToken,
    );
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

  // PEACH PAYMENTS INTEGRATION METHODS

  /// Create PeachPayments checkout for card payment
  Future<Map<String, dynamic>> createPeachCheckout({
    required double amount,
    required String currency,
    required String paymentType,
    String? merchantTransactionId,
    Map<String, dynamic>? customerData,
    Map<String, dynamic>? billingData,
  }) async {
    try {
      final result = await _peachPayments.createCheckout(
        amount: amount,
        currency: currency,
        paymentType: paymentType,
        merchantTransactionId: merchantTransactionId,
        customerData: customerData,
        billingData: billingData,
        notificationUrl: '${ApiConstants.baseUrl}${ApiConstants.payment}/webhook/peach',
      );

      if (result['success'] == true) {
        // Store checkout information in backend
        await _storeCheckoutSession(result['checkoutId'], merchantTransactionId);
        return result;
      } else {
        throw PaymentException(result['error'] ?? 'Failed to create checkout');
      }
    } catch (e) {
      AppLogger.error('Error creating PeachPayments checkout: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to create payment checkout: $e');
    }
  }

  /// Check PeachPayments payment status
  Future<Map<String, dynamic>> checkPeachPaymentStatus(String paymentId) async {
    try {
      final result = await _peachPayments.getPaymentStatus(paymentId);
      
      if (result['success'] == true) {
        // Update payment status in backend
        await _updatePaymentStatus(paymentId, result);
        return result;
      } else {
        throw PaymentException(result['error'] ?? 'Failed to check payment status');
      }
    } catch (e) {
      AppLogger.error('Error checking payment status: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to check payment status: $e');
    }
  }

  /// Process recurring payment via PeachPayments
  Future<Map<String, dynamic>> processRecurringPayment({
    required String registrationId,
    required double amount,
    required String currency,
    String? merchantTransactionId,
  }) async {
    try {
      final result = await _peachPayments.createRecurringPayment(
        registrationId: registrationId,
        amount: amount,
        currency: currency,
        merchantTransactionId: merchantTransactionId,
      );

      if (result['success'] == true) {
        // Update backend with recurring payment result
        await _updateRecurringPayment(result);
        return result;
      } else {
        throw PaymentException(result['error'] ?? 'Recurring payment failed');
      }
    } catch (e) {
      AppLogger.error('Error processing recurring payment: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to process recurring payment: $e');
    }
  }

  /// Request refund via PeachPayments
  Future<Map<String, dynamic>> processRefundWithPeach({
    required String paymentId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    try {
      final result = await _peachPayments.refundPayment(
        paymentId: paymentId,
        amount: amount,
        currency: currency,
        reason: reason,
      );

      if (result['success'] == true) {
        // Update refund status in backend
        await _updateRefundStatus(result);
        return result;
      } else {
        throw PaymentException(result['error'] ?? 'Refund failed');
      }
    } catch (e) {
      AppLogger.error('Error processing refund: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to process refund: $e');
    }
  }

  /// Submit payment using PeachPayments API
  Future<Map<String, dynamic>> submitPeachPayment(Map<String, dynamic> paymentData) async {
    try {
      final result = await _peachPayments.submitPayment(paymentData);
      
      // Sync with backend
      await _syncPaymentWithBackend(result);
      
      return result;
    } catch (e) {
      AppLogger.error('Error submitting PeachPayments payment: $e');
      throw Exception('Failed to process payment: $e');
    }
  }

  /// Get PeachPayments checkout script URL
  String getPeachCheckoutScriptUrl() {
    return _peachPayments.getCheckoutScriptUrl();
  }

  /// Sync payment result with backend (public method)
  Future<void> syncPaymentWithBackend(Map<String, dynamic> paymentData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/sync'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(paymentData),
      );

      if (response.statusCode != 200) {
        throw PaymentException(
          'Failed to sync payment with backend: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error('Error syncing payment with backend: $e');
      if (e is PaymentException) rethrow;
      throw PaymentException('Failed to sync payment: $e');
    }
  }

  /// Sync payment result with backend
  Future<void> _syncPaymentWithBackend(Map<String, dynamic> paymentResult) async {
    try {
      if (paymentResult['success'] == true && paymentResult['transactionId'] != null) {
        // Send payment confirmation to backend
        final url = Uri.parse('$_baseUrl/payments/confirm');
        
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (_authToken != null) 'Authorization': 'Bearer $_authToken',
          },
          body: json.encode({
            'transactionId': paymentResult['transactionId'],
            'status': paymentResult['status'],
            'provider': 'peachpayments',
            'response': paymentResult['response'],
          }),
        );

        if (response.statusCode != 200) {
          AppLogger.warning(
            'Failed to sync payment with backend: ${response.body}',
          );
        }
      }
    } catch (e) {
      AppLogger.error('Error syncing payment with backend: $e');
      // Don't throw error as payment was successful, just log the sync failure
    }
  }

  /// Get supported payment brands for PeachPayments
  List<String> getSupportedPaymentBrands() {
    return _peachPayments.getSupportedPaymentBrands();
  }

  // HELPER METHODS

  /// Store checkout session in backend
  Future<void> _storeCheckoutSession(String checkoutId, String? transactionId) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/checkout/store'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'checkoutId': checkoutId,
          'transactionId': transactionId,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      AppLogger.error('Error storing checkout session: $e');
      // Non-critical error, don't throw
    }
  }

  /// Update payment status in backend
  Future<void> _updatePaymentStatus(String paymentId, Map<String, dynamic> result) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/status/update'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentId': paymentId,
          'status': result['status'],
          'isSuccess': result['isSuccess'],
          'amount': result['amount'],
          'currency': result['currency'],
          'timestamp': result['timestamp'],
          'peachResult': result['result'],
        }),
      );
    } catch (e) {
      AppLogger.error('Error updating payment status: $e');
      // Non-critical error, don't throw
    }
  }

  /// Update recurring payment in backend
  Future<void> _updateRecurringPayment(Map<String, dynamic> result) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/recurring/update'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentId': result['paymentId'],
          'status': result['status'],
          'amount': result['amount'],
          'currency': result['currency'],
          'result': result['result'],
        }),
      );
    } catch (e) {
      AppLogger.error('Error updating recurring payment: $e');
      // Non-critical error, don't throw
    }
  }

  /// Update refund status in backend
  Future<void> _updateRefundStatus(Map<String, dynamic> result) async {
    try {
      await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.payment}/refund/update'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'refundId': result['refundId'],
          'status': result['status'],
          'amount': result['amount'],
          'currency': result['currency'],
          'result': result['result'],
        }),
      );
    } catch (e) {
      AppLogger.error('Error updating refund status: $e');
      // Non-critical error, don't throw
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
