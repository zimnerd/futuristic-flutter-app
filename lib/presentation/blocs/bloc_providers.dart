import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment/payment_bloc.dart';
import 'subscription/subscription_bloc.dart';

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
        
        // TODO: Add other BLoCs when their service dependencies are properly set up
        // Examples:
        // BlocProvider<AuthBloc>(
        //   create: (context) => AuthBloc(userRepository: ServiceLocator.instance.userRepository),
        // ),
        // BlocProvider<ProfileBloc>(
        //   create: (context) => ProfileBloc(profileService: ServiceLocator.instance.profileService),
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

  // TODO: Add other BLoC getters when implemented
  // AuthBloc get authBloc => read<AuthBloc>();
  // UserBloc get userBloc => read<UserBloc>();
  // ProfileBloc get profileBloc => read<ProfileBloc>();
}
