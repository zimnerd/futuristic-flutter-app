import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../core/services/auto_login_service.dart';
import '../../core/services/location_tracking_initializer.dart';
import '../../data/services/global_auth_handler.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/auth/auth_event.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Register global auth logout callback
    GlobalAuthHandler.instance.registerLogoutCallback(() {
      _logger.w('🚨 Global auth failure - triggering logout');
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    });
    
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
          _logger.i(
            '📍 Initializing location tracking after successful login...',
          );
          final locationInitialized = await _locationTracker.initialize();
          if (locationInitialized) {
            _logger.i('✅ 📍 Location tracking started (1km threshold)');
          } else {
            _logger.w(
              '⚠️ 📍 Location tracking failed to start - user may have denied permission',
            );
          }
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
          // Stop location tracking on logout
          _logger.i('📍 Stopping location tracking after logout...');
          await _locationTracker.stop();
        }
      },
      child: widget.child,
    );
  }
}