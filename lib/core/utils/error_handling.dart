import 'dart:developer' as developer;

/// Error handling utilities with retry logic
class ErrorHandling {
  /// Executes a function with error handling and retry logic
  static Future<T> withErrorHandling<T>(
    Future<T> Function() operation,
    String operationType, {
    RetryHandler? retryHandler,
    T Function()? fallback,
    int maxRetries = 3,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        developer.log(
          'Error in $operationType (attempt $attempts/$maxRetries): ${e.toString()}',
          name: 'ErrorHandling',
          level: attempts == maxRetries ? 1000 : 800, // ERROR : WARNING
        );

        // Check if we should retry
        if (attempts < maxRetries && (retryHandler?.shouldRetry(lastException, attempts) ?? true)) {
          // Wait before retrying with exponential backoff
          final delay = Duration(milliseconds: 100 * attempts * attempts);
          await Future.delayed(delay);
          continue;
        }
        
        break;
      }
    }

    // If we have a fallback, use it
    if (fallback != null) {
      developer.log(
        'Using fallback for $operationType after $attempts failed attempts',
        name: 'ErrorHandling',
        level: 900, // INFO
      );
      return fallback();
    }

    // Re-throw the last exception
    throw lastException!;
  }
}

/// Retry handler interface
abstract class RetryHandler {
  bool shouldRetry(Exception exception, int attemptNumber);
}

/// Predefined retry handlers
class RetryHandlers {
  /// API retry handler - retries on network/timeout errors
  static final RetryHandler api = ApiRetryHandler();
  
  /// Network retry handler - retries on connection errors  
  static final RetryHandler network = NetworkRetryHandler();
}

/// API-specific retry handler
class ApiRetryHandler implements RetryHandler {
  @override
  bool shouldRetry(Exception exception, int attemptNumber) {
    final message = exception.toString().toLowerCase();
    
    // Don't retry on client errors (4xx)
    if (message.contains('400') || message.contains('401') || 
        message.contains('403') || message.contains('404')) {
      return false;
    }
    
    // Retry on server errors (5xx) and timeouts
    return message.contains('500') || 
           message.contains('502') || 
           message.contains('503') || 
           message.contains('504') ||
           message.contains('timeout') ||
           message.contains('connection');
  }
}

/// Network-specific retry handler
class NetworkRetryHandler implements RetryHandler {
  @override
  bool shouldRetry(Exception exception, int attemptNumber) {
    final message = exception.toString().toLowerCase();
    
    return message.contains('socket') ||
           message.contains('connection') ||
           message.contains('timeout') ||
           message.contains('network');
  }
}