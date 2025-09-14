/// Base exception class for all custom exceptions in the app
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

/// API-related exceptions
class ApiException extends NetworkException {
  const ApiException(super.message, {super.code, super.details});
}

class NoInternetException extends NetworkException {
  const NoInternetException() : super('No internet connection available');
}

class TimeoutException extends NetworkException {
  const TimeoutException() : super('Request timeout');
}

class ServerException extends NetworkException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.details,
  });
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.details});
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException() : super('Unauthorized access');
}

class TokenExpiredException extends AuthException {
  const TokenExpiredException() : super('Authentication token has expired');
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException() : super('Invalid email or password');
}

/// User-related exceptions
class UserException extends AppException {
  const UserException(super.message, {super.code, super.details});
}

class UserNotFoundException extends UserException {
  const UserNotFoundException() : super('User not found');
}

class ProfileIncompleteException extends UserException {
  const ProfileIncompleteException() : super('Profile is incomplete');
}

class UserBlockedException extends UserException {
  const UserBlockedException() : super('User has been blocked');
}

/// Matching-related exceptions
class MatchException extends AppException {
  const MatchException(super.message, {super.code, super.details});
}

class NoMoreMatchesException extends MatchException {
  const NoMoreMatchesException() : super('No more potential matches available');
}

class MatchNotFoundException extends MatchException {
  const MatchNotFoundException() : super('Match not found');
}

class AlreadyMatchedException extends MatchException {
  const AlreadyMatchedException() : super('Users are already matched');
}

/// Messaging-related exceptions
class MessageException extends AppException {
  const MessageException(super.message, {super.code, super.details});
}

class ConversationNotFoundException extends MessageException {
  const ConversationNotFoundException() : super('Conversation not found');
}

class MessageNotFoundException extends MessageException {
  const MessageNotFoundException() : super('Message not found');
}

class MessageSendFailedException extends MessageException {
  const MessageSendFailedException() : super('Failed to send message');
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.details});
}

class CacheException extends StorageException {
  const CacheException(super.message, {super.code, super.details});
}

class DatabaseException extends StorageException {
  const DatabaseException(super.message, {super.code, super.details});
}

/// Media-related exceptions
class MediaException extends AppException {
  const MediaException(super.message, {super.code, super.details});
}

class FileNotFoundException extends MediaException {
  const FileNotFoundException() : super('File not found');
}

class UnsupportedFileTypeException extends MediaException {
  const UnsupportedFileTypeException() : super('Unsupported file type');
}

class FileTooLargeException extends MediaException {
  const FileTooLargeException() : super('File size exceeds limit');
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.details});
}

class LocationPermissionException extends PermissionException {
  const LocationPermissionException() : super('Location permission required');
}

class CameraPermissionException extends PermissionException {
  const CameraPermissionException() : super('Camera permission required');
}

class MicrophonePermissionException extends PermissionException {
  const MicrophonePermissionException()
    : super('Microphone permission required');
}

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}

class InvalidEmailException extends ValidationException {
  const InvalidEmailException() : super('Invalid email format');
}

class InvalidPhoneException extends ValidationException {
  const InvalidPhoneException() : super('Invalid phone number format');
}

class PasswordTooWeakException extends ValidationException {
  const PasswordTooWeakException()
    : super('Password does not meet requirements');
}

/// Subscription-related exceptions
class SubscriptionException extends AppException {
  const SubscriptionException(super.message, {super.code, super.details});
}

class InsufficientCreditsException extends SubscriptionException {
  const InsufficientCreditsException()
    : super('Insufficient credits for this action');
}

class SubscriptionExpiredException extends SubscriptionException {
  const SubscriptionExpiredException() : super('Subscription has expired');
}

/// Generic exception for unhandled cases
class GenericException extends AppException {
  const GenericException(super.message, {super.code, super.details});
}

/// Utility function to convert error codes to exceptions
AppException createExceptionFromCode(
  String code,
  String message, {
  dynamic details,
}) {
  switch (code) {
    case 'NETWORK_ERROR':
      return NetworkException(message, details: details);
    case 'NO_INTERNET':
      return const NoInternetException();
    case 'TIMEOUT':
      return const TimeoutException();
    case 'UNAUTHORIZED':
      return const UnauthorizedException();
    case 'TOKEN_EXPIRED':
      return const TokenExpiredException();
    case 'INVALID_CREDENTIALS':
      return const InvalidCredentialsException();
    case 'USER_NOT_FOUND':
      return const UserNotFoundException();
    case 'USER_BLOCKED':
      return const UserBlockedException();
    case 'NO_MORE_MATCHES':
      return const NoMoreMatchesException();
    case 'MATCH_NOT_FOUND':
      return const MatchNotFoundException();
    case 'CONVERSATION_NOT_FOUND':
      return const ConversationNotFoundException();
    case 'MESSAGE_SEND_FAILED':
      return const MessageSendFailedException();
    case 'FILE_NOT_FOUND':
      return const FileNotFoundException();
    case 'UNSUPPORTED_FILE_TYPE':
      return const UnsupportedFileTypeException();
    case 'FILE_TOO_LARGE':
      return const FileTooLargeException();
    case 'LOCATION_PERMISSION_REQUIRED':
      return const LocationPermissionException();
    case 'CAMERA_PERMISSION_REQUIRED':
      return const CameraPermissionException();
    case 'INVALID_EMAIL':
      return const InvalidEmailException();
    case 'INVALID_PHONE':
      return const InvalidPhoneException();
    case 'PASSWORD_TOO_WEAK':
      return const PasswordTooWeakException();
    case 'INSUFFICIENT_CREDITS':
      return const InsufficientCreditsException();
    case 'SUBSCRIPTION_EXPIRED':
      return const SubscriptionExpiredException();
    default:
      return GenericException(message, code: code, details: details);
  }
}
