import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Use case to toggle pin status of a conversation
class TogglePinConversation extends UseCase<Unit, TogglePinConversationParams> {
  final ConversationRepository repository;

  TogglePinConversation(this.repository);

  @override
  Future<Either<Failure, Unit>> call(TogglePinConversationParams params) async {
    return await repository.togglePin(params.conversationId);
  }
}

class TogglePinConversationParams extends Equatable {
  final String conversationId;

  const TogglePinConversationParams({required this.conversationId});

  @override
  List<Object> get props => [conversationId];
}
