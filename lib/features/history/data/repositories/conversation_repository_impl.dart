import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/history/data/datasources/conversation_local_datasource.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';

/// Implementation of ConversationRepository
/// Handles error mapping from data layer exceptions to domain failures
class ConversationRepositoryImpl implements ConversationRepository {
  final ConversationLocalDataSource localDataSource;

  ConversationRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Conversation>>> getAllConversations() async {
    try {
      final conversationDTOs = await localDataSource.getAllConversations();
      final conversations = conversationDTOs.map((dto) => dto.toEntity()).toList();
      return Right(conversations);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, List<Conversation>>>> getGroupedConversations() async {
    try {
      final groupedDTOs = await localDataSource.getGroupedConversations();
      final grouped = groupedDTOs.map((key, value) => MapEntry(
            key,
            value.map((dto) => dto.toEntity()).toList(),
          ));
      return Right(grouped);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getConversationById(String conversationId) async {
    try {
      final conversationDTO = await localDataSource.getConversationById(conversationId);
      return Right(conversationDTO.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> searchConversations(String query) async {
    try {
      final conversationDTOs = await localDataSource.searchConversations(query);
      final conversations = conversationDTOs.map((dto) => dto.toEntity()).toList();
      return Right(conversations);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Conversation>> saveConversation({
    required String conversationId,
    required String title,
    required List<dynamic> messageBranches,
    List<String> tags = const [],
  }) async {
    try {
      final conversationDTO = await localDataSource.saveConversation(
        conversationId: conversationId,
        title: title,
        messageBranches: messageBranches,
        tags: tags,
      );
      return Right(conversationDTO.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Conversation>> updateConversation({
    required String conversationId,
    String? title,
    List<dynamic>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  }) async {
    try {
      final conversationDTO = await localDataSource.updateConversation(
        conversationId: conversationId,
        title: title,
        messageBranches: messageBranches,
        isPinned: isPinned,
        tags: tags,
      );
      return Right(conversationDTO.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteConversation(String conversationId) async {
    try {
      await localDataSource.deleteConversation(conversationId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> togglePin(String conversationId) async {
    try {
      await localDataSource.togglePin(conversationId);
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Unit>> clearAllConversations() async {
    try {
      await localDataSource.clearAllConversations();
      return const Right(unit);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getPinnedConversations() async {
    try {
      final conversationDTOs = await localDataSource.getPinnedConversations();
      final conversations = conversationDTOs.map((dto) => dto.toEntity()).toList();
      return Right(conversations);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
