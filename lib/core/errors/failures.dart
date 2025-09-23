import 'package:equatable/equatable.dart';
import 'package:savvy_stock/core/errors/exceptions.dart';

abstract class Failure extends Equatable {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  @override
  List<Object?> get props => [message, stackTrace];

  @override
  String toString() => 'Failure: $message';
}

// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);
}

class ServerFailure extends Failure {
  final int statusCode;

  const ServerFailure(String message, this.statusCode, [StackTrace? stackTrace])
    : super(message, stackTrace);

  @override
  List<Object?> get props => [message, statusCode, stackTrace];
}

// Auth failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.stackTrace]);
}

// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.stackTrace]);
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.stackTrace]);
}

// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.stackTrace]);
}

// Sync failures
class SyncFailure extends Failure {
  const SyncFailure(super.message, [super.stackTrace]);
}

// Generic failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [super.stackTrace]);
}

// System constants specific failures
class SystemConstantFailure extends Failure {
  const SystemConstantFailure(super.message, [super.stackTrace]);
}

// Mapping function to convert exceptions to failures
Failure mapExceptionToFailure(Exception exception) {
  if (exception is NetworkException) {
    return NetworkFailure(exception.message, exception.stackTrace);
  } else if (exception is ServerException) {
    return ServerFailure(
      exception.message,
      exception.statusCode,
      exception.stackTrace,
    );
  } else if (exception is AuthException) {
    return AuthFailure(exception.message, exception.stackTrace);
  } else if (exception is DatabaseException) {
    return DatabaseFailure(exception.message, exception.stackTrace);
  } else if (exception is CacheException) {
    return CacheFailure(exception.message, exception.stackTrace);
  } else if (exception is ValidationException) {
    return ValidationFailure(exception.message, exception.stackTrace);
  } else if (exception is SyncException) {
    return SyncFailure(exception.message, exception.stackTrace);
  } else {
    return UnexpectedFailure(exception.toString());
  }
}
