import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Use case for getting a specific conversation by ID
class GetConversationById implements UseCase<Conversation, String> {
  final ConversationRepository repository;

  GetConversationById(this.repository);

  @override
  Future<Either<Failure, Conversation>> call(String conversationId) async {
    return await repository.getConversationById(conversationId);
  }
}
