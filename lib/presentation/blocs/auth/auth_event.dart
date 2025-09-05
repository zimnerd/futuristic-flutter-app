import 'package:equatable/equatable.dart';

/// Base class for all authentication events
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when user attempts to sign in with email and password
final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event triggered when user attempts to sign up with email and password
final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.username,
  });

  final String email;
  final String password;
  final String username;

  @override
  List<Object?> get props => [email, password, username];
}

/// Event triggered when user requests to sign out
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event triggered when app starts to check if user is already authenticated
final class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

/// Event triggered when user authentication token needs to be refreshed
final class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

/// Event triggered when authentication error needs to be cleared
final class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
