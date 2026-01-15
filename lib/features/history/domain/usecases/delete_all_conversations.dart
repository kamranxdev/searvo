import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import '../repositories/conversation_repository.dart';

class DeleteAllConversations implements UseCase<Unit, NoParams> {
  final ConversationRepository repository;

  DeleteAllConversations(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) async {
    return await repository.clearAllConversations();
  }
}
