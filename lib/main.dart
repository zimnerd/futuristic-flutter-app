import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import 'firebase_options.dart';
import 'app_providers.dart';
import 'blocs/call_bloc.dart';
import 'blocs/chat_bloc.dart';
import 'blocs/notification_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/hive_storage_service.dart';
import 'core/utils/logger.dart';
import 'core/services/service_locator.dart';
import 'data/datasources/local/user_local_data_source.dart';
import 'data/datasources/remote/chat_remote_data_source.dart';
import 'data/datasources/remote/notification_remote_data_source.dart';
import 'data/datasources/remote/user_remote_data_source.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'core/network/api_client.dart';
import 'data/services/webrtc_service.dart';
import 'data/services/websocket_service_impl.dart';
import 'domain/services/websocket_service.dart';
import 'data/services/event_service.dart';
import 'data/services/matching_service.dart';
import 'data/services/preferences_service.dart';
import 'data/services/discovery_service.dart';
import 'data/services/token_service.dart';
import 'data/services/message_database_service.dart';
import 'data/services/background_sync_manager.dart';
import 'data/services/statistics_service.dart';
import 'data/services/heat_map_service.dart';
import 'core/services/location_service.dart';
import 'domain/repositories/user_repository.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/blocs/event/event_bloc.dart';
import 'presentation/blocs/matching/matching_bloc.dart';
import 'presentation/blocs/match/match_bloc.dart';
import 'presentation/blocs/filters/filter_bloc.dart';
import 'presentation/blocs/discovery/discovery_bloc.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/theme/pulse_theme.dart';
import 'presentation/widgets/auto_login_wrapper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized (background isolate)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  AppLogger.info('Background message received: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fix Google Maps black screen issue on Android
  // See: https://github.com/flutter/flutter/issues/40284
  if (defaultTargetPlatform == TargetPlatform.android) {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
      AppLogger.info('✅ Google Maps Android view surface enabled');
    }
  }

  // Initialize Firebase ONCE (check if already initialized by background handler)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('✅ Firebase initialized');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      AppLogger.info('✅ Firebase already initialized (by background handler)');
    } else {
      AppLogger.error('❌ Firebase initialization error: $e');
      rethrow;
    }
  }

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage
  final hiveStorage = HiveStorageService();
  await hiveStorage.initialize();

  // Initialize ServiceLocator (required for token storage)
  await ServiceLocator.instance.initialize();

  // Initialize Firebase notifications
  await _initializeFirebaseNotifications();

  // Initialize authentication tokens
  await _initializeStoredTokens();

  runApp(PulseDatingApp(hiveStorage: hiveStorage));
}

/// Initialize Firebase notifications
Future<void> _initializeFirebaseNotifications() async {
  try {
    final notificationService = ServiceLocator.instance.firebaseNotificationService;
    await notificationService.initialize();
    AppLogger.info('✅ Firebase notifications initialized');
  } catch (e) {
    AppLogger.error('❌ Failed to initialize Firebase notifications: $e');
  }
}

/// Initialize stored authentication tokens in API client
Future<void> _initializeStoredTokens() async {
  try {
    // Use ApiClient's comprehensive token initialization which includes:
    // - Token existence check
    // - Token expiry validation
    // - Automatic token refresh if needed
    // - Token clearing if refresh fails
    await ApiClient.instance.initializeAuthToken();
    AppLogger.info('✅ Authentication tokens initialized');
  } catch (e) {
    AppLogger.error('❌ Failed to initialize stored tokens: $e');
    // Clear any invalid tokens on initialization failure
    try {
      final tokenService = TokenService();
      await tokenService.clearTokens();
    } catch (clearError) {
      AppLogger.error('❌ Failed to clear invalid tokens: $clearError');
    }
  }
}

class PulseDatingApp extends StatelessWidget {
  final HiveStorageService hiveStorage;

