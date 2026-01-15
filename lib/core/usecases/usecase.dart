import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:searvo/core/error/failures.dart';

/// Base class for all use cases in the application
/// Type: The return type of the use case
/// Params: The parameters passed to the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require any parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Use case for synchronous operations
abstract class SyncUseCase<Type, Params> {
  Either<Failure, Type> call(Params params);
}

/// Base class for use case parameters
/// Extend this for type-safe parameters that can be compared
abstract class UseCaseParams extends Equatable {
  const UseCaseParams();
}

/// Use case with no parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
