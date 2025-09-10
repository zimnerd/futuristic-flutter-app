import 'package:equatable/equatable.dart';
import '../../../data/models/premium.dart';

abstract class PremiumEvent extends Equatable {
  const PremiumEvent();

  @override
  List<Object?> get props => [];
}

class LoadPremiumData extends PremiumEvent {}

class LoadAvailablePlans extends PremiumEvent {}

class LoadCurrentSubscription extends PremiumEvent {}

class SubscribeToPlan extends PremiumEvent {
  final String planId;
  final String paymentMethodId;
  final String? promoCode;

  const SubscribeToPlan({
    required this.planId,
    required this.paymentMethodId,
    this.promoCode,
  });

  @override
  List<Object?> get props => [planId, paymentMethodId, promoCode];
}

class CancelSubscription extends PremiumEvent {
  final String? reason;

  const CancelSubscription([this.reason]);

  @override
  List<Object?> get props => [reason];
}

class ReactivateSubscription extends PremiumEvent {}

class PurchaseCoins extends PremiumEvent {
  final String coinPackageId;
  final String paymentMethodId;

  const PurchaseCoins({
    required this.coinPackageId,
    required this.paymentMethodId,
  });

  @override
  List<Object> get props => [coinPackageId, paymentMethodId];
}

class LoadCoinBalance extends PremiumEvent {}

class LoadCoinTransactions extends PremiumEvent {
  final int page;
  final int limit;

  const LoadCoinTransactions({this.page = 1, this.limit = 20});

  @override
  List<Object> get props => [page, limit];
}

class UsePremiumFeature extends PremiumEvent {
  final PremiumFeatureType featureType;
  final Map<String, dynamic>? parameters;

  const UsePremiumFeature({
    required this.featureType,
    this.parameters,
  });

  @override
  List<Object?> get props => [featureType, parameters];
}

class LoadAvailableFeatures extends PremiumEvent {}

class CheckFeatureAccess extends PremiumEvent {
  final PremiumFeatureType featureType;

  const CheckFeatureAccess(this.featureType);

  @override
  List<Object> get props => [featureType];
}

class RefreshPremiumData extends PremiumEvent {}
