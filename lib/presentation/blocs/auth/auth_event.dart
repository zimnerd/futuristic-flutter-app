import 'package:equatable/equatable.dart';

/// Base class for all authentication events
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when user attempts to sign in with email and password
final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
    this.trustDevice = false,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final bool trustDevice;

  @override
  List<Object?> get props => [email, password, rememberMe, trustDevice];
}

/// Event triggered when user attempts to sign up with email and password
final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.username,
    required this.phone,
    this.firstName,
    this.lastName,
    this.birthdate,
    this.gender,
    this.location,
  });

  final String email;
  final String password;
  final String username;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? birthdate;
  final String? gender;
  final String? location;

  @override
  List<Object?> get props => [
    email,
    password,
    username,
    phone,
    firstName,
    lastName,
    birthdate,
    gender,
    location,
  ];
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

/// Event triggered when 2FA verification is requested
final class AuthTwoFactorVerifyRequested extends AuthEvent {
  const AuthTwoFactorVerifyRequested({
    required this.sessionId,
    required this.code,
  });

  final String sessionId;
  final String code;

  @override
  List<Object?> get props => [sessionId, code];
}

/// Event triggered when biometric sign in is requested
final class AuthBiometricSignInRequested extends AuthEvent {
  const AuthBiometricSignInRequested();
}

/// Event triggered when password reset is requested
final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Event triggered when OTP is requested
final class AuthOTPSendRequested extends AuthEvent {
  const AuthOTPSendRequested({
    required this.email,
    required this.type,
    this.phoneNumber,
    this.preferredMethod,
  });

  final String email;
  final String
  type; // 'login', 'registration', 'password_reset', 'phone_verification'
  final String? phoneNumber;
  final String? preferredMethod; // 'email', 'whatsapp', 'both'

  @override
  List<Object?> get props => [email, type, phoneNumber, preferredMethod];
}

/// Event triggered when OTP verification is requested
final class AuthOTPVerifyRequested extends AuthEvent {
  const AuthOTPVerifyRequested({
    required this.sessionId,
    required this.code,
    required this.email,
  });

  final String sessionId;
  final String code;
  final String email;

  @override
  List<Object?> get props => [sessionId, code, email];
}

/// Event triggered when OTP resend is requested
final class AuthOTPResendRequested extends AuthEvent {
  const AuthOTPResendRequested({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}
