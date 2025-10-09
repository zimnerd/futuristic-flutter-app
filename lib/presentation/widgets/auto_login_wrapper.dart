import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/services/auto_login_service.dart';
import '../../core/services/location_tracking_initializer.dart';
import '../../data/services/global_auth_handler.dart';
import '../../services/firebase_notification_service.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/auth/auth_event.dart';
import '../navigation/app_router.dart';

/// Widget that handles automatic login on app startup in development mode
class AutoLoginWrapper extends StatefulWidget {
  final Widget child;

  const AutoLoginWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AutoLoginWrapper> createState() => _AutoLoginWrapperState();
}

class _AutoLoginWrapperState extends State<AutoLoginWrapper> {
  final Logger _logger = Logger();
  final LocationTrackingInitializer _locationTracker =
      LocationTrackingInitializer();
  bool _autoLoginAttempted = false;
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    
    // Register global auth logout callback
    GlobalAuthHandler.instance.registerLogoutCallback(() {
      _logger.w('🚨 Global auth failure - triggering logout');
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    });
    
    // Set up global notification listener for in-app popups
    _setupNotificationListener();
    
    // Attempt auto-login after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoLoginIfNeeded();
    });
  }

  void _attemptAutoLoginIfNeeded() {
    // Only attempt auto-login once and when conditions are right
    if (_autoLoginAttempted || !AutoLoginService.shouldAutoLogin) {
      return;
    }

    _autoLoginAttempted = true;

    final authState = context.read<AuthBloc>().state;
    
    // Only auto-login if not already authenticated and not in a loading state
    if (authState is! AuthAuthenticated && authState is! AuthLoading) {
      _logger.i('🤖 Triggering auto-login on app startup');
      AutoLoginService.attemptAutoLogin(context);
    } else {
      _logger.d('🚫 Skipping auto-login - user already authenticated or loading');
    }
  }

  /// Set up global notification listener for in-app message popups
  void _setupNotificationListener() {
    _notificationSubscription = FirebaseNotificationService
        .instance
        .onNotification
        .listen(
          (notification) {
            _logger.i(
              '📱 Showing in-app notification popup: ${notification['title']}',
            );

            // Show SnackBar for in-app message notification
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${notification['title']}: ${notification['body']}',
                  ),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      // Navigate to messages screen when user taps "View"
                      _navigateToMessages(notification['data']);
                    },
                  ),
                ),
              );
            }
          },
          onError: (error) {
            _logger.e('❌ Error in notification stream: $error');
          },
        );
  }

  /// Navigate to messages screen when notification is tapped
  void _navigateToMessages(Map<String, dynamic> messageData) {
    // Extract conversation ID from notification data if available
    final conversationId = messageData['conversationId'];

    if (conversationId != null) {
      // Navigate to specific conversation
      _logger.i('📱 Navigating to conversation: $conversationId');
      // TODO: Implement navigation to specific conversation
      // For now, just navigate to messages tab
    }

    // Navigate to messages screen using GoRouter
    try {
      AppRouter.router.go(AppRoutes.messages);
      _logger.i('📱 Successfully navigated to messages screen');
    } catch (e) {
      _logger.e('❌ Failed to navigate to messages screen: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        // Listen for auth state changes to provide feedback
        if (state is AuthAuthenticated) {
          final user = AutoLoginService.defaultUser;
          if (user != null) {
            _logger.i('✅ 🤖 Auto-login successful for ${user.name}');
          }

          // Initialize location tracking after successful authentication
          // Use addPostFrameCallback to ensure context is ready for dialogs
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            _logger.i(
              '📍 Initializing location tracking after successful login...',
            );

            // Add a small delay to ensure UI is fully rendered
            await Future.delayed(const Duration(milliseconds: 500));

            if (!context.mounted) {
              _logger.w(
                '⚠️ Context not mounted, skipping location initialization',
              );
              return;
            }

            _logger.i(
              '📍 Context is mounted, proceeding with location initialization',
            );

            final locationInitialized = await _locationTracker
                .initializeWithDialogs(context);
            if (locationInitialized) {
              _logger.i('✅ 📍 Location tracking started (1km threshold)');
            } else {
              _logger.w(
                '⚠️ 📍 Location tracking failed to start - user may have denied permission',
              );
            }
          });
        } else if (state is AuthError) {
          // Handle specific error types with appropriate logging
          final errorCode = state.errorCode;

          if (errorCode == 'USER_NOT_REGISTERED') {
            _logger.i(
              '⚠️ Auto-login skipped: Test user not registered in database',
            );
            _logger.i(
              'ℹ️  Please register the user or use a different test account',
            );
          } else if (state.message.toLowerCase().contains('register first')) {
            _logger.i(
              '⚠️ Auto-login skipped: User registration required',
            );
          } else {
            _logger.w('❌ 🤖 Auto-login failed: ${state.message}');
          }
        } else if (state is AuthUnauthenticated) {
          _logger.d('📍 Auth state: Unauthenticated');
          // Stop location tracking on logout
          _logger.i('📍 Stopping location tracking after logout...');
          await _locationTracker.stop();
        } else {
          _logger.d('📍 Auth state: ${state.runtimeType}');
        }
      },
      child: widget.child,
    );
  }
}