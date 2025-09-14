import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../services/payment_service.dart';
import 'api_service_impl.dart';
import '../../domain/services/api_service.dart';

/// Service for handling PeachPayments webhook notifications
class PaymentWebhookService {
  static PaymentWebhookService? _instance;
  static PaymentWebhookService get instance => _instance ??= PaymentWebhookService._();
  PaymentWebhookService._();
  
  // Logger instance
  final Logger _logger = Logger();
  final ApiService _apiService = ApiServiceImpl();
  
  /// Process incoming webhook notification from PeachPayments
  Future<Map<String, dynamic>> processWebhook({
    required Map<String, dynamic> payload,
    required String signature,
    required String webhookSecret,
  }) async {
    try {
      // Validate webhook signature for security
      if (!_validateSignature(payload, signature, webhookSecret)) {
        return {
          'success': false,
          'error': 'Invalid webhook signature',
          'code': 'INVALID_SIGNATURE',
        };
      }

      // Extract payment information
      final paymentId = payload['id'] as String?;
      final paymentType = payload['paymentType'] as String?;
      final resultCode = payload['result']?['code'] as String?;
      final amount = payload['amount'] as String?;
      final currency = payload['currency'] as String?;
      
      if (paymentId == null || resultCode == null) {
        return {
          'success': false,
          'error': 'Missing required webhook data',
          'code': 'INVALID_PAYLOAD',
        };
      }

      // Determine payment status from result code
      final status = _mapResultCodeToStatus(resultCode);
      
      // Process based on payment status
      final result = await _processPaymentUpdate(
        paymentId: paymentId,
        status: status,
        resultCode: resultCode,
        amount: amount,
        currency: currency,
        paymentType: paymentType,
        fullPayload: payload,
      );

      return {
        'success': true,
        'paymentId': paymentId,
        'status': status,
        'processed': result,
      };
    } catch (e) {
      _logger.e('Error processing webhook: $e');
      return {
        'success': false,
        'error': 'Webhook processing failed: $e',
        'code': 'PROCESSING_ERROR',
      };
    }
  }

  /// Validate webhook signature to ensure authenticity
  bool _validateSignature(Map<String, dynamic> payload, String signature, String secret) {
    try {
      // Create payload string for signature verification
      final payloadString = json.encode(payload);
      
      // Generate expected signature using HMAC-SHA256
      final key = utf8.encode(secret);
      final bytes = utf8.encode(payloadString);
      final hmacSha256 = Hmac(sha256, key);
      final digest = hmacSha256.convert(bytes);
      final expectedSignature = 'sha256=${digest.toString()}';
      
      // Compare signatures securely
      return _secureCompare(signature, expectedSignature);
    } catch (e) {
      _logger.e('Error validating webhook signature: $e');
      return false;
    }
  }

