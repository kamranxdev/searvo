import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
/// Used in conjunction with Dartz Either for functional error handling
abstract class Failure extends Equatable {
  final String message;
  final int? code;
  final StackTrace? stackTrace;
  
  const Failure(this.message, {this.code, this.stackTrace});

  @override
  List<Object?> get props => [message, code, stackTrace];

  @override
  String toString() => message;
}

/// Server-related failures (5xx errors)
class ServerFailure extends Failure {
  const ServerFailure([
    String message = 'A server error occurred. Please try again later.',
    int? code,
    StackTrace? stackTrace,
  ]) : super(message, code: code, stackTrace: stackTrace);
}

/// Network-related failures (connection issues)
class NetworkFailure extends Failure {
  const NetworkFailure([
    String message = 'Network connection failed. Please check your internet connection.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure([
    String message = 'Failed to access local cache.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Validation failures (4xx errors)
class ValidationFailure extends Failure {
  const ValidationFailure([
    String message = 'Validation failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure([
    String message = 'Authentication failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// General API failures with status code
class ApiFailure extends Failure {
  const ApiFailure(
    String message, [
    int? statusCode,
    StackTrace? stackTrace,
  ]) : super(message, code: statusCode, stackTrace: stackTrace);
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure([
    String message = 'The request timed out. Please try again.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Parse/Format failures
class ParseFailure extends Failure {
  const ParseFailure([
    String message = 'Failed to parse data.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Unauthorized access
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    String message = 'You are not authorized to perform this action.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Resource not found
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    String message = 'The requested resource was not found.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

/// Unknown error
class UnknownFailure extends Failure {
  const UnknownFailure([
    String message = 'An unknown error occurred.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

// ===============================================
// Feature-specific failures
// ===============================================

class LLMFailure extends Failure {
  const LLMFailure([
    String message = 'LLM processing failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

class SearchFailure extends Failure {
  const SearchFailure([
    String message = 'Search failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

class RAGFailure extends Failure {
  const RAGFailure([
    String message = 'RAG processing failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

class VoiceFailure extends Failure {
  const VoiceFailure([
    String message = 'Voice processing failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}

class StorageFailure extends Failure {
  const StorageFailure([
    String message = 'Storage operation failed.',
    StackTrace? stackTrace,
  ]) : super(message, stackTrace: stackTrace);
}
