import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_providers.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/hive_storage_service.dart';
import 'data/services/api_service_impl.dart';
import 'data/datasources/remote/user_remote_data_source.dart';
import 'data/datasources/local/user_local_data_source.dart';
import 'data/repositories/user_repository_impl.dart';
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

          // Initialize repositories with complete implementation
          RepositoryProvider<UserRepository>(
            create: (context) => UserRepositoryImpl(
              context.read<UserRemoteDataSource>(),
              context.read<UserLocalDataSource>(),
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
