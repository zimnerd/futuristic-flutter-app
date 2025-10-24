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
/// [forceRefresh] if true, forces a fresh fetch from API instead of using cache
final class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
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
    this.email,
    required this.type,
    this.phoneNumber,
    this.countryCode,
    this.preferredMethod,
  });

  final String? email;
  final String
  type; // 'login', 'registration', 'password_reset', 'phone_verification'
  final String? phoneNumber;
  final String? countryCode;
  final String? preferredMethod; // 'email', 'whatsapp', 'both'

  @override
  List<Object?> get props => [
    email,
    type,
    phoneNumber,
    countryCode,
    preferredMethod,
  ];
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

/// Event triggered for automatic login in development mode
final class AuthAutoLoginRequested extends AuthEvent {
  const AuthAutoLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event triggered when phone number validation is requested
final class AuthPhoneValidationRequested extends AuthEvent {
  const AuthPhoneValidationRequested({
    required this.phone,
    required this.countryCode,
  });

  final String phone;
  final String countryCode;

  @override
  List<Object?> get props => [phone, countryCode];
}

/// Event triggered when Google sign-in is requested
final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Event triggered when Apple sign-in is requested
final class AuthAppleSignInRequested extends AuthEvent {
  const AuthAppleSignInRequested();
}

/// Event triggered when Facebook sign-in is requested
final class AuthFacebookSignInRequested extends AuthEvent {
  const AuthFacebookSignInRequested();
}

/// Event triggered when account linking verification is requested
final class AuthLinkAccountRequested extends AuthEvent {
  const AuthLinkAccountRequested({
    required this.provider,
    required this.verificationCode,
  });

  final String provider;
  final String verificationCode;

  @override
  List<Object?> get props => [provider, verificationCode];
}
