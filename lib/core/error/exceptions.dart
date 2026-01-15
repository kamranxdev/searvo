/// Base exception class for all exceptions in the data layer
abstract class AppException implements Exception {
  final String message;
  final int? code;
  
  const AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Server exception (5xx errors)
class ServerException extends AppException {
  const ServerException([String message = 'Server error', int? code]) : super(message, code);
}

/// Network exception (connection issues)
class NetworkException extends AppException {
  const NetworkException([String message = 'Network error', int? code]) : super(message, code);
}

/// Cache exception
class CacheException extends AppException {
  const CacheException([String message = 'Cache error', int? code]) : super(message, code);
}

/// Validation exception (4xx errors)
class ValidationException extends AppException {
  const ValidationException([String message = 'Validation error', int? code]) : super(message, code);
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException([String message = 'Authentication error', int? code]) : super(message, code);
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException([String message = 'Request timeout', int? code]) : super(message, code);
}

/// Parse exception
class ParseException extends AppException {
  const ParseException([String message = 'Parse error', int? code]) : super(message, code);
}

/// Not found exception (404 errors)
class NotFoundException extends AppException {
  const NotFoundException([String message = 'Resource not found', int? code]) : super(message, code);
}
