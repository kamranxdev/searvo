import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Use case to delete a conversation
class DeleteConversation extends UseCase<Unit, DeleteConversationParams> {
  final ConversationRepository repository;

  DeleteConversation(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteConversationParams params) async {
    return await repository.deleteConversation(params.conversationId);
  }
}

class DeleteConversationParams extends Equatable {
  final String conversationId;

  const DeleteConversationParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
