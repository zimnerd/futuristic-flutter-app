import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/premium_service.dart';
import 'coin_purchase_event.dart';
import 'coin_purchase_state.dart';

/// BLoC for managing coin purchase functionality
///
/// Handles:
/// - Loading payment methods
/// - Processing coin purchases
/// - Managing payment method selection
/// - Handling payment success/errors
class CoinPurchaseBloc extends Bloc<CoinPurchaseEvent, CoinPurchaseState> {
  final PaymentService _paymentService;
  final PremiumService _premiumService;
  final Logger _logger = Logger();

  CoinPurchaseBloc({
    required PaymentService paymentService,
    required PremiumService premiumService,
  })  : _paymentService = paymentService,
        _premiumService = premiumService,
        super(const CoinPurchaseInitial()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<PaymentMethodSelected>(_onPaymentMethodSelected);
    on<PurchaseCoinsRequested>(_onPurchaseCoinsRequested);
    on<ResetPurchaseFlow>(_onResetPurchaseFlow);
  }

  /// Load available payment methods
  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<CoinPurchaseState> emit,
  ) async {
    try {
      emit(const CoinPurchaseLoading(message: 'Loading payment methods...'));
      _logger.d('Loading payment methods for coin purchase');

      final paymentMethods = await _paymentService.getUserPaymentMethods();

      emit(PaymentMethodsLoaded(
        paymentMethods: paymentMethods,
        selectedPaymentMethodId: paymentMethods.isNotEmpty ? paymentMethods.first['id'] as String : null,
      ));

      _logger.d('Loaded ${paymentMethods.length} payment methods');
    } catch (e) {
      _logger.e('Failed to load payment methods: $e');
      emit(CoinPurchaseError(
        message: 'Failed to load payment methods: ${e.toString()}',
      ));
    }
  }

  /// Handle payment method selection
  Future<void> _onPaymentMethodSelected(
    PaymentMethodSelected event,
    Emitter<CoinPurchaseState> emit,
  ) async {
    if (state is PaymentMethodsLoaded) {
      final currentState = state as PaymentMethodsLoaded;
      emit(currentState.copyWith(selectedPaymentMethodId: event.paymentMethodId));
      _logger.d('Selected payment method: ${event.paymentMethodId}');
    }
  }

  /// Process coin purchase
  Future<void> _onPurchaseCoinsRequested(
    PurchaseCoinsRequested event,
    Emitter<CoinPurchaseState> emit,
  ) async {
    try {
      emit(const CoinPurchaseLoading(message: 'Processing payment...'));
      _logger.d('Processing coin purchase: ${event.coins} coins for \$${event.price}');

      String? paymentMethodId;

      // Get selected payment method if available
      if (state is PaymentMethodsLoaded) {
        final currentState = state as PaymentMethodsLoaded;
        paymentMethodId = currentState.selectedPaymentMethodId;
      }

      // If no payment method selected, try to load them
      if (paymentMethodId == null) {
        final paymentMethods = await _paymentService.getUserPaymentMethods();
        if (paymentMethods.isEmpty) {
          emit(const CoinPurchaseError(
            message: 'No payment method available. Please add a payment method first.',
          ));
          return;
        }
        paymentMethodId = paymentMethods.first['id'] as String;
      }

      // Purchase coins through premium service
      final result = await _premiumService.purchaseCoins(
        coinPackageId: event.coinPackageId,
        paymentMethodId: paymentMethodId,
      );

      if (result != null) {
        // Get updated balance
        final balance = await _premiumService.getCoinBalance();

        emit(CoinPurchaseSuccess(
          coinsAdded: event.coins,
          newBalance: balance?.totalCoins ?? 0,
          transactionId: result.transactionId,
        ));

        _logger.i('Coin purchase successful: ${event.coins} coins added');
      } else {
        emit(const CoinPurchaseError(
          message: 'Purchase failed. Please try again.',
        ));
      }
    } catch (e) {
      _logger.e('Coin purchase failed: $e');

      // Check for specific error types
      final errorMessage = e.toString();
      final isInsufficientFunds = errorMessage.toLowerCase().contains('insufficient') ||
          errorMessage.toLowerCase().contains('declined') ||
          errorMessage.toLowerCase().contains('payment failed');

      emit(CoinPurchaseError(
        message: _parseErrorMessage(errorMessage),
        isInsufficientFunds: isInsufficientFunds,
      ));
    }
  }

  /// Reset purchase flow to initial state
  Future<void> _onResetPurchaseFlow(
    ResetPurchaseFlow event,
    Emitter<CoinPurchaseState> emit,
  ) async {
    emit(const CoinPurchaseInitial());
  }

  /// Parse error message to be user-friendly
  String _parseErrorMessage(String error) {
    if (error.toLowerCase().contains('insufficient')) {
      return 'Payment declined. Please check your payment method.';
    } else if (error.toLowerCase().contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.toLowerCase().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.toLowerCase().contains('payment method')) {
      return 'Invalid payment method. Please select another.';
    } else {
      return 'Purchase failed. Please try again or contact support.';
    }
  }
}
