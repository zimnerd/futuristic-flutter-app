import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_providers.dart';
import 'blocs/chat_bloc.dart';
import 'blocs/notification_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/hive_storage_service.dart';
import 'data/datasources/local/user_local_data_source.dart';
import 'data/datasources/remote/chat_remote_data_source.dart';
import 'data/datasources/remote/notification_remote_data_source.dart';
import 'data/datasources/remote/user_remote_data_source.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/services/api_service_impl.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/services/api_service.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/theme/pulse_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage
  final hiveStorage = HiveStorageService();
  await hiveStorage.initialize();

  runApp(PulseDatingApp(hiveStorage: hiveStorage));
}

class PulseDatingApp extends StatelessWidget {
  final HiveStorageService hiveStorage;

  const PulseDatingApp({super.key, required this.hiveStorage});

  @override
  Widget build(BuildContext context) {
    return AppProviders(
      child: MultiBlocProvider(
        providers: [
          // Initialize services
          RepositoryProvider<ApiService>(create: (context) => ApiServiceImpl()),
          RepositoryProvider<HiveStorageService>(
            create: (context) => hiveStorage,
          ),

          // Initialize data sources
          RepositoryProvider<UserRemoteDataSource>(
            create: (context) =>
                UserRemoteDataSourceImpl(context.read<ApiService>()),
          ),
          RepositoryProvider<UserLocalDataSource>(
            create: (context) =>
                UserLocalDataSourceImpl(context.read<HiveStorageService>()),
          ),
          RepositoryProvider<ChatRemoteDataSource>(
            create: (context) =>
                ChatRemoteDataSourceImpl(context.read<ApiService>()),
          ),
          RepositoryProvider<NotificationRemoteDataSource>(
            create: (context) =>
                NotificationRemoteDataSourceImpl(context.read<ApiService>()),
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
        ],
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
  }
}
