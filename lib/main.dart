import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/storage/hive_storage_service.dart';
// Temporary mock repository for development
import 'data/models/user_model.dart';
import 'domain/repositories/user_repository.dart';
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
        // Initialize repositories with mock implementation for now
        RepositoryProvider<UserRepository>(
          create: (context) => MockUserRepository(),
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

/// Temporary mock repository implementation for development
class MockUserRepository implements UserRepository {
  @override
  Future<UserModel?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    // TODO: Implement mock authentication
    return null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return null;
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    return null;
  }

  @override
  Future<void> signOut() async {
    // Mock implementation
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // For any unimplemented method, return appropriate defaults
    final returnType = invocation.memberName.toString();
    if (returnType.contains('Future')) {
      if (returnType.contains('List')) {
        return Future.value(<dynamic>[]);
      }
      if (returnType.contains('UserModel')) {
        return Future.value(null);
      }
      return Future.value();
    }
    if (returnType.contains('Stream')) {
      return Stream.empty();
    }
    return super.noSuchMethod(invocation);
  }
}
