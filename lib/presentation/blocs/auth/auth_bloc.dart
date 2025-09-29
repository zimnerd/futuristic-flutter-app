import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/exceptions/app_exceptions.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/token_service.dart';
import '../../../data/services/websocket_service_impl.dart';
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
    on<AuthOTPSendRequested>(_onOTPSendRequested);
    on<AuthOTPVerifyRequested>(_onOTPVerifyRequested);
    on<AuthOTPResendRequested>(_onOTPResendRequested);
    on<AuthAutoLoginRequested>(_onAutoLoginRequested);
    on<AuthPhoneValidationRequested>(_onPhoneValidationRequested);

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
        
        // Initialize real-time services after successful authentication
        await _initializeRealTimeServices(user);
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
        
        // Initialize real-time services after successful authentication
        await _initializeRealTimeServices(user);
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

  /// Handles automatic login for development mode
  Future<void> _onAutoLoginRequested(
    AuthAutoLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('🔐 🤖 Auto-login for development: ${event.email}');
      emit(const AuthLoading());

      final user = await _userRepository.signInWithEmailPassword(
        event.email,
        event.password,
      );

      if (user != null) {
        _logger.i('✅ 🤖 Auto-login successful: ${user.username}');
        emit(AuthAuthenticated(user: user));
        
        // Initialize real-time services after successful authentication
        await _initializeRealTimeServices(user);
      } else {
        _logger.w('❌ 🤖 Auto-login failed: Invalid credentials');
        emit(
          const AuthError(
            message: 'Auto-login failed: Invalid credentials',
            errorCode: 'AUTO_LOGIN_FAILED',
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('💥 🤖 Auto-login error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Auto-login failed',
          errorCode: e is AppException ? e.code : 'AUTO_LOGIN_ERROR',
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

  /// Handles OTP send request
  Future<void> _onOTPSendRequested(
    AuthOTPSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('Sending OTP to: ${event.email}, type: ${event.type}');
      emit(const AuthLoading());

      final result = await _userRepository.sendOTP(
        email: event.email,
        phoneNumber: event.phoneNumber,
        type: event.type,
        preferredMethod: event.preferredMethod,
      );

      emit(
        AuthOTPSent(
          sessionId: result['sessionId'],
          deliveryMethods: List<String>.from(result['deliveryMethods'] ?? []),
          expiresAt: result['expiresAt'],
          message: 'OTP sent successfully',
        ),
      );

      _logger.i('OTP sent successfully');
    } catch (e, stackTrace) {
      _logger.e('Send OTP error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Failed to send OTP',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Handles OTP verification request
  Future<void> _onOTPVerifyRequested(
    AuthOTPVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('Verifying OTP for session: ${event.sessionId}');
      emit(const AuthLoading());

      final result = await _userRepository.verifyOTP(
        sessionId: event.sessionId,
        code: event.code,
        email: event.email,
      );

      if (result['verified'] == true) {
        // Successful verification
        final userData = result['user'];
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          emit(AuthAuthenticated(user: user));
          _logger.i('OTP verification successful: ${user.username}');
        } else {
          emit(
            const AuthError(
              message: 'Verification successful but user data not found',
            ),
          );
        }
      } else {
        // Failed verification
        final attemptsRemaining = result['attemptsRemaining'] ?? 0;
        emit(
          AuthOTPVerificationFailed(
            message: 'Invalid OTP code. Please try again.',
            attemptsRemaining: attemptsRemaining,
            sessionId: event.sessionId,
          ),
        );
        _logger.w(
          'OTP verification failed, attempts remaining: $attemptsRemaining',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Verify OTP error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Failed to verify OTP',
          errorCode: e is AppException ? e.code : null,
        ),
      );
    }
  }

  /// Handles OTP resend request
  Future<void> _onOTPResendRequested(
    AuthOTPResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('Resending OTP for session: ${event.sessionId}');
      emit(const AuthLoading());

      final result = await _userRepository.resendOTP(
        sessionId: event.sessionId,
      );

      emit(
        AuthOTPSent(
          sessionId: result['sessionId'],
          deliveryMethods: List<String>.from(result['deliveryMethods'] ?? []),
          expiresAt: result['expiresAt'],
          message: 'OTP resent successfully',
        ),
      );

      _logger.i('OTP resent successfully');
    } catch (e, stackTrace) {
      _logger.e('Resend OTP error', error: e, stackTrace: stackTrace);
      emit(
        AuthError(
          message: e is AppException ? e.message : 'Failed to resend OTP',
          errorCode: e is AppException ? e.code : null,
        ),
      );
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

  /// Handles phone number validation request
  Future<void> _onPhoneValidationRequested(
    AuthPhoneValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      _logger.i('📱 Validating phone number: ${event.phone} with country code: ${event.countryCode}');
      emit(const AuthPhoneValidating());

      final response = await _userRepository.validatePhone(
        phone: event.phone,
        countryCode: event.countryCode,
      );

      if (response['isValid'] == true) {
        _logger.i('✅ Phone validation successful');
        emit(AuthPhoneValidationSuccess(
          formattedPhone: response['formattedPhone'] ?? event.phone,
          isValid: true,
          message: response['message'],
        ));
      } else {
        _logger.w('❌ Phone validation failed: ${response['message']}');
        emit(AuthPhoneValidationError(
          message: response['message'] ?? 'Invalid phone number',
          errorCode: response['errorCode'] ?? 'INVALID_PHONE',
        ));
      }
    } catch (e, stackTrace) {
      _logger.e(
        '💥 Error validating phone number',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        AuthPhoneValidationError(
          message: e is AppException
              ? e.message
              : 'Failed to validate phone number',
          errorCode: e is AppException ? (e.code ?? 'VALIDATION_ERROR') : 'VALIDATION_ERROR',
        ),
      );
    }
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

  /// Initialize real-time services after successful authentication
  Future<void> _initializeRealTimeServices(UserModel user) async {
    try {
      _logger.i('🔗 Initializing real-time services for user: ${user.id}');

      // Get auth token from storage for WebSocket authentication
      final tokenService = TokenService();
      final authToken = await tokenService.getAccessToken();

      if (authToken != null) {
        // Initialize WebSocket service with user credentials
        final webSocketService = WebSocketServiceImpl.instance;
        webSocketService.setAuthToken(authToken);
        await webSocketService.connect();
        _logger.i('✅ WebSocket service initialized successfully');
      } else {
        _logger.w('⚠️ No auth token available for real-time services');
      }
    } catch (e) {
      _logger.e('💥 Failed to initialize real-time services: $e');
      // Don't throw error as this is not critical for basic app functionality
    }
  }
}
