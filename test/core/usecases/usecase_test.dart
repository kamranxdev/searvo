import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/core/error/failures.dart';

// Mock implementation for testing
class MockUseCase extends UseCase<String, MockParams> {
  final bool shouldSucceed;
  final String successResult;
  final Failure failureResult;

  MockUseCase({
    this.shouldSucceed = true,
    this.successResult = 'success',
    this.failureResult = const ServerFailure(),
  });

  @override
  Future<Either<Failure, String>> call(MockParams params) async {
    if (shouldSucceed) {
      return Right(successResult);
    }
    return Left(failureResult);
  }
}

class MockParams extends UseCaseParams {
  final String value;

  const MockParams({required this.value});

  @override
  List<Object?> get props => [value];
}

class MockNoParamsUseCase extends NoParamsUseCase<String> {
  final bool shouldSucceed;
  final String successResult;

  MockNoParamsUseCase({
    this.shouldSucceed = true,
    this.successResult = 'success',
  });

  @override
  Future<Either<Failure, String>> call() async {
    if (shouldSucceed) {
      return Right(successResult);
    }
    return const Left(ServerFailure());
  }
}

class MockSyncUseCase extends SyncUseCase<String, MockParams> {
  final bool shouldSucceed;

  MockSyncUseCase({this.shouldSucceed = true});

  @override
  Either<Failure, String> call(MockParams params) {
    if (shouldSucceed) {
      return Right(params.value);
    }
    return const Left(ValidationFailure());
  }
}

void main() {
  group('UseCase Tests', () {
    group('UseCase with params', () {
      test('should return Right with success result when call succeeds', () async {
        final useCase = MockUseCase(shouldSucceed: true, successResult: 'test result');
        const params = MockParams(value: 'test');

        final result = await useCase(params);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (success) => expect(success, 'test result'),
        );
      });

      test('should return Left with failure when call fails', () async {
        final useCase = MockUseCase(
          shouldSucceed: false,
          failureResult: const NetworkFailure(),
        );
        const params = MockParams(value: 'test');

        final result = await useCase(params);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (success) => fail('Should not return success'),
        );
      });
    });

    group('NoParamsUseCase', () {
      test('should return Right with success result when call succeeds', () async {
        final useCase = MockNoParamsUseCase(shouldSucceed: true, successResult: 'no params result');

        final result = await useCase();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (success) => expect(success, 'no params result'),
        );
      });

      test('should return Left with failure when call fails', () async {
        final useCase = MockNoParamsUseCase(shouldSucceed: false);

        final result = await useCase();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (success) => fail('Should not return success'),
        );
      });
    });

    group('SyncUseCase', () {
      test('should return Right synchronously when call succeeds', () {
        final useCase = MockSyncUseCase(shouldSucceed: true);
        const params = MockParams(value: 'sync result');

        final result = useCase(params);

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Should not return failure'),
          (success) => expect(success, 'sync result'),
        );
      });

      test('should return Left synchronously when call fails', () {
        final useCase = MockSyncUseCase(shouldSucceed: false);
        const params = MockParams(value: 'test');

        final result = useCase(params);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (success) => fail('Should not return success'),
        );
      });
    });

    group('UseCaseParams', () {
      test('should be equatable', () {
        const params1 = MockParams(value: 'test');
        const params2 = MockParams(value: 'test');
        const params3 = MockParams(value: 'different');

        expect(params1, equals(params2));
        expect(params1, isNot(equals(params3)));
      });
    });

    group('NoParams', () {
      test('should be equatable', () {
        const noParams1 = NoParams();
        const noParams2 = NoParams();

        expect(noParams1, equals(noParams2));
      });

      test('should have empty props', () {
        const noParams = NoParams();
        expect(noParams.props, isEmpty);
      });
    });
  });
}
