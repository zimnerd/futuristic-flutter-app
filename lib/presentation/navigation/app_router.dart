import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart' as simple_login;
import '../screens/auth/enhanced_login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main/home_screen.dart';
import '../screens/main/matches_screen.dart';
import '../screens/main/messages_screen.dart';
import '../screens/main/profile_screen.dart';
import '../screens/main/settings_screen.dart';
import '../screens/main/filters_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/subscription_management_screen.dart';
// Advanced feature screens
import '../screens/virtual_gifts/virtual_gifts_screen.dart';
import '../screens/premium/premium_screen.dart';
import '../screens/safety/safety_screen.dart';
import '../screens/ai_companion/ai_companion_screen.dart';
import '../screens/speed_dating/speed_dating_screen.dart';
import '../screens/live_streaming/live_streaming_screen.dart';
import '../screens/date_planning/date_planning_screen.dart';
import '../screens/voice_messages/voice_messages_screen.dart';
import '../screens/profile/profile_creation_screen.dart';
import '../screens/call/video_call_screen.dart';
import '../screens/discovery/discovery_screen.dart';
import '../screens/features/advanced_features_screen.dart';
import '../../../domain/entities/user_profile.dart';

/// Application routes configuration using GoRouter
/// Provides type-safe navigation with route guards and transitions
class AppRouter {
  static final GoRouter _router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    initialLocation: AppRoutes.welcome,
    redirect: _handleRedirect,
    routes: [
      // Onboarding routes
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Authentication routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const simple_login.LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.enhancedLogin,
        name: 'enhanced-login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app routes with shell navigation
      ShellRoute(
        builder: (context, state, child) => MainNavigationWrapper(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.matches,
            name: 'matches',
            builder: (context, state) => const MatchesScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
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
            path: AppRoutes.subscription,
            name: 'subscription',
            builder: (context, state) => const SubscriptionManagementScreen(),
          ),
        ],
      ),
      
      // Advanced feature routes (full screen, not in bottom nav)
      GoRoute(
        path: AppRoutes.discovery,
        name: 'discovery',
        builder: (context, state) => const DiscoveryScreen(),
      ),
      GoRoute(
        path: AppRoutes.advancedFeatures,
        name: 'advancedFeatures',
        builder: (context, state) => const AdvancedFeaturesScreen(),
      ),
      GoRoute(
        path: AppRoutes.virtualGifts,
        name: 'virtualGifts',
        builder: (context, state) {
          final recipientId = state.uri.queryParameters['recipientId'];
          final recipientName = state.uri.queryParameters['recipientName'];
          return VirtualGiftsScreen(
            recipientId: recipientId,
            recipientName: recipientName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.premium,
        name: 'premium',
        builder: (context, state) => const PremiumScreen(),
      ),
      GoRoute(
        path: AppRoutes.safety,
        name: 'safety',
        builder: (context, state) => const SafetyScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiCompanion,
        name: 'aiCompanion',
        builder: (context, state) => const AiCompanionScreen(),
      ),
      GoRoute(
        path: AppRoutes.speedDating,
        name: 'speedDating',
        builder: (context, state) => const SpeedDatingScreen(),
      ),
      GoRoute(
        path: AppRoutes.liveStreaming,
        name: 'liveStreaming',
        builder: (context, state) => const LiveStreamingScreen(),
      ),
      GoRoute(
        path: AppRoutes.datePlanning,
        name: 'datePlanning',
        builder: (context, state) => const DatePlanningScreen(),
      ),
      GoRoute(
        path: AppRoutes.voiceMessages,
        name: 'voiceMessages',
        builder: (context, state) => const VoiceMessagesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileCreation,
        name: 'profileCreation',
        builder: (context, state) => const ProfileCreationScreen(),
      ),
      GoRoute(
        path: AppRoutes.videoCall,
        name: 'videoCall',
        builder: (context, state) {
          // Extract user data from route extra or use current call state
          final callId = state.pathParameters['callId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final remoteUser =
              extra?['remoteUser'] as UserProfile? ??
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

          return VideoCallScreen(callId: callId, remoteUser: remoteUser,
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

  static GoRouter get router => _router;

  /// Handle route redirects based on authentication state
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authBloc = context.read<AuthBloc>();
    final isAuthenticated = authBloc.isAuthenticated;
    final isLoading = authBloc.isLoading;

    final isAuthRoute =
        state.fullPath?.startsWith('/auth') == true ||
        state.fullPath == AppRoutes.login ||
        state.fullPath == AppRoutes.register ||
        state.fullPath == AppRoutes.enhancedLogin ||
        state.fullPath == AppRoutes.forgotPassword;

    final isWelcomeRoute =
        state.fullPath == AppRoutes.welcome ||
        state.fullPath == AppRoutes.onboarding;

    // Don't redirect while authentication is loading
    if (isLoading) {
      return null;
    }

    // If user is authenticated and trying to access auth/welcome routes,
    // redirect to home
    if (isAuthenticated && (isAuthRoute || isWelcomeRoute)) {
      return AppRoutes.home;
    }

    // If user is not authenticated and trying to access protected routes,
    // redirect to welcome screen
    if (!isAuthenticated && !isAuthRoute && !isWelcomeRoute) {
      return AppRoutes.welcome;
    }

    // Allow the navigation
    return null;
  }
}

/// Route path constants
class AppRoutes {
  static const String welcome = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String enhancedLogin = '/auth/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String filters = '/filters';
  static const String subscription = '/subscription';
  
  // Advanced feature routes
  static const String discovery = '/discovery';
  static const String advancedFeatures = '/advanced-features';
  static const String virtualGifts = '/virtual-gifts';
  static const String premium = '/premium';
  static const String safety = '/safety';
  static const String aiCompanion = '/ai-companion';
  static const String speedDating = '/speed-dating';
  static const String liveStreaming = '/live-streaming';
  static const String datePlanning = '/date-planning';
  static const String voiceMessages = '/voice-messages';
  static const String profileCreation = '/profile-creation';
  static const String videoCall = '/video-call/:callId';
}

/// Main navigation wrapper with bottom navigation bar
class MainNavigationWrapper extends StatelessWidget {
  const MainNavigationWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}

/// Bottom navigation bar for main app sections
class MainBottomNavigation extends StatelessWidget {
  const MainBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getSelectedIndex(location),
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Matches',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Messages',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case AppRoutes.home:
        return 0;
      case AppRoutes.matches:
        return 1;
      case AppRoutes.messages:
        return 2;
      case AppRoutes.profile:
        return 3;
      default:
        return 0;
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.matches);
        break;
      case 2:
        context.go(AppRoutes.messages);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }
}
