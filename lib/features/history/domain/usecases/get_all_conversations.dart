import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Use case to get all conversations
class GetAllConversations extends NoParamsUseCase<List<Conversation>> {
  final ConversationRepository repository;

  GetAllConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call() async {
    return await repository.getAllConversations();
  }
}
