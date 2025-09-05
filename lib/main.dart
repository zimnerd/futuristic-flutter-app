import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/constants/app_constants.dart';
// import 'package:hive_flutter/hive_flutter.dart';

// Core imports
import 'core/theme/app_theme.dart';
// import 'core/storage/hive_storage_service.dart';

// import 'presentation/pages/splash/splash_page.dart';
// import 'presentation/blocs/app/app_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local storage
  // await HiveStorageService().initialize();

  runApp(const PulseDatingApp());
}

class PulseDatingApp extends StatelessWidget {
  const PulseDatingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: PulseTheme.lightTheme,
      darkTheme: PulseTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

// Temporary home page until we implement proper navigation
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 80, color: PulseColors.primary),
            SizedBox(height: 24),
            Text('Pulse Dating App', style: PulseTextStyles.headlineMedium),
            SizedBox(height: 16),
            Text(
              'Modern dating with offline-first architecture',
              style: PulseTextStyles.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Text('🚧 Under Development 🚧', style: PulseTextStyles.titleMedium),
            SizedBox(height: 16),
            Text(
              'Phase 1: Foundation & Architecture in progress...',
              style: PulseTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
