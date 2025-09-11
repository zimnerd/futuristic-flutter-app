import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/analytics_service.dart';
import '../../../core/utils/logger.dart';

/// Events for Payment BLoC
abstract class PaymentEvent {}

class LoadPaymentMethodsEvent extends PaymentEvent {}

class AddPaymentMethodEvent extends PaymentEvent {
  final PaymentMethod type;
  final Map<String, dynamic> paymentData;
  
  AddPaymentMethodEvent({required this.type, required this.paymentData});
}

class RemovePaymentMethodEvent extends PaymentEvent {
  final String paymentMethodId;
  
  RemovePaymentMethodEvent(this.paymentMethodId);
}

class ProcessSubscriptionPaymentEvent extends PaymentEvent {
  final String planId;
  final String paymentMethodId;
  
  ProcessSubscriptionPaymentEvent({required this.planId, required this.paymentMethodId});
}

class ProcessBoostPaymentEvent extends PaymentEvent {
  final String boostType;
  final String paymentMethodId;
  
  ProcessBoostPaymentEvent({required this.boostType, required this.paymentMethodId});
}

class LoadPaymentHistoryEvent extends PaymentEvent {}

class RequestRefundEvent extends PaymentEvent {
  final String transactionId;
  final String reason;
  
  RequestRefundEvent({required this.transactionId, required this.reason});
}

/// States for Payment BLoC
abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentMethodsLoaded extends PaymentState {
  final List<Map<String, dynamic>> paymentMethods;
  
  PaymentMethodsLoaded(this.paymentMethods);
}

class PaymentHistoryLoaded extends PaymentState {
  final List<Map<String, dynamic>> transactions;
  
  PaymentHistoryLoaded(this.transactions);
}

class PaymentSuccess extends PaymentState {
  final String message;
  final Map<String, dynamic>? data;
  
  PaymentSuccess(this.message, {this.data});
}

class PaymentError extends PaymentState {
  final String message;
  
  PaymentError(this.message);
}

/// Payment BLoC for managing payment operations
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService = ServiceLocator.instance.payment;

  PaymentBloc() : super(PaymentInitial()) {
    on<LoadPaymentMethodsEvent>(_onLoadPaymentMethods);
    on<AddPaymentMethodEvent>(_onAddPaymentMethod);
    on<RemovePaymentMethodEvent>(_onRemovePaymentMethod);
    on<ProcessSubscriptionPaymentEvent>(_onProcessSubscriptionPayment);
    on<ProcessBoostPaymentEvent>(_onProcessBoostPayment);
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
    on<RequestRefundEvent>(_onRequestRefund);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethodsEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final paymentMethods = await _paymentService.getUserPaymentMethods();
      emit(PaymentMethodsLoaded(paymentMethods));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'payment_methods_loaded',
          'count': paymentMethods.length,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load payment methods: $e');
      emit(PaymentError('Failed to load payment methods'));
    }
  }

  Future<void> _onAddPaymentMethod(
    AddPaymentMethodEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final result = await _paymentService.createPaymentMethod(
        type: event.type,
        paymentData: event.paymentData,
      );
      
      emit(PaymentSuccess('Payment method added successfully', data: result));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'payment_method_added',
          'type': event.type.name,
        },
      );
      
      // Reload payment methods
      add(LoadPaymentMethodsEvent());
    } catch (e) {
      AppLogger.error('Failed to add payment method: $e');
      emit(PaymentError('Failed to add payment method'));
    }
  }

  Future<void> _onRemovePaymentMethod(
    RemovePaymentMethodEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await _paymentService.deletePaymentMethod(event.paymentMethodId);
      emit(PaymentSuccess('Payment method removed successfully'));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'payment_method_removed',
          'paymentMethodId': event.paymentMethodId,
        },
      );
      
      // Reload payment methods
      add(LoadPaymentMethodsEvent());
    } catch (e) {
      AppLogger.error('Failed to remove payment method: $e');
      emit(PaymentError('Failed to remove payment method'));
    }
  }

  Future<void> _onProcessSubscriptionPayment(
    ProcessSubscriptionPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final result = await _paymentService.processSubscriptionPayment(
        planId: event.planId,
        paymentMethodId: event.paymentMethodId,
      );
      
      emit(PaymentSuccess('Subscription payment processed successfully', data: result));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackPremiumEvent(
        action: 'completed',
        planId: event.planId,
        properties: {
          'paymentMethodId': event.paymentMethodId,
          'source': 'subscription_payment',
        },
      );
    } catch (e) {
      AppLogger.error('Failed to process subscription payment: $e');
      emit(PaymentError('Failed to process subscription payment'));
      
      // Track failed payment
      ServiceLocator.instance.analytics.trackError(
        errorType: 'subscription_payment_failed',
        errorMessage: e.toString(),
        context: {
          'planId': event.planId,
          'paymentMethodId': event.paymentMethodId,
        },
      );
    }
  }

  Future<void> _onProcessBoostPayment(
    ProcessBoostPaymentEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      // Use one-time payment for boosts
      final result = await _paymentService.processOneTimePayment(
        amount: _getBoostPrice(event.boostType),
        currency: 'USD',
        paymentMethodId: event.paymentMethodId,
        description: 'Profile Boost - ${event.boostType}',
        metadata: {'type': 'boost', 'boostType': event.boostType},
      );
      
      emit(PaymentSuccess('Boost payment processed successfully', data: result));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.boostPurchased,
        properties: {
          'boostType': event.boostType,
          'paymentMethodId': event.paymentMethodId,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to process boost payment: $e');
      emit(PaymentError('Failed to process boost payment'));
      
      // Track failed payment
      ServiceLocator.instance.analytics.trackError(
        errorType: 'boost_payment_failed',
        errorMessage: e.toString(),
        context: {
          'boostType': event.boostType,
          'paymentMethodId': event.paymentMethodId,
        },
      );
    }
  }

  /// Get boost price based on type
  double _getBoostPrice(String boostType) {
    switch (boostType.toLowerCase()) {
      case 'profile_boost':
        return 4.99;
      case 'super_boost':
        return 9.99;
      case 'mega_boost':
        return 19.99;
      default:
        return 4.99;
    }
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      final history = await _paymentService.getPaymentHistory();
      emit(PaymentHistoryLoaded(history));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'payment_history_loaded',
          'count': history.length,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load payment history: $e');
      emit(PaymentError('Failed to load payment history'));
    }
  }

  Future<void> _onRequestRefund(
    RequestRefundEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    
    try {
      await _paymentService.requestRefund(
        paymentId: event.transactionId,
        reason: event.reason,
      );
      
      emit(PaymentSuccess('Refund request submitted successfully'));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'refund_requested',
          'transactionId': event.transactionId,
          'reason': event.reason,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to request refund: $e');
      emit(PaymentError('Failed to request refund'));
    }
  }
}
