abstract class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const AppException(this.message, [this.stackTrace]);

  @override
  String toString() => 'AppException: $message';
}

// Network exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, [super.stackTrace]);
}

class ServerException extends AppException {
  final int statusCode;

  const ServerException(
    String message,
    this.statusCode, [
    StackTrace? stackTrace,
  ]) : super(message, stackTrace);

  @override
  String toString() => 'ServerException ($statusCode): $message';
}

// Auth exceptions
class AuthException extends AppException {
  const AuthException(super.message, [super.stackTrace]);
}

// Database exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.stackTrace]);
}

// Cache exceptions
class CacheException extends AppException {
  const CacheException(super.message, [super.stackTrace]);
}

// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, [super.stackTrace]);
}

// Sync exceptions
class SyncException extends AppException {
  const SyncException(super.message, [super.stackTrace]);
}

// Format exceptions
class FormatException extends AppException {
  const FormatException(super.message, [super.stackTrace]);
}

// Timeout exceptions
class TimeoutException extends AppException {
  const TimeoutException(super.message, [super.stackTrace]);
}

// System constants specific exceptions
class SystemConstantException extends AppException {
  const SystemConstantException(super.message, [super.stackTrace]);
}

// NotFoundException
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.stackTrace]);
}
