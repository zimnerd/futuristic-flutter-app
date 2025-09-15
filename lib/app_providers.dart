import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/storage/hive_storage_service.dart';
import 'data/services/service_locator.dart';
import 'presentation/blocs/matching/matching_bloc.dart';
import 'presentation/blocs/messaging/messaging_bloc.dart';
import 'presentation/blocs/profile/profile_bloc.dart';
import 'presentation/blocs/filters/filter_bloc.dart';
import 'presentation/blocs/virtual_gift/virtual_gift_bloc.dart';
import 'presentation/blocs/safety/safety_bloc.dart';
import 'presentation/blocs/premium/premium_bloc.dart';
import 'presentation/blocs/ai_companion/ai_companion_bloc.dart';
import 'presentation/blocs/speed_dating/speed_dating_bloc.dart';
import 'presentation/blocs/live_streaming/live_streaming_bloc.dart';
import 'presentation/blocs/date_planning/date_planning_bloc.dart';
import 'presentation/blocs/voice_message/voice_message_bloc.dart';
import 'presentation/blocs/discovery/discovery_bloc.dart';
import 'presentation/blocs/call/call_bloc.dart';
import 'features/events/presentation/bloc/placeholder_event_bloc.dart';

/// Clean app setup with simple dependency injection
class AppProviders extends StatelessWidget {
  final Widget child;
  final HiveStorageService hiveStorageService;

  const AppProviders({
    super.key,
    required this.child,
    required this.hiveStorageService,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize services with secure storage
    final serviceLocator = ServiceLocator();
    serviceLocator.initialize(hiveStorageService.secureStorage);

    return MultiBlocProvider(
      providers: [
        // Core BLoCs
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
        BlocProvider<FilterBLoC>(
          create: (context) => FilterBLoC(serviceLocator.preferencesService),
        ),
        
        // Discovery & Matching
        BlocProvider<DiscoveryBloc>(
          create: (context) =>
              DiscoveryBloc(discoveryService: serviceLocator.discoveryService),
        ),

        // Communication BLoCs
        BlocProvider<VoiceMessageBloc>(
          create: (context) =>
              VoiceMessageBloc(serviceLocator.voiceMessageService),
        ),
        BlocProvider<CallBloc>(
          create: (context) =>
              CallBloc(webSocketService: serviceLocator.webSocketService),
        ),

        // Feature BLoCs
        BlocProvider<VirtualGiftBloc>(
          create: (context) =>
              VirtualGiftBloc(serviceLocator.virtualGiftService),
        ),
        BlocProvider<SafetyBloc>(
          create: (context) =>
              SafetyBloc(safetyService: serviceLocator.safetyService),
        ),
        BlocProvider<PremiumBloc>(
          create: (context) =>
              PremiumBloc(premiumService: serviceLocator.premiumService),
        ),
        BlocProvider<AiCompanionBloc>(
          create: (context) => AiCompanionBloc(
            aiCompanionService: serviceLocator.aiCompanionService,
          ),
        ),
        BlocProvider<SpeedDatingBloc>(
          create: (context) => SpeedDatingBloc(
            speedDatingService: serviceLocator.speedDatingService,
          ),
        ),
        BlocProvider<LiveStreamingBloc>(
          create: (context) =>
              LiveStreamingBloc(serviceLocator.liveStreamingService),
        ),
        BlocProvider<DatePlanningBloc>(
          create: (context) =>
              DatePlanningBloc(serviceLocator.datePlanningService),
        ),
        
        // Events BLoC
        BlocProvider<EventBloc>(
          create: (context) => EventBloc(),
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
