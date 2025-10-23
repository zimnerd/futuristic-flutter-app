import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/photo/photo_bloc.dart';
import '../blocs/safety/safety_bloc.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/entities/user_profile.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart' as simple_login;
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/verification_method_screen.dart';
import '../screens/auth/register_screen.dart' show RegisterScreen;
import '../screens/main/home_screen.dart';
import '../screens/main/matches_screen.dart';
import '../screens/main/messages_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/settings_screen.dart';
import '../screens/main/filters_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/landing_screen.dart';
import '../screens/onboarding/intent_selection_screen.dart';
import '../screens/onboarding/profile_setup_wizard.dart';
import '../screens/subscription_management_screen.dart';
import '../screens/payment/payment_methods_screen.dart';
import '../../../presentation/payment/screens/saved_payment_methods_screen.dart';
import '../../../presentation/payment/screens/add_payment_method_screen.dart';
import '../../../screens/payment_history_screen.dart';
import '../../../screens/payment_processing_screen.dart';
import '../../../domain/entities/payment_entities.dart';
// Advanced feature screens
import '../screens/virtual_gifts/virtual_gifts_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/premium/premium_showcase_screen.dart';
import '../screens/safety/safety_screen.dart';
import '../screens/ai_companion/ai_companion_screen.dart';
import '../screens/speed_dating/speed_dating_screen.dart';
import '../screens/live_streaming/live_streaming_screen.dart';
import '../screens/date_planning/date_planning_screen.dart';
import '../screens/date_planning/date_plan_details_screen.dart';
import '../screens/date_planning/create_date_plan_screen.dart';
import '../screens/voice_messages/voice_messages_screen.dart';
import '../screens/speed_dating/speed_dating_room_screen.dart';
import '../screens/speed_dating/speed_dating_event_details_screen.dart';
import '../screens/live_streaming/start_stream_screen.dart';
import '../screens/live_streaming/live_stream_viewer_screen.dart';
import '../screens/live_streaming/live_stream_broadcaster_screen.dart';
import '../screens/live_streaming/schedule_stream_screen.dart';
import '../screens/live_streaming/scheduled_streams_screen.dart';
import '../screens/ai_companion/ai_companion_chat_screen.dart';
import '../../../features/group_chat/presentation/screens/group_chat_screen.dart';
import '../../../features/group_chat/presentation/screens/create_group_screen.dart';
import '../../../features/group_chat/presentation/screens/group_list_screen.dart';
import '../blocs/group_chat/group_chat_bloc.dart';
import '../../../features/group_chat/data/group_chat_service.dart';
import '../../../features/group_chat/data/group_chat_websocket_service.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../../../features/group_chat/presentation/screens/video_call_screen.dart'
    as group_chat_video;
import '../screens/group_chat/group_chat_settings_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/profile/profile_creation_screen.dart';
import '../screens/profile/profile_section_edit_screen.dart';
import '../screens/profile/profile_details_screen.dart';
import '../screens/profile/profile_edit_screen.dart';
import '../screens/profile/profile_viewers_screen.dart';
import '../screens/profile/privacy_settings_screen.dart';
import '../screens/verification/photo_verification_screen.dart';
import '../screens/verification/id_verification_screen.dart';
import '../screens/verification/verification_status_screen.dart';
import '../screens/profile/photo_gallery_screen.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/blocked_users_screen.dart';
import '../screens/safety/safety_center_screen.dart';
import '../screens/safety/emergency_contacts_screen.dart';
import '../screens/matching/match_explanation_screen.dart';
import '../screens/analytics/advanced_analytics_screen.dart'
    show AnalyticsScreen;
import '../blocs/notification/notification_bloc.dart';
import '../blocs/block_report/block_report_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/call/video_call_screen.dart';
import '../screens/calls/audio_call_screen.dart'; // ✅ FIXED: Using NEW version with WebSocket
import '../screens/calls/call_history_screen.dart';
import '../screens/calls/call_details_screen.dart';
import '../blocs/call_history/call_history_barrel.dart';
import '../../../data/repositories/call_history_repository.dart';
import '../screens/discovery/discovery_screen.dart';
import '../screens/discovery/who_liked_you_screen.dart';
import '../screens/features/advanced_features_screen.dart';
import '../screens/explore/explore_screen.dart';
import '../screens/heat_map_screen.dart';
import '../screens/premium/transaction_history_screen.dart';
import '../screens/matching/ai_matching_screen.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/ai_companion.dart';
import '../../../data/services/safety_service.dart';
import '../../../data/services/date_planning_service.dart';
import '../blocs/date_planning/date_planning_bloc.dart';
import '../../../data/services/virtual_gift_service.dart';
import '../blocs/virtual_gift/virtual_gift_bloc.dart';
import '../../../data/services/speed_dating_service.dart';
import '../blocs/speed_dating/speed_dating_bloc.dart';
import '../../../data/services/voice_message_service.dart';
import '../blocs/voice_message/voice_message_bloc.dart';
import '../../../features/group_chat/data/models.dart';
import '../../../domain/entities/event.dart';
// Events screens
import '../screens/events/events_screen.dart';
import '../screens/events/event_details_screen.dart';
import '../../../features/events/presentation/screens/create_event_screen.dart';
import '../../../features/events/presentation/screens/event_communication_screen.dart';
import '../widgets/navigation/main_navigation_wrapper.dart';

