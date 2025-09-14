import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../config/test_credentials.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/auth/auth_event.dart';

/// Service responsible for handling automatic login in development mode
class AutoLoginService {
  static final Logger _logger = Logger();

  /// Triggers auto-login for development if enabled
  static Future<void> attemptAutoLogin(BuildContext context) async {
    // Only enable auto-login in development mode
    if (!TestCredentials.isDevelopmentMode) {
      _logger.d('🚫 Auto-login disabled - not in development mode');
      return;
    }

    try {
      _logger.i('🤖 Auto-login enabled - attempting login with test user');
      
      // Use the regular user account for auto-login
      final testUser = TestCredentials.getByRole('USER');
      
      if (testUser == null) {
        _logger.w('❌ No test user found for auto-login');
        return;
      }

      _logger.i('🔐 Auto-logging in as: ${testUser.email}');

      // Trigger auto-login event
      context.read<AuthBloc>().add(
        AuthAutoLoginRequested(
          email: testUser.email,
          password: testUser.password,
        ),
      );

      _logger.i('✅ Auto-login request sent for ${testUser.name}');
    } catch (e, stackTrace) {
      _logger.e('💥 Auto-login service error', error: e, stackTrace: stackTrace);
    }
  }

  /// Checks if auto-login should be enabled
  static bool get shouldAutoLogin {
    return TestCredentials.isDevelopmentMode;
  }

  /// Gets the default test user for auto-login
  static TestAccount? get defaultUser {
    return TestCredentials.getByRole('USER');
  }
}