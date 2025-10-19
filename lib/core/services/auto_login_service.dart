import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../config/test_credentials.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';
import '../../presentation/blocs/auth/auth_state.dart';

/// Service responsible for handling session validation and automatic login in development mode
class AutoLoginService {
  static final Logger _logger = Logger();

  /// Attempts session validation first, then auto-login if needed in development
  static Future<void> attemptAutoLogin(BuildContext context) async {
    try {
      _logger.i('🔍 Starting session validation on app startup');

      // First, always check authentication status (validates stored session)
      if (!context.mounted) return;
      context.read<AuthBloc>().add(const AuthStatusChecked());

      // Wait a moment to see if session validation succeeds
      await Future.delayed(const Duration(milliseconds: 500));

      // Check current auth state after validation attempt
      if (!context.mounted) return;
      final authState = context.read<AuthBloc>().state;

      if (authState is AuthAuthenticated) {
        _logger.i(
          '✅ Session validation successful - user already authenticated',
        );
        return;
      }

      // If session validation failed and we're in development mode, try auto-login
      if (TestCredentials.isDevelopmentMode) {
        _logger.i(
          '🤖 Session validation failed - attempting auto-login for development',
        );

        final testUser = TestCredentials.getByRole('USER');

        if (testUser == null) {
          _logger.w('❌ No test user found for auto-login');
          return;
        }

        _logger.i('🔐 Auto-logging in as: ${testUser.email}');

        // Trigger auto-login event
        if (!context.mounted) return;
        context.read<AuthBloc>().add(
          AuthAutoLoginRequested(
            email: testUser.email,
            password: testUser.password,
          ),
        );

        _logger.i('✅ Auto-login request sent for ${testUser.name}');
      } else {
        _logger.i('🚫 Auto-login disabled - not in development mode');
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Auto-login service error',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Checks if auto-login should be enabled (only for development builds with failed session validation)
  static bool get shouldAutoLogin {
    return TestCredentials.isDevelopmentMode;
  }

  /// Gets the default test user for auto-login
  static TestAccount? get defaultUser {
    return TestCredentials.getByRole('USER');
  }
}
