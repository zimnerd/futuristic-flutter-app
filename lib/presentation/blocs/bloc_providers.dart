import 'package:flutter/material.dart';

/// Provides all BLoCs to the widget tree with proper dependency injection
///
/// This is a simplified version for Batch 6. The complete dependency injection
/// setup will be implemented in a future batch when we have a proper DI container.
class BlocProviders extends StatelessWidget {
  const BlocProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // TODO: This is a placeholder implementation
    // Complete BLoC providers will be implemented when dependency injection is set up
    return Placeholder(
      child: Text(
        'BLoC Providers - Implementation Pending\n'
        'This requires proper dependency injection setup',
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Extension methods for easy BLoC access throughout the app
/// These will be implemented when BLoCs are properly provided
extension BlocExtensions on BuildContext {
  // TODO: Add BLoC getters when implemented
  // AuthBloc get authBloc => read<AuthBloc>();
  // UserBloc get userBloc => read<UserBloc>();
}
