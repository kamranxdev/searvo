import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';

/// Repository interface for conversation history
/// Defines contract for data operations without implementation details
abstract class ConversationRepository {
  /// Get all conversations
  Future<Either<Failure, List<Conversation>>> getAllConversations();

  /// Get conversations grouped by time category
  Future<Either<Failure, Map<String, List<Conversation>>>> getGroupedConversations();

  /// Get a specific conversation by ID
  Future<Either<Failure, Conversation>> getConversationById(String conversationId);

  /// Search conversations by query
  Future<Either<Failure, List<Conversation>>> searchConversations(String query);

  /// Save a new conversation
  Future<Either<Failure, Conversation>> saveConversation({
    required String conversationId,
    required String title,
    required List<dynamic> messageBranches,
    List<String> tags,
  });

  /// Update an existing conversation
  Future<Either<Failure, Conversation>> updateConversation({
    required String conversationId,
    String? title,
    List<dynamic>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  });

  /// Delete a conversation
  Future<Either<Failure, Unit>> deleteConversation(String conversationId);

  /// Pin/unpin a conversation
  Future<Either<Failure, Unit>> togglePin(String conversationId);

  /// Clear all conversations
  Future<Either<Failure, Unit>> clearAllConversations();

  /// Get pinned conversations
  Future<Either<Failure, List<Conversation>>> getPinnedConversations();
}
