import 'dart:developer' as developer;

/// Performance tracking utilities
class Performance {
  /// Tracks async operations and logs performance metrics
  static Future<T> trackAsync<T>(
    String operationName,
    Future<T> Function() operation, [
    Map<String, dynamic>? metadata,
  ]) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      
      stopwatch.stop();
      developer.log(
        'Operation $operationName completed in ${stopwatch.elapsedMilliseconds}ms',
        name: 'Performance',
        level: 800, // INFO level
      );
      
      if (metadata != null) {
        developer.log(
          'Operation metadata: $metadata',
          name: 'Performance',
          level: 700, // DEBUG level
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        'Operation $operationName failed after ${stopwatch.elapsedMilliseconds}ms: ${e.toString()}',
        name: 'Performance',
        level: 1000, // ERROR level
      );
      
      rethrow;
    }
  }

  /// Tracks synchronous operations
  static T trackSync<T>(
    String operationName,
    T Function() operation, [
    Map<String, dynamic>? metadata,
  ]) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      
      stopwatch.stop();
      developer.log(
        'Sync operation $operationName completed in ${stopwatch.elapsedMicroseconds}μs',
        name: 'Performance',
        level: 800, // INFO level
      );
      
      if (metadata != null) {
        developer.log(
          'Operation metadata: $metadata',
          name: 'Performance',
          level: 700, // DEBUG level
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      developer.log(
        'Sync operation $operationName failed after ${stopwatch.elapsedMicroseconds}μs: ${e.toString()}',
        name: 'Performance',
        level: 1000, // ERROR level
      );
      
      rethrow;
    }
  }

  /// Logs a simple performance marker
  static void mark(String name, [Map<String, dynamic>? metadata]) {
    developer.log(
      'Performance marker: $name',
      name: 'Performance',
      level: 800, // INFO level
    );
    
    if (metadata != null) {
      developer.log(
        'Marker metadata: $metadata',
        name: 'Performance',
        level: 700, // DEBUG level
      );
    }
  }
}