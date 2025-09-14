import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment/payment_bloc.dart';
import 'subscription/subscription_bloc.dart';
import 'call/call_bloc.dart';
import 'discovery/discovery_bloc.dart';
import 'match/match_bloc.dart';
import 'profile/profile_bloc.dart';
import '../../data/services/websocket_service.dart';
import '../../data/services/discovery_service.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/service_locator.dart';
import '../../core/network/api_client.dart';

/// Provides all BLoCs to the widget tree with proper dependency injection
/// 
/// Note: This is a focused implementation for payment/subscription features.
/// Additional BLoCs can be added as needed when their dependencies are resolved.
class BlocProviders extends StatelessWidget {
  const BlocProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Payment & Subscription BLoCs - Ready for integration
        BlocProvider<PaymentBloc>(create: (context) => PaymentBloc()),
        BlocProvider<SubscriptionBloc>(create: (context) => SubscriptionBloc()),
        
        // Call Management BLoC - Real-time communication
        BlocProvider<CallBloc>(
          create: (context) =>
              CallBloc(webSocketService: WebSocketService.instance),
        ),

        // Discovery BLoC - User discovery and swiping
        BlocProvider<DiscoveryBloc>(
          create: (context) =>
              DiscoveryBloc(discoveryService: DiscoveryService()),
        ),

        // Match Management BLoC - Matching system and chat integration
        BlocProvider<MatchBloc>(
          create: (context) => MatchBloc(
            matchingService: MatchingService(apiClient: ApiClient()),
          ),
        ),
        
        // Profile Management BLoC - User profile customization
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            profileService: ServiceLocator().profileService,
          ),
        ),
        
        // TODO: Add other BLoCs when their service dependencies are properly set up
        // Examples:
        // BlocProvider<AuthBloc>(
        //   create: (context) => AuthBloc(userRepository: ServiceLocator.instance.userRepository),
        // ),
      ],
      child: child,
    );
  }
}

/// Extension methods for easy BLoC access throughout the app
extension BlocExtensions on BuildContext {
  // Payment & Subscription BLoCs - Ready to use
  PaymentBloc get paymentBloc => read<PaymentBloc>();
  SubscriptionBloc get subscriptionBloc => read<SubscriptionBloc>();
  
  // Call Management BLoC - Real-time communication
  CallBloc get callBloc => read<CallBloc>();

  // Discovery BLoC - User discovery and swiping
  DiscoveryBloc get discoveryBloc => read<DiscoveryBloc>();

  // Match Management BLoC - Matching system and chat integration
  MatchBloc get matchBloc => read<MatchBloc>();

  // Profile Management BLoC - User profile customization
  ProfileBloc get profileBloc => read<ProfileBloc>();

  // TODO: Add other BLoC getters when implemented
  // AuthBloc get authBloc => read<AuthBloc>();
  // UserBloc get userBloc => read<UserBloc>();
}
