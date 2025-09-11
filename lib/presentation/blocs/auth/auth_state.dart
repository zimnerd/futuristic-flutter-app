import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';

/// Base class for all authentication states
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the app starts
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication operation is in progress
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is successfully authenticated
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final UserModel user;

  @override
  List<Object?> get props => [user];
}

/// State when user is not authenticated
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// State when authentication fails
final class AuthError extends AuthState {
  const AuthError({required this.message, this.errorCode});

  final String message;
  final String? errorCode;

  @override
  List<Object?> get props => [message, errorCode];
}

/// Alias for AuthError to maintain compatibility
final class AuthFailure extends AuthError {
  const AuthFailure({required super.message, super.errorCode});

  // Additional getter for error property
  String get error => message;
}

/// State when two-factor authentication is required
final class AuthTwoFactorRequired extends AuthState {
  const AuthTwoFactorRequired({required this.sessionId, this.message});

  final String sessionId;
  final String? message;

  @override
  List<Object?> get props => [sessionId, message];
}

/// State when user account is created successfully but needs verification
final class AuthRegistrationSuccess extends AuthState {
  const AuthRegistrationSuccess({required this.user, required this.message});

  final UserModel user;
  final String message;

  @override
  List<Object?> get props => [user, message];
}

/// State when password reset email is sent successfully
final class AuthPasswordResetEmailSent extends AuthState {
  const AuthPasswordResetEmailSent({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