  /// Secure string comparison to prevent timing attacks
  bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;
    
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    
    return result == 0;
  }

  /// Map PeachPayments result codes to our internal status enum
  PaymentStatus _mapResultCodeToStatus(String resultCode) {
    // Success codes
    if (resultCode.startsWith('000.000.') || resultCode.startsWith('000.100.1')) {
      return PaymentStatus.succeeded;
    }
    
    // Pending codes
    if (resultCode.startsWith('000.200.') || resultCode.startsWith('800.400.5')) {
      return PaymentStatus.pending;
    }
    
    // Rejection codes
    if (resultCode.startsWith('100.') || resultCode.startsWith('800.100.')) {
      return PaymentStatus.failed;
    }
    
    // Refund codes
    if (resultCode.startsWith('000.000.') && resultCode.contains('refund')) {
      return PaymentStatus.refunded;
    }
    
    // Default to failed for unknown codes
    return PaymentStatus.failed;
  }

  /// Process payment status update based on webhook data
  Future<bool> _processPaymentUpdate({
    required String paymentId,
    required PaymentStatus status,
    required String resultCode,
    String? amount,
    String? currency,
    String? paymentType,
    required Map<String, dynamic> fullPayload,
  }) async {
    try {
      // Update local payment record
      await _updateLocalPaymentRecord(
        paymentId: paymentId,
        status: status,
        resultCode: resultCode,
        amount: amount,
        currency: currency,
        metadata: fullPayload,
      );

      // Handle different payment statuses
      switch (status) {
        case PaymentStatus.succeeded:
          await _handleSuccessfulPayment(paymentId, amount, currency, fullPayload);
          break;
        case PaymentStatus.failed:
          await _handleFailedPayment(paymentId, resultCode, fullPayload);
          break;
        case PaymentStatus.pending:
          await _handlePendingPayment(paymentId, fullPayload);
          break;
        case PaymentStatus.refunded:
          await _handleRefundedPayment(paymentId, amount, fullPayload);
          break;
        default:
          _logger.i('Unknown payment status: $status');
      }

      // Send notification to user if app is active
      await _notifyUser(paymentId, status, amount, currency);

      return true;
    } catch (e) {
      _logger.e('Error processing payment update for $paymentId: $e');
      return false;
    }
  }

  /// Update local payment record with webhook data
  Future<void> _updateLocalPaymentRecord({
    required String paymentId,
    required PaymentStatus status,
    required String resultCode,
    String? amount,
    String? currency,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Update payment record via API (which would typically update local cache)
      await _apiService.patch('/api/payments/$paymentId', data: {
        'status': status.name,
        'resultCode': resultCode,
        'amount': amount,
        'currency': currency,
        'metadata': metadata,
      });
      _logger.i('Updated local payment record: $paymentId -> $status');
    } catch (e) {
      _logger.e('Failed to update local payment record: $e');
    }
  }

  /// Handle successful payment completion
  Future<void> _handleSuccessfulPayment(
    String paymentId,
    String? amount,
    String? currency,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Unlock premium features
      await _unlockPremiumFeatures(paymentId);
      
      // Send confirmation email (via backend)
      await _sendPaymentConfirmation(paymentId, amount, currency);
      
      // Update subscription status if applicable
      await _updateSubscriptionStatus(paymentId, active: true);
      
      _logger.i('Successfully processed payment completion: $paymentId');
    } catch (e) {
      _logger.e('Error handling successful payment $paymentId: $e');
    }
  }

  /// Handle failed payment
  Future<void> _handleFailedPayment(
    String paymentId,
    String resultCode,
    Map<String, dynamic> payload,
  ) async {
    try {
      // Log failure reason
      final failureReason = payload['result']?['description'] ?? 'Unknown error';
      _logger.i('Payment failed: $paymentId - $failureReason ($resultCode)');
      
      // Notify user of failure and suggest retry
      await _scheduleRetryNotification(paymentId, failureReason);
      
      // Update subscription status if applicable
      await _updateSubscriptionStatus(paymentId, active: false);
    } catch (e) {
      _logger.e('Error handling failed payment $paymentId: $e');
    }
  }

  /// Handle pending payment
  Future<void> _handlePendingPayment(
    String paymentId,
    Map<String, dynamic> payload,
  ) async {
    try {
      _logger.i('Payment pending: $paymentId');
      
      // Schedule status check for later
      await _scheduleStatusCheck(paymentId);
      
      // Notify user that payment is being processed
      await _notifyPaymentPending(paymentId);
    } catch (e) {
      _logger.e('Error handling pending payment $paymentId: $e');
    }
  }

  /// Handle refunded payment
  Future<void> _handleRefundedPayment(
    String paymentId,
    String? amount,
    Map<String, dynamic> payload,
  ) async {
    try {
      _logger.i('Payment refunded: $paymentId - $amount');
      
      // Revoke premium features if applicable
      await _revokePremiumFeatures(paymentId);
      
      // Update subscription status
      await _updateSubscriptionStatus(paymentId, active: false);
      
      // Send refund confirmation
      await _sendRefundConfirmation(paymentId, amount);
    } catch (e) {
      _logger.e('Error handling refunded payment $paymentId: $e');
    }
  }

  /// Unlock premium features for user
  Future<void> _unlockPremiumFeatures(String paymentId) async {
    try {
      await _apiService.post('/api/payments/$paymentId/unlock-features');
      _logger.i('Unlocked premium features for payment: $paymentId');
    } catch (e) {
      _logger.e('Failed to unlock premium features: $e');
    }
  }

  /// Revoke premium features for user
  Future<void> _revokePremiumFeatures(String paymentId) async {
    try {
      await _apiService.post('/api/payments/$paymentId/revoke-features');
      _logger.i('Revoked premium features for payment: $paymentId');
    } catch (e) {
      _logger.e('Failed to revoke premium features: $e');
    }
  }

  /// Send payment confirmation
  Future<void> _sendPaymentConfirmation(String paymentId, String? amount, String? currency) async {
    try {
      await _apiService.post('/api/payments/$paymentId/send-confirmation', data: {
        'amount': amount,
        'currency': currency,
      });
      _logger.i('Sent payment confirmation: $paymentId');
    } catch (e) {
      _logger.e('Failed to send payment confirmation: $e');
    }
  }

  /// Send refund confirmation
  Future<void> _sendRefundConfirmation(String paymentId, String? amount) async {
    try {
      await _apiService.post('/api/payments/$paymentId/send-refund-confirmation', data: {
        'amount': amount,
      });
      _logger.i('Sent refund confirmation: $paymentId');
    } catch (e) {
      _logger.e('Failed to send refund confirmation: $e');
    }
  }

  /// Update subscription status
  Future<void> _updateSubscriptionStatus(String paymentId, {required bool active}) async {
    try {
      await _apiService.patch('/api/subscriptions/payment/$paymentId', data: {
        'active': active,
      });
      _logger.i('Updated subscription status: $paymentId -> ${active ? 'active' : 'inactive'}');
    } catch (e) {
      _logger.e('Failed to update subscription status: $e');
    }
  }

  /// Schedule retry notification for failed payments
  Future<void> _scheduleRetryNotification(String paymentId, String reason) async {
    try {
      await _apiService.post('/api/payments/$paymentId/schedule-retry', data: {
        'reason': reason,
      });
      _logger.i('Scheduled retry notification for: $paymentId');
    } catch (e) {
      _logger.e('Failed to schedule retry notification: $e');
    }
  }

  /// Schedule status check for pending payments
  Future<void> _scheduleStatusCheck(String paymentId) async {
    try {
      await _apiService.post('/api/payments/$paymentId/schedule-check');
      _logger.i('Scheduled status check for: $paymentId');
    } catch (e) {
      _logger.e('Failed to schedule status check: $e');
    }
  }

  /// Notify user about payment pending
  Future<void> _notifyPaymentPending(String paymentId) async {
    try {
      await _apiService.post('/api/notifications/payment-pending', data: {
        'paymentId': paymentId,
      });
      _logger.i('Notified user of pending payment: $paymentId');
    } catch (e) {
      _logger.e('Failed to notify user about pending payment: $e');
    }
  }

  /// Send in-app notification to user about payment status
  Future<void> _notifyUser(String paymentId, PaymentStatus status, String? amount, String? currency) async {
    try {
      await _apiService.post('/api/notifications/payment-status', data: {
        'paymentId': paymentId,
        'status': status.name,
        'amount': amount,
        'currency': currency,
      });
      final statusText = status.name.toUpperCase();
      _logger.i('Notified user: Payment $paymentId is $statusText');
    } catch (e) {
      _logger.e('Failed to notify user about payment status: $e');
    }
  }

  /// Get webhook endpoint URL for PeachPayments configuration
  String getWebhookEndpointUrl(String baseUrl) {
    return '$baseUrl/api/webhooks/peachpayments';
  }

  /// Validate webhook payload structure
  bool isValidWebhookPayload(Map<String, dynamic> payload) {
    final requiredFields = ['id', 'result', 'paymentType'];
    
    for (final field in requiredFields) {
      if (!payload.containsKey(field)) {
        _logger.i('Missing required webhook field: $field');
        return false;
      }
    }
    
    return true;
  }
}
