import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../../../data/models/premium.dart';
import '../../../data/services/premium_service.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_state.dart';
import 'premium_event.dart';
import 'premium_state.dart';

class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final PremiumService _premiumService;
  final AuthBloc? _authBloc;
  final Logger _logger = Logger();
  static const String _tag = 'PremiumBloc';

  PremiumBloc({required PremiumService premiumService, AuthBloc? authBloc})
    : _premiumService = premiumService,
      _authBloc = authBloc,
      super(PremiumInitial()) {
    on<LoadPremiumData>(_onLoadPremiumData);
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<LoadCurrentSubscription>(_onLoadCurrentSubscription);
    on<SubscribeToPlan>(_onSubscribeToPlan);
    on<CancelSubscription>(_onCancelSubscription);
    on<ReactivateSubscription>(_onReactivateSubscription);
    on<PurchaseCoins>(_onPurchaseCoins);
    on<LoadCoinBalance>(_onLoadCoinBalance);
    on<LoadCoinTransactions>(_onLoadCoinTransactions);
    on<UsePremiumFeature>(_onUsePremiumFeature);
    on<LoadAvailableFeatures>(_onLoadAvailableFeatures);
    on<CheckFeatureAccess>(_onCheckFeatureAccess);
    on<RefreshPremiumData>(_onRefreshPremiumData);
  }

  /// Get current user ID from auth state
  String? get _currentUserId {
    final authState = _authBloc?.state;
    if (authState is AuthAuthenticated) {
      return authState.user.id;
    }
    return null; // Return null if not authenticated or authBloc not available
  }

  Future<void> _onLoadPremiumData(
    LoadPremiumData event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumLoading());
      _logger.i('$_tag: 🔄 Loading complete premium data');

      final results = await Future.wait([
        _premiumService.getAvailablePlans(),
        _premiumService.getCurrentSubscription(),
        _premiumService.getCoinBalance(),
        _premiumService.getAvailableFeatures(),
      ]);

      final plans = results[0] as List<PremiumPlan>;
      final subscription = results[1] as UserSubscription?;
      final coinBalance = results[2] as CoinBalance?;
      final features = results[3] as List<PremiumFeature>;

      _logger.i('$_tag: 📊 Results - Plans: ${plans.length}, Subscription: ${subscription != null ? "EXISTS (${subscription.status})" : "NULL"}, Features: ${features.length}');
      
      if (subscription != null) {
        _logger.i('$_tag: 🎫 Subscription Details - IsActive: ${subscription.isActive}, Tier: ${subscription.planName}, End: ${subscription.endDate}');
      }

      emit(
        PremiumLoaded(
          subscription: subscription,
          plans: plans,
          coinBalance:
              coinBalance ??
              CoinBalance(
                userId: _currentUserId ?? 'fallback-user-id',
                totalCoins: 0,
                lastUpdated: DateTime.now(),
              ),
          features: features.map((f) => f.name).toList(),
        ),
      );

      _logger.i('$_tag: ✅ Premium data loaded successfully - State: PremiumLoaded, HasSubscription: ${subscription != null}');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: ❌ Failed to load premium data',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to load premium data: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAvailablePlans(
    LoadAvailablePlans event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumLoading());
      _logger.d('$_tag: Loading available plans');

      final plans = await _premiumService.getAvailablePlans();

      if (state is PremiumLoaded) {
        final currentState = state as PremiumLoaded;
        emit(currentState.copyWith(plans: plans));
      } else {
        emit(
          PremiumLoaded(
            plans: plans,
            coinBalance: CoinBalance(
              userId: _currentUserId ?? 'fallback-user-id',
              totalCoins: 0,
              lastUpdated: DateTime.now(),
            ),
          ),
        );
      }

      _logger.d('$_tag: Loaded ${plans.length} available plans');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load plans',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to load plans: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCurrentSubscription(
    LoadCurrentSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      _logger.d('$_tag: Loading current subscription');

      final subscription = await _premiumService.getCurrentSubscription();

      if (state is PremiumLoaded) {
        final currentState = state as PremiumLoaded;
        emit(currentState.copyWith(subscription: subscription));
      } else {
        emit(
          PremiumLoaded(
            subscription: subscription,
            coinBalance: CoinBalance(
              userId: _currentUserId ?? 'fallback-user-id',
              totalCoins: 0,
              lastUpdated: DateTime.now(),
            ),
          ),
        );
      }

      _logger.d('$_tag: Current subscription loaded');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load subscription',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to load subscription: ${e.toString()}'));
    }
  }

  Future<void> _onSubscribeToPlan(
    SubscribeToPlan event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumSubscribing(event.planId));
      _logger.d('$_tag: Subscribing to plan: ${event.planId}');

      final subscription = await _premiumService.subscribeToPlan(
        planId: event.planId,
        paymentMethodId: event.paymentMethodId,
        promoCode: event.promoCode,
      );

      if (subscription != null) {
        emit(PremiumSubscriptionSuccess(subscription));
        _logger.d('$_tag: Subscription successful');

        // Refresh data
        add(RefreshPremiumData());
      } else {
        emit(PremiumError('Subscription failed - no response from server'));
      }
    } catch (e, stackTrace) {
      _logger.e('$_tag: Subscription failed', error: e, stackTrace: stackTrace);
      emit(PremiumError('Subscription failed: ${e.toString()}'));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumSubscriptionCancelling());
      _logger.d('$_tag: Cancelling subscription');

      final success = await _premiumService.cancelSubscription(
        reason: event.reason,
      );

      if (success) {
        emit(PremiumSubscriptionCancelled());
        _logger.d('$_tag: Subscription cancelled successfully');

        // Refresh data
        add(RefreshPremiumData());
      } else {
        emit(PremiumError('Failed to cancel subscription'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to cancel subscription',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to cancel subscription: ${e.toString()}'));
    }
  }

  Future<void> _onReactivateSubscription(
    ReactivateSubscription event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumLoading());
      _logger.d('$_tag: Reactivating subscription');

      final subscription = await _premiumService.reactivateSubscription();

      if (subscription != null) {
        emit(PremiumSubscriptionSuccess(subscription));
        _logger.d('$_tag: Subscription reactivated successfully');

        // Refresh data
        add(RefreshPremiumData());
      } else {
        emit(PremiumError('Failed to reactivate subscription'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to reactivate subscription',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to reactivate subscription: ${e.toString()}'));
    }
  }

  Future<void> _onPurchaseCoins(
    PurchaseCoins event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumCoinsUpdating());
      _logger.d('$_tag: Purchasing coins: ${event.coinPackageId}');

      final result = await _premiumService.purchaseCoins(
        coinPackageId: event.coinPackageId,
        paymentMethodId: event.paymentMethodId,
      );

      if (result != null) {
        emit(
          PremiumPaymentSuccess(result.transactionId, result.amount.toDouble()),
        );
        _logger.d('$_tag: Coins purchased successfully');

        // Refresh data
        add(RefreshPremiumData());
      } else {
        emit(PremiumError('Failed to purchase coins'));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Coin purchase failed',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to purchase coins: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCoinBalance(
    LoadCoinBalance event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      _logger.d('$_tag: Loading coin balance');

      final balance = await _premiumService.getCoinBalance();

      if (balance != null) {
        if (state is PremiumLoaded) {
          final currentState = state as PremiumLoaded;
          emit(currentState.copyWith(coinBalance: balance));
        } else {
          emit(PremiumLoaded(coinBalance: balance));
        }
        _logger.d('$_tag: Coin balance loaded: ${balance.totalCoins}');
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load coin balance',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to load coin balance: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCoinTransactions(
    LoadCoinTransactions event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      _logger.d('$_tag: Loading coin transactions (page ${event.page})');

      final transactions = await _premiumService.getCoinTransactions(
        page: event.page,
        limit: event.limit,
      );

      _logger.d('$_tag: Loaded ${transactions.length} coin transactions');
      // Note: You might want to add transaction state to PremiumState if needed
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load coin transactions',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to load coin transactions: ${e.toString()}'));
    }
  }

  Future<void> _onUsePremiumFeature(
    UsePremiumFeature event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumFeatureChecking(event.featureType.name));
      _logger.d('$_tag: Using premium feature: ${event.featureType.name}');

      final success = await _premiumService.usePremiumFeature(
        featureType: event.featureType,
        parameters: event.parameters,
      );

      if (success) {
        emit(PremiumFeatureAccessResult(event.featureType.name, true));
        _logger.d('$_tag: Premium feature used successfully');

        // Refresh data to update coin balance
        add(RefreshPremiumData());
      } else {
        emit(
          PremiumFeatureAccessResult(
            event.featureType.name,
            false,
            'Feature usage failed',
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to use premium feature',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to use premium feature: ${e.toString()}'));
    }
  }

  Future<void> _onLoadAvailableFeatures(
    LoadAvailableFeatures event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      _logger.d('$_tag: Loading available features');

      final features = await _premiumService.getAvailableFeatures();

      if (state is PremiumLoaded) {
        final currentState = state as PremiumLoaded;
        emit(
          currentState.copyWith(features: features.map((f) => f.name).toList()),
        );
      } else {
        emit(
          PremiumLoaded(
            features: features.map((f) => f.name).toList(),
            coinBalance: CoinBalance(
              userId: _currentUserId ?? 'fallback-user-id',
              totalCoins: 0,
              lastUpdated: DateTime.now(),
            ),
          ),
        );
      }

      _logger.d('$_tag: Loaded ${features.length} available features');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Failed to load features',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to load features: ${e.toString()}'));
    }
  }

  Future<void> _onCheckFeatureAccess(
    CheckFeatureAccess event,
    Emitter<PremiumState> emit,
  ) async {
    try {
      emit(PremiumFeatureChecking(event.featureType.name));
      _logger.d(
        '$_tag: Checking access for feature: ${event.featureType.name}',
      );

      // Note: You'd need to implement a hasFeatureAccess method in the service
      // For now, we'll check if user has an active subscription
      final subscription = await _premiumService.getCurrentSubscription();
      final hasAccess = subscription != null && subscription.isActive;

      String? reason;
      if (!hasAccess) {
        reason = 'Premium subscription required for ${event.featureType.name}';
      }

      emit(
        PremiumFeatureAccessResult(event.featureType.name, hasAccess, reason),
      );
      _logger.d('$_tag: Feature access check complete: $hasAccess');
    } catch (e, stackTrace) {
      _logger.e(
        '$_tag: Feature access check failed',
        error: e,
        stackTrace: stackTrace,
      );
      emit(PremiumError('Failed to check feature access: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshPremiumData(
    RefreshPremiumData event,
    Emitter<PremiumState> emit,
  ) async {
    // Only refresh if we're currently in a loaded state
    if (state is PremiumLoaded) {
      add(LoadPremiumData());
    }
  }
}
