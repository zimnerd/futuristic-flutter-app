/// Custom exceptions for data layer error handling
/// These exceptions are mapped to failures in the repository layer
library;

/// Base class for all data exceptions
abstract class DataException implements Exception {
  const DataException([this.message]);
  
  final String? message;
}

/// Exception thrown when the server returns an error
class ServerException extends DataException {
  const ServerException([super.message]);
}

/// Exception thrown when there's no internet connection
class NetworkException extends DataException {
  const NetworkException([super.message]);
}

/// Exception thrown when cache operations fail
class CacheException extends DataException {
  const CacheException([super.message]);
}

/// Exception thrown when authentication fails
class AuthException extends DataException {
  const AuthException([super.message]);
}

/// Exception thrown when validation fails
class ValidationException extends DataException {
  const ValidationException([super.message]);
}

/// Exception thrown when location services fail
class LocationException extends DataException {
  const LocationException([super.message]);
}

/// Exception thrown when permission is denied
class PermissionException extends DataException {
  const PermissionException([super.message]);
}

/// Exception thrown when parsing fails
class ParseException extends DataException {
  const ParseException([super.message]);
}

/// Exception thrown when a resource is not found
class NotFoundException extends DataException {
  const NotFoundException([super.message]);
}