  const PulseDatingApp({super.key, required this.hiveStorage});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      hiveStorageService: hiveStorage,
      child: MultiBlocProvider(
        providers: [
          // Initialize services
          RepositoryProvider<ApiClient>(
            create: (context) => ApiClient.instance,
          ),
          RepositoryProvider<HiveStorageService>(
            create: (context) => hiveStorage,
          ),
          RepositoryProvider<WebSocketService>(
            create: (context) => WebSocketServiceImpl.instance,
          ),
          RepositoryProvider<WebRTCService>(
            create: (context) => WebRTCService(),
          ),
          RepositoryProvider<StatisticsService>(
            create: (context) => StatisticsService(context.read<ApiClient>()),
          ),
          RepositoryProvider<HeatMapService>(
            create: (context) => HeatMapService(context.read<ApiClient>()),
          ),
          RepositoryProvider<LocationService>(
            create: (context) => LocationService(),
          ),

          // Initialize data sources
          RepositoryProvider<UserRemoteDataSource>(
            create: (context) =>
                UserRemoteDataSourceImpl(context.read<ApiClient>()),
          ),
          RepositoryProvider<UserLocalDataSource>(
            create: (context) =>
                UserLocalDataSourceImpl(context.read<HiveStorageService>()),
          ),
          RepositoryProvider<ChatRemoteDataSource>(
            create: (context) =>
                ChatRemoteDataSourceImpl(context.read<ApiClient>()),
          ),
          RepositoryProvider<NotificationRemoteDataSource>(
            create: (context) =>
                NotificationRemoteDataSourceImpl(context.read<ApiClient>()),
          ),

          // Initialize repositories with complete implementation
          RepositoryProvider<UserRepository>(
            create: (context) => UserRepositoryImpl(
              context.read<UserRemoteDataSource>(),
              context.read<UserLocalDataSource>(),
            ),
          ),
          RepositoryProvider<ChatRepository>(
            create: (context) => ChatRepositoryImpl(
              remoteDataSource: context.read<ChatRemoteDataSource>(),
              webSocketService: context.read<WebSocketService>(),
            ),
          ),
          RepositoryProvider<NotificationRepository>(
            create: (context) => NotificationRepositoryImpl(
              remoteDataSource: context.read<NotificationRemoteDataSource>(),
            ),
          ),

          // Initialize BLoCs
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(userRepository: context.read<UserRepository>()),
          ),
          BlocProvider<UserBloc>(
            create: (context) =>
                UserBloc(userRepository: context.read<UserRepository>()),
          ),
          BlocProvider<ChatBloc>(
            create: (context) =>
                ChatBloc(chatRepository: context.read<ChatRepository>()),
          ),
          BlocProvider<NotificationBloc>(
            create: (context) => NotificationBloc(
              notificationRepository: context.read<NotificationRepository>(),
            ),
          ),
          BlocProvider<CallBloc>(
            create: (context) => CallBloc(
              webRTCService: context.read<WebRTCService>(),
              webSocketService: context.read<WebSocketService>(),
            ),
          ),
          BlocProvider<EventBloc>(
            create: (context) => EventBloc(eventService: EventService.instance),
          ),
          BlocProvider<MatchingBloc>(
            create: (context) => MatchingBloc(
              matchingService: MatchingService(
                apiClient: context.read<ApiClient>(),
              ),
            ),
          ),
          BlocProvider<MatchBloc>(
            create: (context) => MatchBloc(
              matchingService: MatchingService(
                apiClient: context.read<ApiClient>(),
              ),
            ),
          ),
          BlocProvider<FilterBLoC>(
            create: (context) => FilterBLoC(
              PreferencesService(context.read<ApiClient>()),
            ),
          ),
          BlocProvider<DiscoveryBloc>(
            create: (context) => DiscoveryBloc(
              discoveryService: DiscoveryService(
                apiClient: context.read<ApiClient>(),
              ),
              preferencesService: PreferencesService(context.read<ApiClient>()),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            // Initialize AppRouter with AuthBloc once it's available
            final authBloc = context.read<AuthBloc>();
            AppRouter.initialize(authBloc);
            
            // Get repositories for background sync
            final chatRepository = context.read<ChatRepository>();
            final databaseService = MessageDatabaseService();
            
            return BackgroundSyncManager.provider(
              chatRepository: chatRepository,
              databaseService: databaseService,
              child: AutoLoginWrapper(
                child: MaterialApp.router(
                  title: AppConstants.appName,
                  theme: PulseTheme.light,
                  darkTheme: PulseTheme.dark,
                  themeMode: ThemeMode.system,
                  debugShowCheckedModeBanner: false,
                  routerConfig: AppRouter.router,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
