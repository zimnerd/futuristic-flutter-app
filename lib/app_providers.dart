import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/services/service_locator.dart';
import 'presentation/blocs/matching/matching_bloc.dart';
import 'presentation/blocs/messaging/messaging_bloc.dart';
import 'presentation/blocs/profile/profile_bloc.dart';

/// Clean app setup with simple dependency injection
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final serviceLocator = ServiceLocator();
    serviceLocator.initialize();

    return MultiBlocProvider(
      providers: [
        BlocProvider<MatchingBloc>(
          create: (context) => MatchingBloc(
            matchingService: serviceLocator.matchingService,
          ),
        ),
        BlocProvider<MessagingBloc>(
          create: (context) => MessagingBloc(
            messagingService: serviceLocator.messagingService,
          ),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) =>
              ProfileBloc(profileService: serviceLocator.profileService),
        ),
      ],
      child: child,
    );
  }
}
/// Then use in widgets like:
/// 
/// BlocBuilder<MatchingBloc, MatchingState>(
///   builder: (context, state) {
///     // Use state here
///   },
/// )
/// 
/// context.read<MatchingBloc>().add(LoadPotentialMatches());
