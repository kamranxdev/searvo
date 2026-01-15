import 'package:dartz/dartz.dart';

/// Extension methods for Either type to make it easier to work with
extension EitherExtensions<L, R> on Either<L, R> {
  /// Get the right value (success)
  /// Throws if this is a Left
  R getRight() => (this as Right<L, R>).value;
  
  /// Get the left value (failure)
  /// Throws if this is a Right
  L getLeft() => (this as Left<L, R>).value;
  
  /// Check if this is a Right (success)
  bool get isRight => this is Right<L, R>;
  
  /// Check if this is a Left (failure)
  bool get isLeft => this is Left<L, R>;
  
  /// Transform the right value
  Either<L, T> map<T>(T Function(R r) f) {
    return fold(
      (l) => Left(l),
      (r) => Right(f(r)),
    );
  }
  
  /// FlatMap - chain operations that return Either
  Either<L, T> flatMap<T>(Either<L, T> Function(R r) f) {
    return fold(
      (l) => Left(l),
      (r) => f(r),
    );
  }
  
  /// Get right value or return a default
  R getOrElse(R Function() defaultValue) {
    return fold(
      (_) => defaultValue(),
      (r) => r,
    );
  }
}
