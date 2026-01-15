import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/auth/domain/repositories/auth_repository.dart';

class SignOut extends NoParamsUseCase<Unit> {
  final AuthRepository repository;

  SignOut(this.repository);

  @override
  Future<Either<Failure, Unit>> call() async {
    return await repository.signOut();
  }
}
