import 'package:equatable/equatable.dart';

/// Events for coin purchase BLoC
abstract class CoinPurchaseEvent extends Equatable {
  const CoinPurchaseEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request coin purchase
class PurchaseCoinsRequested extends CoinPurchaseEvent {
  final String coinPackageId;
  final int coins;
  final double price;

  const PurchaseCoinsRequested({
    required this.coinPackageId,
    required this.coins,
    required this.price,
  });

  @override
  List<Object?> get props => [coinPackageId, coins, price];
}

/// Event to select a payment method
class PaymentMethodSelected extends CoinPurchaseEvent {
  final String paymentMethodId;

  const PaymentMethodSelected(this.paymentMethodId);

  @override
  List<Object?> get props => [paymentMethodId];
}

/// Event to load available payment methods
class LoadPaymentMethods extends CoinPurchaseEvent {
  const LoadPaymentMethods();
}

/// Event to reset the purchase flow
class ResetPurchaseFlow extends CoinPurchaseEvent {
  const ResetPurchaseFlow();
}
