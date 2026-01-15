import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/auth/domain/entities/user.dart';
import 'package:searvo/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser extends NoParamsUseCase<User?> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, User?>> call() async {
    return await repository.getCurrentUser();
  }
}
