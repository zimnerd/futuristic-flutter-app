import 'package:equatable/equatable.dart';

/// States for coin purchase BLoC
abstract class CoinPurchaseState extends Equatable {
  const CoinPurchaseState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any purchase action
class CoinPurchaseInitial extends CoinPurchaseState {
  const CoinPurchaseInitial();
}

/// Loading state during payment processing
class CoinPurchaseLoading extends CoinPurchaseState {
  final String? message;

  const CoinPurchaseLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when payment methods are loaded
class PaymentMethodsLoaded extends CoinPurchaseState {
  final List<Map<String, dynamic>> paymentMethods;
  final String? selectedPaymentMethodId;

  const PaymentMethodsLoaded({
    required this.paymentMethods,
    this.selectedPaymentMethodId,
  });

  @override
  List<Object?> get props => [paymentMethods, selectedPaymentMethodId];

  PaymentMethodsLoaded copyWith({
    List<Map<String, dynamic>>? paymentMethods,
    String? selectedPaymentMethodId,
  }) {
    return PaymentMethodsLoaded(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      selectedPaymentMethodId:
          selectedPaymentMethodId ?? this.selectedPaymentMethodId,
    );
  }
}

/// Success state after successful purchase
class CoinPurchaseSuccess extends CoinPurchaseState {
  final int coinsAdded;
  final int newBalance;
  final String transactionId;

  const CoinPurchaseSuccess({
    required this.coinsAdded,
    required this.newBalance,
    required this.transactionId,
  });

  @override
  List<Object?> get props => [coinsAdded, newBalance, transactionId];
}

/// Error state when purchase fails
class CoinPurchaseError extends CoinPurchaseState {
  final String message;
  final bool isInsufficientFunds;

  const CoinPurchaseError({
    required this.message,
    this.isInsufficientFunds = false,
  });

  @override
  List<Object?> get props => [message, isInsufficientFunds];
}
