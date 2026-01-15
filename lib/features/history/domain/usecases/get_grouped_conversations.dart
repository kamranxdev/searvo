import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Use case to get conversations grouped by time category
class GetGroupedConversations extends NoParamsUseCase<Map<String, List<Conversation>>> {
  final ConversationRepository repository;

  GetGroupedConversations(this.repository);

  @override
  Future<Either<Failure, Map<String, List<Conversation>>>> call() async {
    return await repository.getGroupedConversations();
  }
}
