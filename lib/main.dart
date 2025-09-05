import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/storage/hive_storage_service.dart';
import 'data/datasources/remote/user_remote_data_source_impl.dart';
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
  await HiveStorageService().initialize();

  runApp(const PulseDatingApp());
}

class PulseDatingApp extends StatelessWidget {
  const PulseDatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Initialize services
        RepositoryProvider<ApiService>(create: (context) => ApiServiceImpl()),

        // Initialize repositories with real implementation
        RepositoryProvider<UserRepository>(
          create: (context) {
            final apiService = context.read<ApiService>();
            final remoteDataSource = UserRemoteDataSourceImpl(
              apiService: apiService,
            );
            // TODO: Initialize local data source when implemented
            return UserRepositoryImpl(
              remoteDataSource: remoteDataSource,
              localDataSource:
                  remoteDataSource as dynamic, // Temporary: use remote as local
            );
          },
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
    );
  }
}
