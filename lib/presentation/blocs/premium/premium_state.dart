import 'package:equatable/equatable.dart';
import '../../../data/models/premium.dart';

abstract class PremiumState extends Equatable {
  const PremiumState();

  @override
  List<Object?> get props => [];
}

class PremiumInitial extends PremiumState {}

class PremiumLoading extends PremiumState {}

class PremiumLoaded extends PremiumState {
  final UserSubscription? subscription;
  final List<PremiumPlan> plans;
  final CoinBalance coinBalance;
  final List<String> features;

  const PremiumLoaded({
    this.subscription,
    this.plans = const [],
    required this.coinBalance,
    this.features = const [],
  });

  @override
  List<Object?> get props => [subscription, plans, coinBalance, features];

  PremiumLoaded copyWith({
    UserSubscription? subscription,
    List<PremiumPlan>? plans,
    CoinBalance? coinBalance,
    List<String>? features,
  }) {
    return PremiumLoaded(
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      coinBalance: coinBalance ?? this.coinBalance,
      features: features ?? this.features,
    );
  }
}

class PremiumError extends PremiumState {
  final String message;

  const PremiumError(this.message);

  @override
  List<Object> get props => [message];
}

// Subscription management states
class PremiumSubscribing extends PremiumState {
  final String planId;

  const PremiumSubscribing(this.planId);

  @override
  List<Object> get props => [planId];
}

class PremiumSubscriptionSuccess extends PremiumState {
  final UserSubscription subscription;

  const PremiumSubscriptionSuccess(this.subscription);

  @override
  List<Object> get props => [subscription];
}

class PremiumSubscriptionCancelling extends PremiumState {}

class PremiumSubscriptionCancelled extends PremiumState {}

// Payment states
class PremiumProcessingPayment extends PremiumState {
  final String method;
  final double amount;

  const PremiumProcessingPayment(this.method, this.amount);

  @override
  List<Object> get props => [method, amount];
}

class PremiumPaymentSuccess extends PremiumState {
  final String transactionId;
  final double amount;

  const PremiumPaymentSuccess(this.transactionId, this.amount);

  @override
  List<Object> get props => [transactionId, amount];
}

// Feature access states
class PremiumFeatureChecking extends PremiumState {
  final String feature;

  const PremiumFeatureChecking(this.feature);

  @override
  List<Object> get props => [feature];
}

class PremiumFeatureAccessResult extends PremiumState {
  final String feature;
  final bool hasAccess;
  final String? reason;

  const PremiumFeatureAccessResult(this.feature, this.hasAccess, [this.reason]);

  @override
  List<Object?> get props => [feature, hasAccess, reason];
}

// Coin management states
class PremiumCoinsUpdating extends PremiumState {}

class PremiumCoinsUpdated extends PremiumState {
  final CoinBalance newBalance;

  const PremiumCoinsUpdated(this.newBalance);

  @override
  List<Object> get props => [newBalance];
}
