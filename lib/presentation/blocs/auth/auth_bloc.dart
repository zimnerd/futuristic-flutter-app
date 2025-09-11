import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/exceptions/app_exceptions.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/repositories/user_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC responsible for managing authentication state and operations
///
/// Handles user sign in, sign up, sign out, and authentication status checking.
/// Works with UserRepository to perform authentication operations and manages
/// the authentication state throughout the app lifecycle.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required UserRepository userRepository, Logger? logger})
    : _userRepository = userRepository,
      _logger = logger ?? Logger(),
      super(const AuthInitial()) {
    // Register event handlers
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthTokenRefreshRequested>(_onTokenRefreshRequested);
    on<AuthErrorCleared>(_onErrorCleared);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<AuthTwoFactorVerifyRequested>(_onTwoFactorVerifyRequested);
    on<AuthBiometricSignInRequested>(_onBiometricSignInRequested);

    // Check authentication status when BLoC is created
    add(const AuthStatusChecked());
  }

  final UserRepository _userRepository;
  final Logger _logger;

  /// Checks current authentication status
  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('🔍 Checking authentication status...');
      emit(const AuthLoading());

      final user = await _userRepository.getCurrentUser();

      if (user != null) {
        _logger.i('✅ User is authenticated: ${user.username}');
        emit(AuthAuthenticated(user: user));
      } else {
        _logger.i('❌ User is not authenticated');
        emit(const AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error checking auth status',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        AuthError(
          message: e is AppException
              ? e.message
              : 'Failed to check authentication status',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Handles user sign in with email and password
  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('🔐 Attempting sign in for: ${event.email}');
      emit(const AuthLoading());

      final user = await _userRepository.signInWithEmailPassword(
        event.email,
        event.password,
      );

      if (user != null) {
        _logger.i('✅ Sign in successful: ${user.username}');
        emit(AuthAuthenticated(user: user));
      } else {
        _logger.w('❌ Sign in failed: Invalid credentials');
        emit(
          const AuthError(
            message: 'Invalid email or password',
            errorCode: 'INVALID_CREDENTIALS',
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('💥 Sign in error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Sign in failed',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Handles user sign up with email, password, username, and phone
  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('📝 Attempting sign up for: ${event.email}');
      emit(const AuthLoading());

      final user = await _userRepository.signUpWithEmailPassword(
        event.email,
        event.password,
        event.username,
        event.phone,
        firstName: event.firstName,
        lastName: event.lastName,
        birthdate: event.birthdate,
        gender: event.gender,
        location: event.location,
      );

      if (user != null) {
        _logger.i('✅ Sign up successful: ${user.username}');
        emit(
          AuthRegistrationSuccess(
            user: user,
            message: 'Account created successfully! Please verify your email.',
          ),
        );
      } else {
        _logger.w('❌ Sign up failed');
        emit(
          const AuthError(
            message: 'Failed to create account',
            errorCode: 'SIGNUP_FAILED',
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('💥 Sign up error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Sign up failed',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Handles user sign out
  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('🚪 Signing out user...');
      emit(const AuthLoading());

      await _userRepository.signOut();

      _logger.i('✅ Sign out successful');
      emit(const AuthUnauthenticated());
    } catch (e, stackTrace) {
      _logger.e('💥 Sign out error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Sign out failed',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Handles authentication token refresh
  Future<void> _onTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('🔄 Refreshing authentication token...');

      // Note: Token refresh logic would typically be handled by the repository
      // This is a placeholder for when the backend implements refresh tokens
      final user = await _userRepository.getCurrentUser();

      if (user != null) {
        _logger.i('✅ Token refresh successful');
        emit(AuthAuthenticated(user: user));
      } else {
        _logger.w('❌ Token refresh failed - user not found');
        emit(const AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      _logger.e('💥 Token refresh error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Token refresh failed',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Clears authentication errors
  void _onErrorCleared(AuthErrorCleared event, Emitter<AuthState> emit) {
    _logger.i('🧹 Clearing authentication error');
    emit(const AuthUnauthenticated());
  }

  /// Handles password reset request
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('🔐 Requesting password reset for: ${event.email}');
      emit(const AuthLoading());

      await _userRepository.requestPasswordReset(event.email);

      _logger.i('✅ Password reset email sent successfully');
      emit(
        const AuthPasswordResetEmailSent(
          message:
              'Password reset link sent to your email address. Please check your inbox.',
        ),
      );
    } on AppException catch (e) {
      _logger.e('❌ Password reset failed: ${e.message}');
      emit(AuthFailure(message: e.message, errorCode: e.code));
    } catch (e) {
      _logger.e('❌ Unexpected error during password reset: $e');
      emit(
        const AuthFailure(
          message: 'Failed to send password reset email. Please try again.',
          errorCode: 'password_reset_error',
        ),
      );
    }
  }

  /// Handles two-factor authentication verification
  Future<void> _onTwoFactorVerifyRequested(
    AuthTwoFactorVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      _logger.i('Verifying two-factor authentication code');

      final user = await _userRepository.verifyTwoFactor(
        sessionId: event.sessionId,
        code: event.code,
      );

      if (user != null) {
        emit(AuthAuthenticated(user: user));
        _logger.i('Two-factor authentication verified successfully');
      } else {
        emit(const AuthError(message: 'Two-factor verification failed'));
      }
    } on AppException catch (e) {
      _logger.e('Two-factor verification failed: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      const message =
          'An unexpected error occurred during two-factor verification';
      _logger.e('Two-factor verification error: $e');
      emit(const AuthError(message: message));
    }
  }

  /// Handles biometric authentication sign-in
  Future<void> _onBiometricSignInRequested(
    AuthBiometricSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      _logger.i('Attempting biometric authentication');

      final user = await _userRepository.signInWithBiometric();

      if (user != null) {
        emit(AuthAuthenticated(user: user));
        _logger.i('Biometric authentication successful');
      } else {
        emit(const AuthError(message: 'Biometric authentication failed'));
      }
    } on AppException catch (e) {
      _logger.e('Biometric authentication failed: ${e.message}');
      emit(AuthError(message: e.message));
    } catch (e) {
      const message =
          'An unexpected error occurred during biometric authentication';
      _logger.e('Biometric authentication error: $e');
      emit(const AuthError(message: message));
    }
  }

  /// Gets the current authenticated user, if any
  UserModel? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    }
    return null;
  }

  /// Checks if user is currently authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  /// Checks if authentication is currently loading
  bool get isLoading => state is AuthLoading;

  /// Gets the current error message, if any
  String? get errorMessage {
    final currentState = state;
    if (currentState is AuthError) {
      return currentState.message;
    }
    return null;
  }
}
