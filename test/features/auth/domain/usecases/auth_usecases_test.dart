import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/auth/domain/entities/user.dart';
import 'package:searvo/features/auth/domain/repositories/auth_repository.dart';
import 'package:searvo/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:searvo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:searvo/features/auth/domain/usecases/sign_out.dart';
import 'package:searvo/features/auth/domain/usecases/get_current_user.dart';

// Mock implementation of AuthRepository
class MockAuthRepository implements AuthRepository {
  bool shouldSucceed = true;
  User? mockUser;
  Failure mockFailure = const AuthFailure();

  @override
  Stream<User?> get authStateChanges => Stream.value(mockUser);

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    if (shouldSucceed) {
      return Right(mockUser);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldSucceed && mockUser != null) {
      return Right(mockUser!);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (shouldSucceed && mockUser != null) {
      return Right(mockUser!);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    if (shouldSucceed && mockUser != null) {
      return Right(mockUser!);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    if (shouldSucceed) {
      return const Right(unit);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    if (shouldSucceed) {
      return const Right(unit);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    if (shouldSucceed && mockUser != null) {
      return Right(mockUser!);
    }
    return Left(mockFailure);
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() async {
    if (shouldSucceed) {
      return const Right(unit);
    }
    return Left(mockFailure);
  }

  @override
  bool get isAuthenticated => mockUser != null;
}

void main() {
  late MockAuthRepository mockRepository;

  const testUser = User(
    uid: 'test-uid-123',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    mockRepository.mockUser = testUser;
    mockRepository.shouldSucceed = true;
  });

  group('SignInWithEmail UseCase Tests', () {
    late SignInWithEmail useCase;

    setUp(() {
      useCase = SignInWithEmail(mockRepository);
    });

    test('should return User when sign in is successful', () async {
      const params = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password123',
      );

      final result = await useCase(params);

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (user) {
          expect(user.uid, testUser.uid);
          expect(user.email, testUser.email);
        },
      );
    });

    test('should return AuthFailure when sign in fails', () async {
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure = const AuthFailure('Invalid credentials');

      const params = SignInWithEmailParams(
        email: 'wrong@example.com',
        password: 'wrongpassword',
      );

      final result = await useCase(params);

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (user) => fail('Should not return user'),
      );
    });

    test('SignInWithEmailParams should be equatable', () {
      const params1 = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password',
      );
      const params2 = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password',
      );
      const params3 = SignInWithEmailParams(
        email: 'different@example.com',
        password: 'password',
      );

      expect(params1, equals(params2));
      expect(params1, isNot(equals(params3)));
    });

    test('SignInWithEmailParams props should include email and password', () {
      const params = SignInWithEmailParams(
        email: 'test@example.com',
        password: 'password',
      );

      expect(params.props, contains('test@example.com'));
      expect(params.props, contains('password'));
    });
  });

  group('SignInWithGoogle UseCase Tests', () {
    late SignInWithGoogle useCase;

    setUp(() {
      useCase = SignInWithGoogle(mockRepository);
    });

    test('should return User when Google sign in is successful', () async {
      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (user) {
          expect(user.uid, testUser.uid);
          expect(user.email, testUser.email);
        },
      );
    });

    test('should return AuthFailure when Google sign in fails', () async {
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure = const AuthFailure('Google sign in cancelled');

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (user) => fail('Should not return user'),
      );
    });
  });

  group('SignOut UseCase Tests', () {
    late SignOut useCase;

    setUp(() {
      useCase = SignOut(mockRepository);
    });

    test('should return unit when sign out is successful', () async {
      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (success) => expect(success, unit),
      );
    });

    test('should return AuthFailure when sign out fails', () async {
      mockRepository.shouldSucceed = false;
      mockRepository.mockFailure = const AuthFailure('Sign out failed');

      final result = await useCase();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (success) => fail('Should not return success'),
      );
    });
  });

  group('GetCurrentUser UseCase Tests', () {
    late GetCurrentUser useCase;

    setUp(() {
      useCase = GetCurrentUser(mockRepository);
    });

    test('should return User when user is logged in', () async {
      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (user) {
          expect(user, isNotNull);
          expect(user!.uid, testUser.uid);
        },
      );
    });

    test('should return null User when no user is logged in', () async {
      mockRepository.mockUser = null;

      final result = await useCase();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not return failure'),
        (user) => expect(user, isNull),
      );
    });

    test('should return failure when getting current user fails', () async {
      mockRepository.shouldSucceed = false;

      final result = await useCase();

      expect(result.isLeft(), isTrue);
    });
  });

  group('AuthRepository Tests', () {
    test('authStateChanges should emit user', () async {
      final emissions = await mockRepository.authStateChanges.toList();
      expect(emissions, [testUser]);
    });

    test('isAuthenticated should return true when user exists', () {
      expect(mockRepository.isAuthenticated, isTrue);
    });

    test('isAuthenticated should return false when no user', () {
      mockRepository.mockUser = null;
      expect(mockRepository.isAuthenticated, isFalse);
    });
  });
}
