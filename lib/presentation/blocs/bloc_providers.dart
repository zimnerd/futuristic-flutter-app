import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment/payment_bloc.dart';
import 'subscription/subscription_bloc.dart';
import 'call/call_bloc.dart';
import 'discovery/discovery_bloc.dart';
import 'match/match_bloc.dart';
import 'profile/profile_bloc.dart';
import 'auth/auth_bloc.dart';
import 'user/user_bloc.dart';
import 'messaging/messaging_bloc.dart';
import '../../data/services/websocket_service.dart';
import '../../data/services/discovery_service.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/messaging_service.dart';
import '../../data/services/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/di/service_locator.dart' as di;
import '../../domain/repositories/user_repository.dart';

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
            matchingService: MatchingService(apiClient: ApiClient.instance),
          ),
        ),
        
        // Profile Management BLoC - User profile customization
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            profileService: ServiceLocator().profileService,
          ),
        ),
        
        // Authentication BLoC - User authentication and session management
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            userRepository: di.sl<UserRepository>(),
          ),
        ),

        // User Management BLoC - User profile operations and management
        BlocProvider<UserBloc>(
          create: (context) => UserBloc(
            userRepository: di.sl<UserRepository>(),
          ),
        ),

        // Messaging BLoC - Chat and conversation management
        BlocProvider<MessagingBloc>(
          create: (context) => MessagingBloc(
            messagingService: di.sl<MessagingService>(),
          ),
        ),
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

  // Authentication BLoC - User authentication and session management
  AuthBloc get authBloc => read<AuthBloc>();

  // User Management BLoC - User profile operations and management
  UserBloc get userBloc => read<UserBloc>();

  // Messaging BLoC - Chat and conversation management
  MessagingBloc get messagingBloc => read<MessagingBloc>();
}
