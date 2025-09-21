import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../../core/utils/logger.dart';
import '../../core/config/app_config.dart';

/// PeachPayments API integration service
/// Documentation: https://developer.peachpayments.com/
class PeachPaymentsService {
  static PeachPaymentsService? _instance;
  static PeachPaymentsService get instance => _instance ??= PeachPaymentsService._();
  
  PeachPaymentsService._();

  // Logger instance
  final Logger _logger = Logger();

  // PeachPayments API configuration
  String get _baseUrl => AppConfig.peachPaymentsBaseUrl;
  static const String _checkoutEndpoint = '/v1/checkouts';
  static const String _paymentStatusEndpoint = '/v1/payments';
  
  // API credentials (should be from environment variables in production)
  late String _entityId;
  late String _accessToken;
  
  /// Initialize PeachPayments with credentials
  void initialize({
    required String entityId,
    required String accessToken,
  }) {
    _entityId = entityId;
    _accessToken = accessToken;
    
    AppLogger.info('PeachPayments initialized with entity: $entityId');
  }

  /// Create a checkout session for payment processing
  /// Returns checkout ID for frontend payment widget
  Future<Map<String, dynamic>> createCheckout({
    required double amount,
    required String currency,
    required String paymentType,
    String? merchantTransactionId,
    Map<String, dynamic>? customerData,
    Map<String, dynamic>? billingData,
    String? notificationUrl,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_checkoutEndpoint');
      
      // Prepare checkout data
      final checkoutData = {
        'entityId': _entityId,
        'amount': amount.toStringAsFixed(2),
        'currency': currency.toUpperCase(),
        'paymentType': paymentType, // 'DB' for debit, 'PA' for preauthorization
        if (merchantTransactionId != null) 'merchantTransactionId': merchantTransactionId,
        if (notificationUrl != null) 'notificationUrl': notificationUrl,
        'testMode': 'EXTERNAL', // Remove for production
      };

      // Add customer data if provided
      if (customerData != null) {
        customerData.forEach((key, value) {
          checkoutData['customer.$key'] = value.toString();
        });
      }

      // Add billing data if provided
      if (billingData != null) {
        billingData.forEach((key, value) {
          checkoutData['billing.$key'] = value.toString();
        });
      }

      AppLogger.info('Creating PeachPayments checkout: $checkoutData');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _buildFormData(checkoutData),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['result']['code'] == '000.200.100') {
        AppLogger.info('Checkout created successfully: ${responseData['id']}');
        return {
          'success': true,
          'checkoutId': responseData['id'],
          'redirectUrl': responseData['redirectUrl'],
          'buildNumber': responseData['buildNumber'],
          'timestamp': responseData['timestamp'],
        };
      } else {
        AppLogger.warning(
          'Failed to create checkout: ${responseData['result']['description']}',
        );
        return {
          'success': false,
          'error': responseData['result']['description'] ?? 'Unknown error',
          'code': responseData['result']['code'],
        };
      }
    } catch (e) {
      AppLogger.error('Error creating checkout: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get payment status by checkout/payment ID
  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final url = Uri.parse('$_baseUrl$_paymentStatusEndpoint/$paymentId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final result = responseData['result'];
        final code = result['code'] as String;
        
        // PeachPayments success codes
        final isSuccess = code.startsWith('000.000.') || 
                         code.startsWith('000.100.1') || 
                         code == '000.200.100';
        
        final isPending = code.startsWith('000.200.') || 
                         code.startsWith('800.400.5') ||
                         code == '000.000.100';
        
        final isFailure = !isSuccess && !isPending;

        _logger.i('Payment status retrieved: $code - ${result['description']}');

        return {
          'success': true,
          'paymentId': responseData['id'],
          'status': _mapPeachStatus(code),
          'amount': responseData['amount'],
          'currency': responseData['currency'],
          'timestamp': responseData['timestamp'],
          'result': result,
          'card': responseData['card'],
          'isSuccess': isSuccess,
          'isPending': isPending,
          'isFailure': isFailure,
        };
      } else {
        _logger.i('Failed to get payment status: $responseData');
        return {
          'success': false,
          'error': 'Failed to retrieve payment status',
        };
      }
    } catch (e) {
      _logger.e('Error getting payment status: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Create a recurring payment (for subscriptions)
  Future<Map<String, dynamic>> createRecurringPayment({
    required String registrationId,
    required double amount,
    required String currency,
    String? merchantTransactionId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_paymentStatusEndpoint');
      
      final paymentData = {
        'entityId': _entityId,
        'amount': amount.toStringAsFixed(2),
        'currency': currency.toUpperCase(),
        'paymentType': 'DB',
        'registrationId': registrationId,
        if (merchantTransactionId != null) 'merchantTransactionId': merchantTransactionId,
      };

      _logger.i('Creating recurring payment: $paymentData');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _buildFormData(paymentData),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final result = responseData['result'];
        final code = result['code'] as String;
        final isSuccess = code.startsWith('000.000.') || code.startsWith('000.100.1');

        _logger.i('Recurring payment result: $code - ${result['description']}');

        return {
          'success': isSuccess,
          'paymentId': responseData['id'],
          'status': _mapPeachStatus(code),
          'amount': responseData['amount'],
          'currency': responseData['currency'],
          'result': result,
        };
      } else {
        _logger.i('Failed to create recurring payment: $responseData');
        return {
          'success': false,
          'error': 'Failed to create recurring payment',
        };
      }
    } catch (e) {
      _logger.e('Error creating recurring payment: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Refund a payment
  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required double amount,
    required String currency,
    String? reason,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$_paymentStatusEndpoint');
      
      final refundData = {
        'entityId': _entityId,
        'amount': amount.toStringAsFixed(2),
        'currency': currency.toUpperCase(),
        'paymentType': 'RF',
        'referencedPaymentId': paymentId,
        if (reason != null) 'descriptor': reason,
      };

      _logger.i('Creating refund: $refundData');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: _buildFormData(refundData),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final result = responseData['result'];
        final code = result['code'] as String;
        final isSuccess = code.startsWith('000.000.') || code.startsWith('000.100.1');

        _logger.i('Refund result: $code - ${result['description']}');

        return {
          'success': isSuccess,
          'refundId': responseData['id'],
          'status': _mapPeachStatus(code),
          'amount': responseData['amount'],
          'currency': responseData['currency'],
          'result': result,
        };
      } else {
        _logger.i('Failed to create refund: $responseData');
        return {
          'success': false,
          'error': 'Failed to create refund',
        };
      }
    } catch (e) {
      _logger.e('Error creating refund: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  /// Get PeachPayments checkout script URL for frontend integration
  String getCheckoutScriptUrl() {
    return '$_baseUrl/v1/paymentWidgets.js?checkoutId=';
  }

  /// Map PeachPayments status codes to our internal status
  String _mapPeachStatus(String code) {
    if (code.startsWith('000.000.') || code.startsWith('000.100.1')) {
      return 'completed';
    } else if (code.startsWith('000.200.') || code.startsWith('800.400.5')) {
      return 'pending';
    } else if (code.startsWith('800.100.') || code.startsWith('800.120.')) {
      return 'failed';
    } else if (code.startsWith('000.400.0') || code.startsWith('000.400.1')) {
      return 'cancelled';
    } else {
      return 'failed';
    }
  }

  /// Build form-encoded data for API requests
  String _buildFormData(Map<String, dynamic> data) {
    return data.entries
        .map((entry) => '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');
  }

  /// Validate webhook notification from PeachPayments
  bool validateWebhookNotification(Map<String, dynamic> notification, String signature) {
    // Implement webhook signature validation based on PeachPayments documentation
    // This is crucial for security in production
    _logger.i('Validating webhook notification: ${notification['id']}');
    
    // For now, return true - implement proper validation in production
    return true;
  }

  /// Get supported payment brands for checkout widget
  List<String> getSupportedPaymentBrands() {
    return [
      'VISA',
      'MASTER',
      'AMEX',
      'DISCOVER',
      'PAYPAL',
      'APPLEPAY',
      'GOOGLEPAY',
    ];
  }

  /// Submit payment with card or external payment method
  Future<Map<String, dynamic>> submitPayment(Map<String, dynamic> paymentData) async {
    try {
      // For card payments, use the payments endpoint
      if (paymentData.containsKey('cardNumber')) {
        return await _submitCardPayment(paymentData);
      } else {
        // For external payment methods, redirect to external provider
        return await _submitExternalPayment(paymentData);
      }
    } catch (e) {
      _logger.e('Error submitting payment: $e');
      return {
        'success': false,
        'error': 'Payment submission failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> _submitCardPayment(Map<String, dynamic> paymentData) async {
    final url = Uri.parse('$_baseUrl$_paymentStatusEndpoint');
    
    final body = {
      'entityId': _entityId,
      'amount': paymentData['amount'] ?? '99.99',
      'currency': paymentData['currency'] ?? 'USD',
      'paymentBrand': _detectCardBrand(paymentData['cardNumber']),
      'paymentType': 'DB',
      'card.number': paymentData['cardNumber'],
      'card.holder': paymentData['cardHolder'],
      'card.expiryMonth': paymentData['expiryMonth'],
      'card.expiryYear': paymentData['expiryYear'],
      'card.cvv': paymentData['cvv'],
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: _buildFormData(body),
    );

    final result = json.decode(response.body);
    
    return {
      'success': response.statusCode == 200 && result['result']?['code']?.startsWith('000.'),
      'response': result,
      'transactionId': result['id'],
      'status': result['result']?['description'],
    };
  }

  Future<Map<String, dynamic>> _submitExternalPayment(Map<String, dynamic> paymentData) async {
    // For external payments, return a redirect URL
    final paymentMethod = paymentData['paymentMethod'];
    final checkoutId = paymentData['checkoutId'];
    
    // Simulate external payment redirect
    return {
      'success': true,
      'redirectUrl': '$_baseUrl/external-payment/$paymentMethod/$checkoutId',
      'requiresRedirect': true,
      'paymentMethod': paymentMethod,
    };
  }

  String _detectCardBrand(String cardNumber) {
    final cleanCard = cardNumber.replaceAll(' ', '');
    if (cleanCard.startsWith('4')) return 'VISA';
    if (cleanCard.startsWith('5')) return 'MASTER';
    if (cleanCard.startsWith('3')) return 'AMEX';
    return 'VISA'; // Default
  }

  /// Create test payment data for development
  Map<String, dynamic> getTestPaymentData() {
    return {
      'card.number': '4200000000000000',
      'card.expiryMonth': '05',
      'card.expiryYear': '2034',
      'card.cvv': '123',
      'card.holder': 'Jane Jones',
    };
  }

  /// Tokenize payment method for secure storage
  /// Returns token that can be used for future payments
  Future<Map<String, dynamic>> tokenizePaymentMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cardholderName,
    String? cvv,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/registrations');

      final tokenData = {
        'entityId': _entityId,
        'paymentBrand': _detectCardBrand(cardNumber),
        'card.number': cardNumber,
        'card.holder': cardholderName,
        'card.expiryMonth': expiryMonth,
        'card.expiryYear': expiryYear,
        if (cvv != null) 'card.cvv': cvv,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: tokenData.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
            )
            .join('&'),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = responseData['result'];
        final code = result['code'] as String;

        // Check if tokenization was successful
        if (code.startsWith('000.000.') || code.startsWith('000.100.1')) {
          return {
            'success': true,
            'token': responseData['id'],
            'brand': responseData['paymentBrand'],
            'last4': cardNumber.substring(cardNumber.length - 4),
            'expiryMonth': expiryMonth,
            'expiryYear': expiryYear,
          };
        } else {
          return {
            'success': false,
            'error': result['description'] ?? 'Tokenization failed',
            'code': code,
          };
        }
      } else {
        return {
          'success': false,
          'error':
              'HTTP ${response.statusCode}: ${responseData['error'] ?? 'Unknown error'}',
          'code': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      _logger.e('Error tokenizing payment method: $e');
      return {
        'success': false,
        'error': 'Tokenization failed: $e',
        'code': 'TOKENIZATION_ERROR',
      };
    }
  }

  /// Process payment using stored token
  Future<Map<String, dynamic>> processTokenPayment({
    required String token,
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/v1/payments');

      final paymentData = {
        'entityId': _entityId,
        'amount': amount.toStringAsFixed(2),
        'currency': currency,
        'paymentType': 'DB', // Debit payment
        'registrationId': token,
        if (description != null) 'merchantTransactionId': description,
        if (metadata != null)
          ...metadata.map(
            (key, value) =>
                MapEntry('customParameters[$key]', value.toString()),
          ),
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: paymentData.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}',
            )
            .join('&'),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = responseData['result'];
        final code = result['code'] as String;

        // Check if payment was successful
        if (code.startsWith('000.000.') || code.startsWith('000.100.1')) {
          return {
            'success': true,
            'payment_id': responseData['id'],
            'amount': responseData['amount'],
            'currency': responseData['currency'],
            'status': 'succeeded',
            'result_code': code,
            'descriptor': responseData['descriptor'],
          };
        } else {
          return {
            'success': false,
            'error': result['description'] ?? 'Payment failed',
            'code': code,
            'payment_id': responseData['id'],
          };
        }
      } else {
        return {
          'success': false,
          'error':
              'HTTP ${response.statusCode}: ${responseData['error'] ?? 'Unknown error'}',
          'code': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      _logger.e('Error processing token payment: $e');
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
        'code': 'PAYMENT_ERROR',
      };
    }
  }
}
