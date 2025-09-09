import 'package:equatable/equatable.dart';

/// Abstract base class for all failures in the application
abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => [];
}

/// Failure when the server cannot be reached or returns an error
class ServerFailure extends Failure {
  const ServerFailure({this.message});

  final String? message;

  @override
  List<Object> get props => [message ?? ''];
}

/// Failure when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Failure when authentication fails
class AuthFailure extends Failure {
  const AuthFailure({this.message});

  final String? message;

  @override
  List<Object> get props => [message ?? ''];
}

/// Failure when cached data is not available
class CacheFailure extends Failure {
  const CacheFailure();
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// Failure when permission is denied
class PermissionFailure extends Failure {
  const PermissionFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// Failure when location services fail
class LocationFailure extends Failure {
  const LocationFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}

/// General application failure
class GeneralFailure extends Failure {
  const GeneralFailure({required this.message});

  final String message;

  @override
  List<Object> get props => [message];
}
