/// Base exception class for all app-specific exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

/// Authentication related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(super.message, {super.code, super.originalError});
}

class LoginException extends AuthenticationException {
  const LoginException(super.message, {super.code, super.originalError});
}

class RegistrationException extends AuthenticationException {
  const RegistrationException(super.message, {super.code, super.originalError});
}

class SessionExpiredException extends AuthenticationException {
  const SessionExpiredException(super.message, {super.code, super.originalError});
}

/// Location related exceptions
class LocationException extends AppException {
  const LocationException(super.message, {super.code, super.originalError});
}

class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException(super.message, {super.code, super.originalError});
}

class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException(super.message, {super.code, super.originalError});
}

class LocationTimeoutException extends LocationException {
  const LocationTimeoutException(super.message, {super.code, super.originalError});
}

/// Attendance related exceptions
class AttendanceException extends AppException {
  const AttendanceException(super.message, {super.code, super.originalError});
}

class CheckInException extends AttendanceException {
  const CheckInException(super.message, {super.code, super.originalError});
}

class CheckOutException extends AttendanceException {
  const CheckOutException(super.message, {super.code, super.originalError});
}

class GeofenceViolationException extends AttendanceException {
  const GeofenceViolationException(super.message, {super.code, super.originalError});
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class ConnectionTimeoutException extends NetworkException {
  const ConnectionTimeoutException(super.message, {super.code, super.originalError});
}

class ServerException extends NetworkException {
  const ServerException(super.message, {super.code, super.originalError});
}

/// Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class DataNotFoundException extends DatabaseException {
  const DataNotFoundException(super.message, {super.code, super.originalError});
}

class DataValidationException extends DatabaseException {
  const DataValidationException(super.message, {super.code, super.originalError});
}

/// Camera related exceptions
class CameraException extends AppException {
  const CameraException(super.message, {super.code, super.originalError});
}

class CameraPermissionDeniedException extends CameraException {
  const CameraPermissionDeniedException(super.message, {super.code, super.originalError});
}

/// Generic exceptions
class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}