/// Listenable adapter for AuthBloc to work with GoRouter refreshListenable
class AuthBlocListenable extends ChangeNotifier {
  AuthBlocListenable(this._authBloc) {
    _authBloc.stream.listen((_) {
      notifyListeners();
    });
  }

  final AuthBloc _authBloc;
}

/// Application routes configuration using GoRouter
/// Provides type-safe navigation with route guards and transitions
class AppRouter {
  static GoRouter? _router;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Initialize router with AuthBloc for navigation state updates
  static void initialize(AuthBloc authBloc) {
    final authListenable = AuthBlocListenable(authBloc);

    _router = GoRouter(
      debugLogDiagnostics: kDebugMode,
      initialLocation: AppRoutes.welcome,
      redirect: _handleRedirect,
      refreshListenable: authListenable,
      navigatorKey: navigatorKey,
      routes: [
        // Onboarding routes
        GoRoute(
          path: AppRoutes.welcome,
          name: 'welcome',
          builder: (context, state) => const LandingScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.intentSelection,
          name: 'intentSelection',
          builder: (context, state) => const IntentSelectionScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileSetup,
          name: 'profileSetup',
          builder: (context, state) => const ProfileSetupWizard(),
        ),

        // Authentication routes
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const simple_login.LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final phoneNumber = extra?['phoneNumber'] as String?;
            return RegisterScreen(phoneNumber: phoneNumber);
          },
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgotPassword',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: AppRoutes.otpVerify,
          name: 'otpVerify',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return OTPVerificationScreen(
              sessionId: extra['sessionId'] as String,
              phoneNumber: extra['phoneNumber'] as String,
              deliveryMethods: extra['deliveryMethods'] as List<String>?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.verificationMethod,
          name: 'verificationMethod',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return VerificationMethodScreen(
              userId: extra?['userId'] as String?,
            );
          },
        ),

        // Main app routes with StatefulShellRoute for tab state preservation
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainNavigationWrapper(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0: Discover/Home Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  name: 'home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),

            // Branch 1: Sparks/Matches Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.matches,
                  name: 'matches',
                  builder: (context, state) => const MatchesScreen(),
                ),
              ],
            ),

            // Branch 2: Explore Tab (NEW - Feature Hub)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.explore,
                  name: 'explore',
                  builder: (context, state) => const ExploreScreen(),
                ),
              ],
            ),

            // Branch 4: Events Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.events,
                  name: 'events',
                  builder: (context, state) => const EventsScreen(),
                ),
              ],
            ),

            // Branch 5: DMs/Messages Tab
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.messages,
                  name: 'messages',
                  builder: (context, state) => const MessagesScreen(),
                ),
              ],
            ),

            // Branch 6: Profile Tab (FIXED - now shows actual profile)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.profile,
                  name: 'profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        // Detail screens (outside tabs - no bottom nav)
        GoRoute(
          path: AppRoutes.settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.filters,
          name: 'filters',
          builder: (context, state) => const FiltersScreen(),
        ),
        GoRoute(
          path: AppRoutes.statistics,
          name: 'statistics',
          builder: (context, state) => const StatisticsScreen(),
        ),
        GoRoute(
          path: AppRoutes.heatMap,
          name: 'heat-map',
          builder: (context, state) => const HeatMapScreen(),
        ),
        GoRoute(
          path: AppRoutes.subscription,
          name: 'subscription',
          builder: (context, state) => const SubscriptionManagementScreen(),
        ),

        // Events routes (full screen)
        GoRoute(
          path: AppRoutes.eventDetails,
          name: 'eventDetails',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            return EventDetailsScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: AppRoutes.createEvent,
          name: 'createEvent',
          builder: (context, state) => const CreateEventScreen(),
        ),
        GoRoute(
          path: AppRoutes.eventCommunication,
          name: 'eventCommunication',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            // For now, create a dummy event. In real implementation, fetch from state/service
            final event = Event(
              id: eventId,
              title: 'Sample Event',
              description: 'Sample event description',
              location: 'Sample location',
              coordinates: const EventCoordinates(lat: 0.0, lng: 0.0),
              date: DateTime.now(),
              image: null,
              category: 'Social',
              createdAt: DateTime.now(),
              attendees: [],
            );
            return EventCommunicationScreen(event: event);
          },
        ),

        // Advanced feature routes (full screen, not in bottom nav)
        GoRoute(
          path: AppRoutes.discovery,
          name: 'discovery',
          builder: (context, state) => const DiscoveryScreen(),
        ),
        GoRoute(
          path: AppRoutes.whoLikedYou,
          name: 'whoLikedYou',
          builder: (context, state) => const WhoLikedYouScreen(),
        ),
        GoRoute(
          path: AppRoutes.advancedFeatures,
          name: 'advancedFeatures',
          builder: (context, state) => const AdvancedFeaturesScreen(),
        ),
        GoRoute(
          path: AppRoutes.transactionHistory,
          name: 'transactionHistory',
          builder: (context, state) => const TransactionHistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.aiMatching,
          name: 'aiMatching',
          builder: (context, state) {
            final authBloc = BlocProvider.of<AuthBloc>(context);
            final authState = authBloc.state;
            if (authState is! AuthAuthenticated) {
              // Redirect to login if not authenticated
              Future.microtask(() => context.go(AppRoutes.login));
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return AiMatchingScreen(currentUser: authState.user);
          },
        ),
        GoRoute(
          path: AppRoutes.virtualGifts,
          name: 'virtualGifts',
          builder: (context, state) {
            final recipientId = state.uri.queryParameters['recipientId'];
            final recipientName = state.uri.queryParameters['recipientName'];
            return BlocProvider(
              create: (_) =>
                  VirtualGiftBloc(VirtualGiftService(ApiClient.instance)),
              child: VirtualGiftsScreen(
                recipientId: recipientId,
                recipientName: recipientName,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.premium,
          name: 'premium',
          builder: (context, state) => const PremiumScreen(),
        ),
        GoRoute(
          path: AppRoutes.premiumShowcase,
          name: 'premiumShowcase',
          builder: (context, state) {
            final highlightFeature = state.uri.queryParameters['feature'];
            final selectedPlanId = state.uri.queryParameters['plan'];
            final source = state.uri.queryParameters['source'];
            return PremiumShowcaseScreen(
              highlightFeature: highlightFeature,
              selectedPlanId: selectedPlanId,
              source: source,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.safety,
          name: 'safety',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                SafetyBloc(safetyService: SafetyService(ApiClient.instance)),
            child: const SafetyScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.aiCompanion,
          name: 'aiCompanion',
          builder: (context, state) => const AiCompanionScreen(),
        ),
        GoRoute(
          path: AppRoutes.speedDating,
          name: 'speedDating',
          builder: (context, state) {
            final authBloc = context.read<AuthBloc>();
            return BlocProvider(
              create: (_) => SpeedDatingBloc(
                speedDatingService: SpeedDatingService(),
                authBloc: authBloc,
              ),
              child: const SpeedDatingScreen(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.liveStreaming,
          name: 'liveStreaming',
          builder: (context, state) => const LiveStreamingScreen(),
        ),
        GoRoute(
          path: AppRoutes.datePlanning,
          name: 'datePlanning',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                DatePlanningBloc(DatePlanningService(ApiClient.instance)),
            child: const DatePlanningScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.voiceMessages,
          name: 'voiceMessages',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                VoiceMessageBloc(VoiceMessageService(ApiClient.instance)),
            child: const VoiceMessagesScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profileCreation,
          name: 'profileCreation',
          builder: (context, state) => const ProfileCreationScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileSectionEdit,
          name: 'profileSectionEdit',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final sectionType =
                extra?['sectionType'] as String? ?? 'basic_info';
            final initialData = extra?['initialData'] as Map<String, dynamic>?;

            return BlocProvider(
              create: (context) =>
                  PhotoBloc(userRepository: context.read<UserRepository>()),
              child: ProfileSectionEditScreen(
                sectionType: sectionType,
                initialData: initialData,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.profileDetails,
          name: 'profileDetails',
          builder: (context, state) {
            // Extract profile and context from extra data
            final extraData = state.extra;
            final UserProfile? profile;
            final ProfileContext profileContext;
            final VoidCallback? onLike;
            final VoidCallback? onDislike;
            final VoidCallback? onSuperLike;

            if (extraData is Map<String, dynamic>) {
              profile = extraData['profile'] as UserProfile?;
              profileContext =
                  extraData['context'] as ProfileContext? ??
                  ProfileContext.general;
              onLike = extraData['onLike'] as VoidCallback?;
              onDislike = extraData['onDislike'] as VoidCallback?;
              onSuperLike = extraData['onSuperLike'] as VoidCallback?;
            } else if (extraData is UserProfile) {
              // Backward compatibility
              profile = extraData;
              profileContext = ProfileContext.general;
              onLike = null;
              onDislike = null;
              onSuperLike = null;
            } else {
              profile = null;
              profileContext = ProfileContext.general;
              onLike = null;
              onDislike = null;
              onSuperLike = null;
            }

            if (profile == null) {
              // Navigate back if no profile provided
              return Scaffold(
                appBar: AppBar(title: const Text('Profile Not Found')),
                body: const Center(child: Text('Profile not found')),
              );
            }

            return ProfileDetailsScreen(
              profile: profile,
              isOwnProfile: false,
              context: profileContext,
              onLike: onLike,
              onDislike: onDislike,
              onSuperLike: onSuperLike,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.chat,
          name: 'chat',
          builder: (context, state) {
            final conversationId = state.pathParameters['conversationId'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;

            return ChatScreen(
              conversationId: conversationId,
              otherUserId: extra?['otherUserId'] ?? '',
              otherUserName: extra?['otherUserName'] ?? 'User',
              otherUserPhoto: extra?['otherUserPhoto'],
            );
          },
        ),
        GoRoute(
          path: AppRoutes.videoCall,
          name: 'videoCall',
          builder: (context, state) {
            final callId = state.pathParameters['callId'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;
            
            // Get remoteUser - could be UserModel or UserProfile
            final remoteUserObject = extra?['remoteUser'];
            final remoteUserModel = remoteUserObject is UserModel
                ? remoteUserObject
                : null;
            final remoteUserProfile = remoteUserObject is UserProfile
                ? remoteUserObject
                : null;

            // Convert UserModel to UserProfile if needed
            final remoteUser = remoteUserModel != null
                ? UserProfile(
                    id: remoteUserModel.id,
                    name: remoteUserModel.firstName ?? remoteUserModel.username,
                    age: remoteUserModel.age ?? 25,
                    bio: remoteUserModel.bio ?? '',
                    photos: remoteUserModel.photos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final p = entry.value;
                      String photoUrl = '';

                      if (p is String) {
                        photoUrl = p;
                      } else if (p is Map) {
                        photoUrl = p['url'] as String? ?? '';
                      } else {
                        photoUrl = (p as dynamic).url as String? ?? '';
                      }

                      return ProfilePhoto(
                        id: 'photo_$index',
                        url: photoUrl,
                        order: index,
                        isMain: index == 0,
                      );
                    }).toList(),
                    location: UserLocation(
                      latitude:
                          remoteUserModel.coordinates?['latitude'] as double? ??
                          0.0,
                      longitude:
                          remoteUserModel.coordinates?['longitude']
                              as double? ??
                          0.0,
                      address: remoteUserModel.location ?? 'Unknown',
                      city: remoteUserModel.location ?? 'Unknown',
                      country: 'Unknown',
                    ),
                  )
                : remoteUserProfile ??
                      UserProfile(
                        id: 'unknown_user',
                        name: 'Unknown User',
                        age: 25,
                        bio: '',
                        photos: [],
                        location: UserLocation(
                          latitude: 0.0,
                          longitude: 0.0,
                          address: 'Unknown',
                          city: 'Unknown',
                          country: 'Unknown',
                        ),
                      );

            return VideoCallScreen(callId: callId, remoteUser: remoteUser);
          },
        ),
        GoRoute(
          path: AppRoutes.audioCall,
          name: 'audioCall',
          builder: (context, state) {
            final callId = state.pathParameters['callId'] ?? '';
            final extra = state.extra as Map<String, dynamic>?;
            final remoteUser = extra?['remoteUser'] as UserModel;
            final isIncoming = extra?['isIncoming'] as bool? ?? false;

            // Extract photo URL - handle both String and Photo object
            String? photoUrl;
            if (remoteUser.photos.isNotEmpty) {
              final firstPhoto = remoteUser.photos.first;
              if (firstPhoto is String) {
                photoUrl = firstPhoto;
              } else if (firstPhoto is Map<String, dynamic>) {
                photoUrl = firstPhoto['url'] as String?;
              } else {
                // Photo object with url getter
                photoUrl = (firstPhoto as dynamic).url as String?;
              }
            }

            return AudioCallScreen(
              callId: callId,
              recipientId: remoteUser.id,
              userName: remoteUser.firstName ?? remoteUser.username,
              userPhotoUrl: photoUrl,
              isOutgoing: !isIncoming, // Convert isIncoming to isOutgoing
            );
          },
        ),
        GoRoute(
          path: AppRoutes.profileEdit,
          name: 'profileEdit',
          builder: (context, state) => const ProfileEditScreen(),
        ),
        GoRoute(
          path: AppRoutes.profileViewers,
          name: 'profileViewers',
          builder: (context, state) => const ProfileViewersScreen(),
        ),
        GoRoute(
          path: AppRoutes.privacySettings,
          name: 'privacySettings',
          builder: (context, state) => const PrivacySettingsScreen(),
        ),

        // Date Planning routes
        GoRoute(
          path: AppRoutes.datePlanDetails,
          name: 'datePlanDetails',
          builder: (context, state) {
            final datePlan = state.extra as Map<String, dynamic>;
            return DatePlanDetailsScreen(datePlan: datePlan);
          },
        ),
        GoRoute(
          path: AppRoutes.createDatePlan,
          name: 'createDatePlan',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CreateDatePlanScreen(
              planToEdit: extra?['planToEdit'],
              suggestion: extra?['suggestion'],
            );
          },
        ),

        // Speed Dating routes
        GoRoute(
          path: AppRoutes.speedDatingRoom,
          name: 'speedDatingRoom',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return SpeedDatingRoomScreen(
              session: extra['session'],
              eventId: extra['eventId'] as String,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.speedDatingEventDetails,
          name: 'speedDatingEventDetails',
          builder: (context, state) {
            final event = state.extra as Map<String, dynamic>;
            return SpeedDatingEventDetailsScreen(event: event);
          },
        ),

        // Live Streaming routes
        GoRoute(
          path: AppRoutes.startStream,
          name: 'startStream',
          builder: (context, state) {
            final streamToEdit = state.extra as Map<String, dynamic>?;
            return StartStreamScreen(streamToEdit: streamToEdit);
          },
        ),
        GoRoute(
          path: AppRoutes.liveStreamViewer,
          name: 'liveStreamViewer',
          builder: (context, state) {
            final stream = state.extra as Map<String, dynamic>;
            return LiveStreamViewerScreen(stream: stream);
          },
        ),
        GoRoute(
          path: AppRoutes.liveStreamBroadcaster,
          name: 'liveStreamBroadcaster',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return LiveStreamBroadcasterScreen(
              streamId: extra['streamId'] as String,
              title: extra['title'] as String,
              description: extra['description'] as String? ?? '',
            );
          },
        ),
        GoRoute(
          path: AppRoutes.scheduledStreams,
          name: 'scheduledStreams',
          builder: (context, state) => const ScheduledStreamsScreen(),
        ),
        GoRoute(
          path: AppRoutes.scheduleStream,
          name: 'scheduleStream',
          builder: (context, state) {
            final streamData = state.extra as Map<String, dynamic>?;
            return ScheduleStreamScreen(streamToEdit: streamData);
          },
        ),

        // AI Companion routes
        GoRoute(
          path: AppRoutes.aiCompanionChat,
          name: 'aiCompanionChat',
          builder: (context, state) {
            final companion = state.extra as AICompanion;
            return AiCompanionChatScreen(companion: companion);
          },
        ),

        // Group Chat routes
        GoRoute(
          path: AppRoutes.groupList,
          name: 'groupList',
          builder: (context, state) {
            // Create GroupChatBloc with required services
            final apiClient = ApiClient.instance;
            final authToken = apiClient.authToken ?? '';

            final groupChatService = GroupChatService();
            final wsService = GroupChatWebSocketService(
              baseUrl: ApiConstants.websocketUrl,
              accessToken: authToken,
            );

            final bloc = GroupChatBloc(
              service: groupChatService,
              wsService: wsService,
            );

            return BlocProvider.value(
              value: bloc,
              child: GroupListScreen(bloc: bloc),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.groupChat,
          name: 'groupChat',
          builder: (context, state) {
            final group = state.extra as GroupConversation;

            // Create GroupChatBloc with required services
            final apiClient = ApiClient.instance;
            final authToken = apiClient.authToken ?? '';

            final groupChatService = GroupChatService();
            final wsService = GroupChatWebSocketService(
              baseUrl: ApiConstants.websocketUrl,
              accessToken: authToken,
            );

            final bloc = GroupChatBloc(
              service: groupChatService,
              wsService: wsService,
            );

            return BlocProvider.value(
              value: bloc,
              child: GroupChatScreen(group: group),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.groupChatSettings,
          name: 'groupChatSettings',
          builder: (context, state) {
            final group = state.extra as GroupConversation;
            return GroupChatSettingsScreen(group: group);
          },
        ),
        GoRoute(
          path: AppRoutes.createGroup,
          name: 'createGroup',
          builder: (context, state) {
            // Create GroupChatBloc with required services
            final apiClient = ApiClient.instance;
            final authToken = apiClient.authToken ?? '';

            final groupChatService = GroupChatService();
            final wsService = GroupChatWebSocketService(
              baseUrl: ApiConstants.websocketUrl,
              accessToken: authToken,
            );

            final bloc = GroupChatBloc(
              service: groupChatService,
              wsService: wsService,
            );

            return BlocProvider.value(
              value: bloc,
              child: const CreateGroupScreen(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.groupVideoCall,
          name: 'groupVideoCall',
          builder: (context, state) {
            final liveSessionId = state.pathParameters['liveSessionId'] ?? '';
            final data = state.extra as Map<String, dynamic>?;

            // Get or create GroupChatBloc - must be provided for VideoCallScreen
            final groupChatBloc = data?['groupChatBloc'] as GroupChatBloc?;

            if (groupChatBloc == null) {
              // Return error screen if bloc not provided
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: const Center(
                  child: Text(
                    'Failed to initialize video call. Please try again.',
                  ),
                ),
              );
            }

            return BlocProvider.value(
              value: groupChatBloc,
              child: group_chat_video.VideoCallScreen(
                liveSessionId: liveSessionId,
                rtcToken: data?['rtcToken'] as String? ?? '',
                session: data?['session'],
              ),
            );
          },
        ),

        // Notifications route
        GoRoute(
          path: AppRoutes.notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationScreen(),
        ),

        // Call History routes
        GoRoute(
          path: AppRoutes.callHistory,
          name: 'callHistory',
          builder: (context, state) {
            // Create CallHistoryBloc with repository
            final repository = CallHistoryRepository();
            final bloc = CallHistoryBloc(repository: repository);

            return BlocProvider<CallHistoryBloc>.value(
              value: bloc,
              child: const CallHistoryScreen(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.callDetails,
          name: 'callDetails',
          builder: (context, state) {
            final callId = state.pathParameters['callId'] ?? '';
            // Create CallHistoryBloc with repository for details screen
            final repository = CallHistoryRepository();
            final bloc = CallHistoryBloc(repository: repository);

            return BlocProvider<CallHistoryBloc>.value(
              value: bloc,
              child: CallDetailsScreen(callId: callId),
            );
          },
        ),

        // Payment routes
        GoRoute(
          path: AppRoutes.paymentMethods,
          name: 'paymentMethods',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PaymentMethodsScreen(
              planId: extra?['planId'] as String?,
              planName: extra?['planName'] as String?,
              amount: extra?['amount'] as double?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.savedPaymentMethods,
          name: 'savedPaymentMethods',
          builder: (context, state) => const SavedPaymentMethodsScreen(),
        ),
        GoRoute(
          path: AppRoutes.addPaymentMethod,
          name: 'addPaymentMethod',
          builder: (context, state) => const AddPaymentMethodScreen(),
        ),
        GoRoute(
          path: AppRoutes.paymentHistory,
          name: 'paymentHistory',
          builder: (context, state) => const PaymentHistoryScreen(),
        ),
        GoRoute(
          path: AppRoutes.paymentProcessing,
          name: 'paymentProcessing',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final amount = extra?['amount'] as double? ?? 0.0;
            final typeString = extra?['type'] as String? ?? 'premium';
            // Convert String to PaymentType enum
            final paymentType = PaymentType.values.firstWhere(
              (e) => e.name == typeString,
              orElse: () => PaymentType.premium,
            );
            return PaymentProcessingScreen(
              amount: amount,
              paymentType: paymentType,
            );
          },
        ),

        // Verification routes
        GoRoute(
          path: AppRoutes.photoVerification,
          name: 'photoVerification',
          builder: (context, state) => const PhotoVerificationScreen(),
        ),
        GoRoute(
          path: AppRoutes.idVerification,
          name: 'idVerification',
          builder: (context, state) => const IdVerificationScreen(),
        ),
        GoRoute(
          path: AppRoutes.verificationStatus,
          name: 'verificationStatus',
          builder: (context, state) => const VerificationStatusScreen(),
        ),

        // Photo management routes
        GoRoute(
          path: AppRoutes.photoGallery,
          name: 'photoGallery',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return PhotoGalleryScreen(
              photos: extra?['photos'] as List<ProfilePhoto>? ?? [],
              initialIndex: extra?['initialIndex'] as int? ?? 0,
              heroTag: extra?['heroTag'] as String?,
              showDetails: extra?['showDetails'] as bool? ?? false,
            );
          },
        ),

        // Notification settings routes
        GoRoute(
          path: AppRoutes.notificationSettings,
          name: 'notificationSettings',
          builder: (context, state) {
            return BlocProvider(
              create: (context) => NotificationBloc(
                userRepository: context.read<UserRepository>(),
                authBloc: context.read<AuthBloc>(),
              )..add(const LoadNotificationPreferences()),
              child: const NotificationSettingsScreen(),
            );
          },
        ),

        // Safety & Security routes
        GoRoute(
          path: AppRoutes.safetyCenter,
          name: 'safetyCenter',
          builder: (context, state) {
            return const SafetyCenterScreen();
          },
        ),
        GoRoute(
          path: '/safety/emergency-contacts',
          name: 'emergencyContacts',
          builder: (context, state) {
            return const EmergencyContactsScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.matchExplanation,
          name: 'matchExplanation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return MatchExplanationScreen(
              profile: extra['profile'] as UserProfile,
              compatibilityScore: extra['compatibilityScore'] as double,
              matchReasons: extra['matchReasons'] as Map<String, dynamic>?,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.advancedAnalytics,
          name: 'advancedAnalytics',
          builder: (context, state) {
            return const AnalyticsScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.blockedUsers,
          name: 'blockedUsers',
          builder: (context, state) {
            final authState = context.read<AuthBloc>().state;
            final currentUserId = authState is AuthAuthenticated
                ? authState.user.id
                : '';

            return BlocProvider(
              create: (context) => BlockReportBloc(
                userRepository: context.read<UserRepository>(),
                currentUserId: currentUserId,
              ),
              child: const SafetyBlockedUsersScreen(),
            );
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.uri.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.welcome),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static GoRouter get router =>
      _router ??
      (throw StateError(
        'AppRouter not initialized. Call AppRouter.initialize() first.',
      ));

  /// Handle route redirects based on authentication state and profile completion
  static FutureOr<String?> _handleRedirect(BuildContext context, GoRouterState state) async {
    final authBloc = context.read<AuthBloc>();
    final isAuthenticated = authBloc.isAuthenticated;
    final isLoading = authBloc.isLoading;
    final currentState = authBloc.state;

    final isAuthRoute =
        state.fullPath?.startsWith('/auth') == true ||
        state.fullPath == AppRoutes.login ||
        state.fullPath == AppRoutes.register ||
        state.fullPath == AppRoutes.forgotPassword ||
        state.fullPath == AppRoutes.otpVerify ||
        state.fullPath == AppRoutes.verificationMethod;

    final isWelcomeRoute =
        state.fullPath == AppRoutes.welcome ||
        state.fullPath == AppRoutes.onboarding;

    final isProfileSetupRoute = state.fullPath == AppRoutes.profileSetup;

    // Debug logging
    debugPrint('🔄 Navigation Debug:');
    debugPrint('  Current Path: ${state.fullPath}');
    debugPrint('  Auth State: ${currentState.runtimeType}');
    debugPrint('  Is Authenticated: $isAuthenticated');
    debugPrint('  Is Loading: $isLoading');
    debugPrint('  Is Auth Route: $isAuthRoute');
    debugPrint('  Is Welcome Route: $isWelcomeRoute');

    // Don't redirect while authentication is loading
    if (isLoading) {
      debugPrint('  ⏳ Auth loading - no redirect');
      return null;
    }

    // Check verification status for authenticated users
    if (currentState is AuthVerificationRequired &&
        !state.fullPath!.contains(AppRoutes.verificationMethod)) {
      debugPrint(
        '  🔐 User needs verification - redirecting to verification method selection',
      );
      return AppRoutes.verificationMethod;
    }

    // Check profile enrichment status for authenticated users
    if (currentState is AuthProfileEnrichmentRequired &&
        !state.fullPath!.contains(AppRoutes.profileSetup)) {
      debugPrint(
        '  📝 User needs profile enrichment - redirecting to profile setup',
      );
      return AppRoutes.profileSetup;
    }

    // Check profile completion status for authenticated users
    if (isAuthenticated) {
      final prefs = await SharedPreferences.getInstance();
      final profileSetupComplete = prefs.getBool('profile_setup_complete') ?? false;

      // If authenticated user hasn't completed profile setup
      if (!profileSetupComplete && !isProfileSetupRoute) {
        debugPrint('  📝 Profile setup incomplete - redirecting to profile setup');
        return AppRoutes.profileSetup;
      }

      // If user is authenticated with completed profile and trying to access auth/welcome routes,
      // redirect to home
      if ((isAuthRoute || isWelcomeRoute) && profileSetupComplete) {
        debugPrint(
          '  ✅ Authenticated user accessing welcome/auth route - redirecting to home',
        );
        return AppRoutes.home;
      }
    }

    // If user is not authenticated and trying to access protected routes,
    // redirect to welcome screen
    if (!isAuthenticated && !isAuthRoute && !isWelcomeRoute) {
      debugPrint(
        '  🚫 Unauthenticated user accessing protected route - redirecting to welcome',
      );
      return AppRoutes.welcome;
    }

    debugPrint('  ➡️ No redirect needed');
    // Allow the navigation
    return null;
  }
}

/// Route path constants
class AppRoutes {
  static const String welcome = '/';
  static const String onboarding = '/onboarding';
  static const String intentSelection = '/intent-selection';
  static const String profileSetup = '/profile-setup';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerify = '/otp-verify';
  static const String verificationMethod = '/verification-method';
  static const String home = '/home';
  static const String matches = '/matches';
  static const String explore = '/explore';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String filters = '/filters';
  static const String statistics = '/statistics';
  static const String heatMap = '/heat-map';
  static const String subscription = '/subscription';
  static const String events = '/events';

  // Advanced feature routes
  static const String discovery = '/discovery';
  static const String whoLikedYou = '/who-liked-you';
  static const String advancedFeatures = '/advanced-features';
  static const String virtualGifts = '/virtual-gifts';
  static const String premium = '/premium';
  static const String premiumShowcase = '/premium-showcase';
  static const String safety = '/safety';
  static const String aiCompanion = '/ai-companion';
  static const String speedDating = '/speed-dating';
  static const String liveStreaming = '/live-streaming';
  static const String datePlanning = '/date-planning';
  static const String voiceMessages = '/voice-messages';
  static const String profileCreation = '/profile-creation';
  static const String profileSectionEdit = '/profile-section-edit';
  static const String profileDetails = '/profile-details/:profileId';
  static const String profileEdit = '/profile-edit';
  static const String profileViewers = '/profile-viewers';
  static const String privacySettings = '/privacy-settings';
  static const String chat = '/chat/:conversationId';
  static const String videoCall = '/video-call/:callId';
  static const String groupVideoCall = '/group-video-call/:liveSessionId';
  static const String audioCall = '/audio-call/:callId';

  // Events routes
  static const String eventDetails = '/events/:eventId';
  static const String createEvent = '/events/create';
  static const String eventCommunication = '/events/:eventId/communication';

  // Date planning routes
  static const String datePlanDetails = '/date-plan-details';
  static const String createDatePlan = '/create-date-plan';

  // Speed dating routes
  static const String speedDatingRoom = '/speed-dating-room';
  static const String speedDatingEventDetails = '/speed-dating-event-details';

  // Live streaming routes
  static const String startStream = '/start-stream';
  static const String liveStreamViewer = '/live-stream-viewer';
  static const String liveStreamBroadcaster = '/live-stream-broadcaster';
  static const String scheduledStreams = '/scheduled-streams';
  static const String scheduleStream = '/schedule-stream';

  // AI Companion routes
  static const String aiCompanionChat = '/ai-companion-chat';

  // Group chat routes
  static const String groupList = '/group-list';
  static const String groupChat = '/group-chat';
  static const String groupChatSettings = '/group-chat-settings';
  static const String createGroup = '/create-group';

  // Notification route
  static const String notifications = '/notifications';

  // Call history routes
  static const String callHistory = '/call-history';
  static const String callDetails = '/call-details/:callId';

  // Payment routes
  static const String paymentMethods = '/payment-methods';
  static const String savedPaymentMethods = '/saved-payment-methods';
  static const String addPaymentMethod = '/add-payment-method';
  static const String paymentHistory = '/payment-history';
  static const String paymentProcessing = '/payment-processing';

  // Verification routes
  static const String photoVerification = '/photo-verification';
  static const String idVerification = '/id-verification';
  static const String verificationStatus = '/verification-status';

  // Photo management routes
  static const String photoGallery = '/photo-gallery';

  // Notification settings routes
  static const String notificationSettings = '/notification-settings';

  // Safety & Security routes
  static const String safetyCenter = '/safety-center';
  static const String blockedUsers = '/blocked-users';

  // Matching routes
  static const String matchExplanation = '/match-explanation';

  // Analytics routes
  static const String advancedAnalytics = '/advanced-analytics';
  
  // AI Matching routes
  static const String aiMatching = '/ai-matching';

  // Transaction routes
  static const String transactionHistory = '/transaction-history';
}
