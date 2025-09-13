import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logger/logger.dart';
import '../services/payment_service.dart';

/// Service for handling PeachPayments webhook notifications
class PaymentWebhookService {
  static PaymentWebhookService? _instance;
  static PaymentWebhookService get instance => _instance ??= PaymentWebhookService._();
  PaymentWebhookService._();
  
  // Logger instance
  final Logger _logger = Logger();
  
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
    // TODO: Implement local database update
    // This would typically update your local SQLite/Hive database
    _logger.i('Updating local payment record: $paymentId -> $status');
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
    // TODO: Implement feature unlocking logic
    _logger.i('Unlocking premium features for payment: $paymentId');
  }

  /// Revoke premium features for user
  Future<void> _revokePremiumFeatures(String paymentId) async {
    // TODO: Implement feature revocation logic
    _logger.i('Revoking premium features for payment: $paymentId');
  }

  /// Send payment confirmation
  Future<void> _sendPaymentConfirmation(String paymentId, String? amount, String? currency) async {
    // TODO: Implement confirmation sending via backend API
    _logger.i('Sending payment confirmation: $paymentId');
  }

  /// Send refund confirmation
  Future<void> _sendRefundConfirmation(String paymentId, String? amount) async {
    // TODO: Implement refund confirmation via backend API
    _logger.i('Sending refund confirmation: $paymentId');
  }

  /// Update subscription status
  Future<void> _updateSubscriptionStatus(String paymentId, {required bool active}) async {
    // TODO: Implement subscription status update
    _logger.i('Updating subscription status: $paymentId -> ${active ? 'active' : 'inactive'}');
  }

  /// Schedule retry notification for failed payments
  Future<void> _scheduleRetryNotification(String paymentId, String reason) async {
    // TODO: Implement retry notification scheduling
    _logger.i('Scheduling retry notification for: $paymentId');
  }

  /// Schedule status check for pending payments
  Future<void> _scheduleStatusCheck(String paymentId) async {
    // TODO: Implement status check scheduling
    _logger.i('Scheduling status check for: $paymentId');
  }

  /// Notify user about payment pending
  Future<void> _notifyPaymentPending(String paymentId) async {
    // TODO: Implement pending notification
    _logger.i('Notifying user of pending payment: $paymentId');
  }

  /// Send in-app notification to user about payment status
  Future<void> _notifyUser(String paymentId, PaymentStatus status, String? amount, String? currency) async {
    // TODO: Implement in-app notification system
    final statusText = status.name.toUpperCase();
    _logger.i('Notifying user: Payment $paymentId is $statusText');
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
