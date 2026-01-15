import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Use case to search conversations
class SearchConversations extends UseCase<List<Conversation>, SearchConversationsParams> {
  final ConversationRepository repository;

  SearchConversations(this.repository);

  @override
  Future<Either<Failure, List<Conversation>>> call(SearchConversationsParams params) async {
    return await repository.searchConversations(params.query);
  }
}

class SearchConversationsParams extends Equatable {
  final String query;

  const SearchConversationsParams({required this.query});

  @override
  List<Object> get props => [query];
}
