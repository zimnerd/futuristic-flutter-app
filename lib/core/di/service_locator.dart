import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../data/services/messaging_service.dart';
import '../../data/services/matching_service.dart';
import '../../presentation/blocs/messaging/messaging_bloc.dart';
import '../../presentation/blocs/matching/matching_bloc.dart';

/// Service locator for dependency injection
final GetIt sl = GetIt.instance;

/// Initialize dependencies
Future<void> initializeDependencies() async {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Services
  sl.registerLazySingleton<MessagingService>(
    () => MessagingService(apiClient: sl()),
  );
  sl.registerLazySingleton<MatchingService>(
    () => MatchingService(apiClient: sl()),
  );

  // BLoCs
  sl.registerFactory<MessagingBloc>(
    () => MessagingBloc(messagingService: sl()),
  );
  sl.registerFactory<MatchingBloc>(
    () => MatchingBloc(matchingService: sl()),
  );
}
