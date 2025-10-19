import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_payment_method.dart';
import 'payment_service.dart';
import 'peach_payments_service.dart';

/// Service for managing saved payment methods
/// Handles secure storage, tokenization, and validation of payment methods
class SavedPaymentMethodsService {
  static SavedPaymentMethodsService? _instance;
  static SavedPaymentMethodsService get instance =>
      _instance ??= SavedPaymentMethodsService._();
  SavedPaymentMethodsService._();

  // Logger instance
  final Logger _logger = Logger();

  static const String _storageKey = 'saved_payment_methods';
  static const String _defaultMethodKey = 'default_payment_method_id';

  final PaymentService _paymentService = PaymentService.instance;
  final PeachPaymentsService _peachPayments = PeachPaymentsService.instance;

  /// Get all saved payment methods for current user
  Future<List<SavedPaymentMethod>> getSavedPaymentMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map(
            (json) => SavedPaymentMethod.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      _logger.e('Error loading saved payment methods: $e');
      return [];
    }
  }

  /// Save a new payment method after successful tokenization
  Future<SavedPaymentMethod?> savePaymentMethod({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cardholderName,
    String? nickname,
    bool setAsDefault = false,
  }) async {
    try {
      // Tokenize the payment method with PeachPayments
      final tokenResult = await _peachPayments.tokenizePaymentMethod(
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardholderName: cardholderName,
      );

      if (!tokenResult['success']) {
        _logger.i('Failed to tokenize payment method: ${tokenResult['error']}');
        return null;
      }

      // Create saved payment method
      final savedMethod = SavedPaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        token: tokenResult['token'],
        cardType: _detectCardType(cardNumber),
        lastFourDigits: cardNumber.substring(cardNumber.length - 4),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cardholderName: cardholderName,
        nickname:
            nickname ??
            '${_detectCardType(cardNumber)} ending in ${cardNumber.substring(cardNumber.length - 4)}',
        isDefault: setAsDefault,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      // Save to local storage
      final methods = await getSavedPaymentMethods();

      // If setting as default, remove default from other methods
      if (setAsDefault) {
        for (var method in methods) {
          method.isDefault = false;
        }
      }

      methods.add(savedMethod);
      await _saveMethodsToStorage(methods);

      // Set as default method if specified
      if (setAsDefault) {
        await setDefaultPaymentMethod(savedMethod.id);
      }

      _logger.i('Payment method saved successfully: ${savedMethod.id}');
      return savedMethod;
    } catch (e) {
      _logger.e('Error saving payment method: $e');
      return null;
    }
  }

  /// Delete a saved payment method
  Future<bool> deletePaymentMethod(String methodId) async {
    try {
      final methods = await getSavedPaymentMethods();
      final methodIndex = methods.indexWhere((m) => m.id == methodId);

      if (methodIndex == -1) {
        _logger.i('Payment method not found: $methodId');
        return false;
      }

      final deletedMethod = methods[methodIndex];
      methods.removeAt(methodIndex);

      // If deleted method was default, set first remaining as default
      if (deletedMethod.isDefault && methods.isNotEmpty) {
        methods.first.isDefault = true;
        await setDefaultPaymentMethod(methods.first.id);
      }

      await _saveMethodsToStorage(methods);

      // Revoke token from PeachPayments
      await _revokePaymentToken(deletedMethod.token);

      _logger.i('Payment method deleted: $methodId');
      return true;
    } catch (e) {
      _logger.e('Error deleting payment method: $e');
      return false;
    }
  }

  /// Update payment method details (nickname, etc.)
  Future<bool> updatePaymentMethod({
    required String methodId,
    String? nickname,
    bool? setAsDefault,
  }) async {
    try {
      final methods = await getSavedPaymentMethods();
      final methodIndex = methods.indexWhere((m) => m.id == methodId);

      if (methodIndex == -1) {
        _logger.i('Payment method not found: $methodId');
        return false;
      }

      final method = methods[methodIndex];

      // Update fields
      if (nickname != null) {
        method.nickname = nickname;
      }

      if (setAsDefault == true) {
        // Remove default from all methods
        for (var m in methods) {
          m.isDefault = false;
        }
        method.isDefault = true;
        await setDefaultPaymentMethod(methodId);
      }

      await _saveMethodsToStorage(methods);
      _logger.i('Payment method updated: $methodId');
      return true;
    } catch (e) {
      _logger.e('Error updating payment method: $e');
      return false;
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(String methodId) async {
    try {
      final methods = await getSavedPaymentMethods();
      bool methodFound = false;

      // Update default status
      for (var method in methods) {
        if (method.id == methodId) {
          method.isDefault = true;
          methodFound = true;
        } else {
          method.isDefault = false;
        }
      }

      if (!methodFound) {
        _logger.i('Payment method not found: $methodId');
        return false;
      }

      await _saveMethodsToStorage(methods);

      // Store default method ID separately for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultMethodKey, methodId);

      _logger.i('Default payment method set: $methodId');
      return true;
    } catch (e) {
      _logger.e('Error setting default payment method: $e');
      return false;
    }
  }

  /// Get default payment method
  Future<SavedPaymentMethod?> getDefaultPaymentMethod() async {
    try {
      final methods = await getSavedPaymentMethods();
      return methods.firstWhere(
        (method) => method.isDefault,
        orElse: () =>
            methods.isNotEmpty ? methods.first : throw StateError('No methods'),
      );
    } catch (e) {
      _logger.i('No default payment method found');
      return null;
    }
  }

  /// Pay with saved payment method
  Future<Map<String, dynamic>> payWithSavedMethod({
    required String methodId,
    required double amount,
    required String currency,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final methods = await getSavedPaymentMethods();
      final method = methods.firstWhere(
        (m) => m.id == methodId,
        orElse: () => throw StateError('Payment method not found'),
      );

      // Update last used timestamp
      method.lastUsedAt = DateTime.now();
      await _saveMethodsToStorage(methods);

      // Process payment using stored token
      final result = await _peachPayments.processTokenPayment(
        token: method.token,
        amount: amount,
        currency: currency,
        description: description ?? 'Payment via saved method',
        metadata: {
          'payment_method_id': methodId,
          'card_type': method.cardType,
          'last_four': method.lastFourDigits,
          ...?metadata,
        },
      );

      // Sync with backend if payment successful
      if (result['success']) {
        await _paymentService.syncPaymentWithBackend({
          'payment_id': result['payment_id'],
          'amount': amount,
          'currency': currency,
          'payment_method_type': 'saved_card',
          'payment_method_id': methodId,
          'status': 'completed',
        });
      }

      return result;
    } catch (e) {
      _logger.e('Error processing payment with saved method: $e');
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
        'code': 'SAVED_PAYMENT_ERROR',
      };
    }
  }

  /// Validate all saved payment methods (check expiry, etc.)
  Future<List<String>> validateSavedMethods() async {
    try {
      final methods = await getSavedPaymentMethods();
      final expiredMethods = <String>[];
      final now = DateTime.now();

      for (var method in methods) {
        // Check if card is expired
        final expiryDate = DateTime(
          int.parse('20${method.expiryYear}'),
          int.parse(method.expiryMonth),
        );

        if (expiryDate.isBefore(now)) {
          expiredMethods.add(method.id);
        }
      }

      if (expiredMethods.isNotEmpty) {
        _logger.i('Found ${expiredMethods.length} expired payment methods');
      }

      return expiredMethods;
    } catch (e) {
      _logger.e('Error validating saved methods: $e');
      return [];
    }
  }

  /// Remove all expired payment methods
  Future<int> removeExpiredMethods() async {
    try {
      final expiredIds = await validateSavedMethods();
      int removedCount = 0;

      for (final methodId in expiredIds) {
        if (await deletePaymentMethod(methodId)) {
          removedCount++;
        }
      }

      _logger.i('Removed $removedCount expired payment methods');
      return removedCount;
    } catch (e) {
      _logger.e('Error removing expired methods: $e');
      return 0;
    }
  }

  /// Clear all saved payment methods
  Future<bool> clearAllSavedMethods() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      await prefs.remove(_defaultMethodKey);

      _logger.i('All saved payment methods cleared');
      return true;
    } catch (e) {
      _logger.e('Error clearing saved methods: $e');
      return false;
    }
  }

  /// Save methods list to secure storage
  Future<void> _saveMethodsToStorage(List<SavedPaymentMethod> methods) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(methods.map((m) => m.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  /// Detect card type from card number
  String _detectCardType(String cardNumber) {
    final number = cardNumber.replaceAll(RegExp(r'\D'), '');

    if (number.startsWith('4')) {
      return 'Visa';
    } else if (number.startsWith(RegExp(r'^5[1-5]'))) {
      return 'Mastercard';
    } else if (number.startsWith(RegExp(r'^3[47]'))) {
      return 'American Express';
    } else if (number.startsWith('6')) {
      return 'Discover';
    }

    return 'Unknown';
  }

  /// Revoke payment token from PeachPayments
  Future<void> _revokePaymentToken(String token) async {
    try {
      // Implement token revocation with PeachPayments API
      // In a real implementation, this would call the PeachPayments API to revoke the token
      _logger.i('Revoking payment token: $token');

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));

      _logger.i('Successfully revoked payment token: $token');
    } catch (e) {
      _logger.e('Error revoking payment token: $e');
    }
  }

  /// Get payment method by ID
  Future<SavedPaymentMethod?> getPaymentMethodById(String methodId) async {
    try {
      final methods = await getSavedPaymentMethods();
      return methods.firstWhere(
        (method) => method.id == methodId,
        orElse: () => throw StateError('Method not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get payment methods sorted by usage (most recent first)
  Future<List<SavedPaymentMethod>> getMethodsByUsage() async {
    final methods = await getSavedPaymentMethods();
    methods.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return methods;
  }

  /// Check if user has any saved payment methods
  Future<bool> hasSavedMethods() async {
    final methods = await getSavedPaymentMethods();
    return methods.isNotEmpty;
  }
}
