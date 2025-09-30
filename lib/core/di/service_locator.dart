import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../storage/hive_storage_service.dart';
import '../constants/api_constants.dart';
import '../../data/services/messaging_service.dart';
import '../../data/services/matching_service.dart';
import '../../data/services/token_service.dart';
import '../../features/group_chat/data/group_chat_service.dart';
import '../../features/group_chat/data/group_chat_websocket_service.dart';
import '../../data/datasources/remote/user_remote_data_source.dart';
import '../../data/datasources/local/user_local_data_source.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/user_repository.dart';
import '../../presentation/blocs/messaging/messaging_bloc.dart';
import '../../presentation/blocs/matching/matching_bloc.dart';
import '../../presentation/blocs/group_chat/group_chat_bloc.dart';

/// Service locator for dependency injection
final GetIt sl = GetIt.instance;

/// Initialize dependencies
Future<void> initializeDependencies() async {
  // Core Storage
  sl.registerLazySingleton<HiveStorageService>(() => HiveStorageService());

  // Core Network
  sl.registerLazySingleton<ApiClient>(() => ApiClient.instance);

  // Data Sources
  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(sl<HiveStorageService>()),
  );

  // Repositories
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      sl<UserRemoteDataSource>(),
      sl<UserLocalDataSource>(),
    ),
  );

  // Services
  sl.registerLazySingleton<MessagingService>(
    () => MessagingService(apiClient: sl()),
  );
  sl.registerLazySingleton<MatchingService>(
    () => MatchingService(apiClient: sl()),
  );

  // Group Chat Services - will be initialized after login with token
  sl.registerLazySingleton<GroupChatService>(
    () => GroupChatService(
      baseUrl: ApiConstants.baseUrl,
      accessToken: TokenService().getAccessToken() as String?,
    ),
  );
  sl.registerLazySingleton<GroupChatWebSocketService>(
    () => GroupChatWebSocketService(
      baseUrl: ApiConstants.websocketUrl,
      accessToken: '', // Will be set after login
    ),
  );

  // BLoCs
  sl.registerFactory<MessagingBloc>(
    () => MessagingBloc(messagingService: sl()),
  );
  sl.registerFactory<MatchingBloc>(
    () => MatchingBloc(matchingService: sl()),
  );
  sl.registerFactory<GroupChatBloc>(
    () => GroupChatBloc(groupChatService: sl(), webSocketService: sl()),
  );

  // Initialize storage
  await sl<HiveStorageService>().initialize();
}
