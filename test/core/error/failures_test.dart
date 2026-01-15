import 'package:flutter_test/flutter_test.dart';
import 'package:searvo/core/error/failures.dart';

void main() {
  group('Failure Tests', () {
    group('ServerFailure', () {
      test('should create ServerFailure with default message', () {
        const failure = ServerFailure();
        expect(failure.message, 'A server error occurred. Please try again later.');
        expect(failure.code, isNull);
      });

      test('should create ServerFailure with custom message and code', () {
        const failure = ServerFailure('Custom server error', 500);
        expect(failure.message, 'Custom server error');
        expect(failure.code, 500);
      });

      test('should be equal when properties match', () {
        const failure1 = ServerFailure('Error', 500);
        const failure2 = ServerFailure('Error', 500);
        expect(failure1, equals(failure2));
      });

      test('should have correct toString output', () {
        const failure = ServerFailure('Test error');
        expect(failure.toString(), 'Test error');
      });
    });

    group('NetworkFailure', () {
      test('should create NetworkFailure with default message', () {
        const failure = NetworkFailure();
        expect(failure.message, 'Network connection failed. Please check your internet connection.');
      });

      test('should create NetworkFailure with custom message', () {
        const failure = NetworkFailure('Custom network error');
        expect(failure.message, 'Custom network error');
      });
    });

    group('CacheFailure', () {
      test('should create CacheFailure with default message', () {
        const failure = CacheFailure();
        expect(failure.message, 'Failed to access local cache.');
      });

      test('should create CacheFailure with custom message', () {
        const failure = CacheFailure('Cache not found');
        expect(failure.message, 'Cache not found');
      });
    });

    group('ValidationFailure', () {
      test('should create ValidationFailure with default message', () {
        const failure = ValidationFailure();
        expect(failure.message, 'Validation failed.');
      });

      test('should create ValidationFailure with custom message', () {
        const failure = ValidationFailure('Invalid input');
        expect(failure.message, 'Invalid input');
      });
    });

    group('AuthFailure', () {
      test('should create AuthFailure with default message', () {
        const failure = AuthFailure();
        expect(failure.message, 'Authentication failed.');
      });

      test('should create AuthFailure with custom message', () {
        const failure = AuthFailure('Invalid credentials');
        expect(failure.message, 'Invalid credentials');
      });
    });

    group('ApiFailure', () {
      test('should create ApiFailure with message and status code', () {
        const failure = ApiFailure('API error', 404);
        expect(failure.message, 'API error');
        expect(failure.code, 404);
      });

      test('should create ApiFailure with only message', () {
        const failure = ApiFailure('API error');
        expect(failure.message, 'API error');
        expect(failure.code, isNull);
      });
    });

    group('TimeoutFailure', () {
      test('should create TimeoutFailure with default message', () {
        const failure = TimeoutFailure();
        expect(failure.message, 'The request timed out. Please try again.');
      });
    });

    group('ParseFailure', () {
      test('should create ParseFailure with default message', () {
        const failure = ParseFailure();
        expect(failure.message, 'Failed to parse data.');
      });
    });

    group('UnauthorizedFailure', () {
      test('should create UnauthorizedFailure with default message', () {
        const failure = UnauthorizedFailure();
        expect(failure.message, 'You are not authorized to perform this action.');
      });
    });

    group('NotFoundFailure', () {
      test('should create NotFoundFailure with default message', () {
        const failure = NotFoundFailure();
        expect(failure.message, 'The requested resource was not found.');
      });
    });

    group('Equatable props', () {
      test('should include all properties in props list', () {
        const failure = ServerFailure('Error', 500);
        expect(failure.props, contains('Error'));
        expect(failure.props, contains(500));
      });

      test('different failures should not be equal', () {
        const serverFailure = ServerFailure('Error');
        const networkFailure = NetworkFailure('Error');
        expect(serverFailure, isNot(equals(networkFailure)));
      });
    });
  });
}
