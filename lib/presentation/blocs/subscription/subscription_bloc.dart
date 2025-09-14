import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/service_locator.dart';
import '../../../data/services/service_locator.dart' as data_services;
import '../../../data/services/subscription_service.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/models/subscription.dart';
import '../../../data/models/subscription_plan.dart';
import '../../../data/models/subscription_usage.dart';
import '../../../core/utils/logger.dart';

/// Events for Subscription BLoC
abstract class SubscriptionEvent {}

class LoadSubscriptionEvent extends SubscriptionEvent {}

class LoadSubscriptionPlansEvent extends SubscriptionEvent {}

class LoadSubscriptionUsageEvent extends SubscriptionEvent {}

class UpdateSubscriptionPlanEvent extends SubscriptionEvent {
  final String planId;
  final String paymentMethodId;
  
  UpdateSubscriptionPlanEvent({required this.planId, required this.paymentMethodId});
}

class CancelSubscriptionEvent extends SubscriptionEvent {
  final String reason;
  
  CancelSubscriptionEvent({required this.reason});
}

class ResumeSubscriptionEvent extends SubscriptionEvent {}

class RefreshSubscriptionDataEvent extends SubscriptionEvent {}

/// States for Subscription BLoC
abstract class SubscriptionState {}

class SubscriptionInitial extends SubscriptionState {}

class SubscriptionLoading extends SubscriptionState {}

class SubscriptionLoaded extends SubscriptionState {
  final Subscription? subscription;
  
  SubscriptionLoaded(this.subscription);
}

class SubscriptionPlansLoaded extends SubscriptionState {
  final List<SubscriptionPlan> plans;
  
  SubscriptionPlansLoaded(this.plans);
}

class SubscriptionUsageLoaded extends SubscriptionState {
  final SubscriptionUsage? usage;
  
  SubscriptionUsageLoaded(this.usage);
}

class SubscriptionDataLoaded extends SubscriptionState {
  final Subscription? subscription;
  final List<SubscriptionPlan> plans;
  final SubscriptionUsage? usage;
  
  SubscriptionDataLoaded({
    required this.subscription,
    required this.plans,
    required this.usage,
  });
}

class SubscriptionSuccess extends SubscriptionState {
  final String message;
  final Map<String, dynamic>? data;
  
  SubscriptionSuccess(this.message, {this.data});
}

class SubscriptionError extends SubscriptionState {
  final String message;
  
  SubscriptionError(this.message);
}

/// Subscription BLoC for managing subscription operations
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  late final SubscriptionService _subscriptionService;

  SubscriptionBloc() : super(SubscriptionInitial()) {
    // Initialize the subscription service with required dependencies
    _subscriptionService = data_services.ServiceLocator().subscriptionService;
    
    on<LoadSubscriptionEvent>(_onLoadSubscription);
    on<LoadSubscriptionPlansEvent>(_onLoadSubscriptionPlans);
    on<LoadSubscriptionUsageEvent>(_onLoadSubscriptionUsage);
    on<UpdateSubscriptionPlanEvent>(_onUpdateSubscriptionPlan);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<ResumeSubscriptionEvent>(_onResumeSubscription);
    on<RefreshSubscriptionDataEvent>(_onRefreshSubscriptionData);
  }

  Future<void> _onLoadSubscription(
    LoadSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      final subscription = await _subscriptionService.getCurrentSubscription();
      emit(SubscriptionLoaded(subscription));
      
      // Track analytics
      if (subscription != null) {
        ServiceLocator.instance.analytics.trackEvent(
          eventType: AnalyticsEventType.featureUsed,
          properties: {
            'feature': 'subscription_loaded',
            'plan': subscription.planId,
            'status': subscription.status.name,
          },
        );
      }
    } catch (e) {
      AppLogger.error('Failed to load subscription: $e');
      emit(SubscriptionError('Failed to load subscription'));
    }
  }

  Future<void> _onLoadSubscriptionPlans(
    LoadSubscriptionPlansEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      // Get predefined plans from the model
      final plans = PredefinedPlans.plans;
      emit(SubscriptionPlansLoaded(plans));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'subscription_plans_loaded',
          'count': plans.length,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load subscription plans: $e');
      emit(SubscriptionError('Failed to load subscription plans'));
    }
  }

  Future<void> _onLoadSubscriptionUsage(
    LoadSubscriptionUsageEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      final usage = await _subscriptionService.getSubscriptionUsage();
      emit(SubscriptionUsageLoaded(usage));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'subscription_usage_loaded',
          'has_usage': usage != null,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to load subscription usage: $e');
      emit(SubscriptionError('Failed to load subscription usage'));
    }
  }

  Future<void> _onUpdateSubscriptionPlan(
    UpdateSubscriptionPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      // Find the plan by ID
      final plan = PredefinedPlans.plans.firstWhere(
        (p) => p.id == event.planId,
        orElse: () => throw Exception('Plan not found'),
      );
      
      final result = await _subscriptionService.changePlan(
        newPlan: plan,
      );
      
      emit(SubscriptionSuccess('Subscription plan updated successfully', 
        data: result.data?.toJson()));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'subscription_plan_updated',
          'new_plan': event.planId,
        },
      );
      
      // Refresh subscription data
      add(RefreshSubscriptionDataEvent());
    } catch (e) {
      AppLogger.error('Failed to update subscription plan: $e');
      emit(SubscriptionError('Failed to update subscription plan'));
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      final result = await _subscriptionService.cancelSubscription(
        reason: event.reason,
      );
      
      emit(SubscriptionSuccess('Subscription cancelled successfully', 
        data: result.data?.toJson()));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'subscription_cancelled',
          'reason': event.reason,
        },
      );
      
      // Refresh subscription data
      add(RefreshSubscriptionDataEvent());
    } catch (e) {
      AppLogger.error('Failed to cancel subscription: $e');
      emit(SubscriptionError('Failed to cancel subscription'));
    }
  }

  Future<void> _onResumeSubscription(
    ResumeSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      final result = await _subscriptionService.resumeSubscription();
      
      emit(SubscriptionSuccess('Subscription resumed successfully', 
        data: result.data?.toJson()));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'subscription_resumed',
        },
      );
      
      // Refresh subscription data
      add(RefreshSubscriptionDataEvent());
    } catch (e) {
      AppLogger.error('Failed to resume subscription: $e');
      emit(SubscriptionError('Failed to resume subscription'));
    }
  }

  Future<void> _onRefreshSubscriptionData(
    RefreshSubscriptionDataEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(SubscriptionLoading());
    
    try {
      // Load all subscription data in parallel
      final results = await Future.wait<dynamic>([
        _subscriptionService.getCurrentSubscription(),
        Future.value(PredefinedPlans.plans), // Static data
        _subscriptionService.getSubscriptionUsage(),
      ]);
      
      final subscription = results[0] as Subscription?;
      final plans = results[1] as List<SubscriptionPlan>;
      final usage = results[2] as SubscriptionUsage?;
      
      emit(SubscriptionDataLoaded(
        subscription: subscription,
        plans: plans,
        usage: usage,
      ));
      
      // Track analytics
      ServiceLocator.instance.analytics.trackEvent(
        eventType: AnalyticsEventType.featureUsed,
        properties: {
          'feature': 'subscription_data_refreshed',
          'current_plan': subscription?.planId ?? 'none',
          'has_usage': usage != null,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to refresh subscription data: $e');
      emit(SubscriptionError('Failed to refresh subscription data'));
    }
  }
}
