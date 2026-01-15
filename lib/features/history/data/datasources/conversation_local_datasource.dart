import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/features/history/data/models/conversation_dto.dart';
import 'package:searvo/features/history/services/conversation_database_service.dart';

/// Local data source for conversations using Drift database
abstract class ConversationLocalDataSource {
  Future<List<ConversationDTO>> getAllConversations();
  Future<Map<String, List<ConversationDTO>>> getGroupedConversations();
  Future<ConversationDTO> getConversationById(String conversationId);
  Future<List<ConversationDTO>> searchConversations(String query);
  Future<ConversationDTO> saveConversation({
    required String conversationId,
    required String title,
    required List<dynamic> messageBranches,
    List<String> tags,
  });
  Future<ConversationDTO> updateConversation({
    required String conversationId,
    String? title,
    List<dynamic>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  });
  Future<void> deleteConversation(String conversationId);
  Future<void> togglePin(String conversationId);
  Future<void> clearAllConversations();
  Future<List<ConversationDTO>> getPinnedConversations();
}

class ConversationLocalDataSourceImpl implements ConversationLocalDataSource {
  final ConversationDatabaseService databaseService;

  ConversationLocalDataSourceImpl({required this.databaseService});

  @override
  Future<List<ConversationDTO>> getAllConversations() async {
    try {
      final conversations = await databaseService.getAllConversations();
      return conversations.map((c) => ConversationDTO.fromModel(c)).toList();
    } catch (e) {
      throw CacheException('Failed to get all conversations: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, List<ConversationDTO>>> getGroupedConversations() async {
    try {
      final grouped = await databaseService.getGroupedConversations();
      return grouped.map((key, value) => MapEntry(
            key,
            value.map((c) => ConversationDTO.fromModel(c)).toList(),
          ));
    } catch (e) {
      throw CacheException('Failed to get grouped conversations: ${e.toString()}');
    }
  }

  @override
  Future<ConversationDTO> getConversationById(String conversationId) async {
    try {
      final conversation = await databaseService.getConversationByConversationId(conversationId);
      if (conversation == null) {
        throw CacheException('Conversation not found: $conversationId');
      }
      return ConversationDTO.fromModel(conversation);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to get conversation: ${e.toString()}');
    }
  }

  @override
  Future<List<ConversationDTO>> searchConversations(String query) async {
    try {
      final conversations = await databaseService.searchConversations(query);
      return conversations.map((c) => ConversationDTO.fromModel(c)).toList();
    } catch (e) {
      throw CacheException('Failed to search conversations: ${e.toString()}');
    }
  }

  @override
  Future<ConversationDTO> saveConversation({
    required String conversationId,
    required String title,
    required List<dynamic> messageBranches,
    List<String> tags = const [],
  }) async {
    try {
      final conversation = await databaseService.saveConversation(
        conversationId: conversationId,
        title: title,
        messageBranches: messageBranches.cast(),
        tags: tags,
      );
      return ConversationDTO.fromModel(conversation);
    } catch (e) {
      throw CacheException('Failed to save conversation: ${e.toString()}');
    }
  }

  @override
  Future<ConversationDTO> updateConversation({
    required String conversationId,
    String? title,
    List<dynamic>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  }) async {
    try {
      final conversation = await databaseService.updateConversation(
        conversationId: conversationId,
        title: title,
        messageBranches: messageBranches?.cast(),
        isPinned: isPinned,
        tags: tags,
      );
      return ConversationDTO.fromModel(conversation);
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException('Failed to update conversation: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    try {
      await databaseService.deleteConversation(conversationId);
    } catch (e) {
      throw CacheException('Failed to delete conversation: ${e.toString()}');
    }
  }

  @override
  Future<void> togglePin(String conversationId) async {
    try {
      await databaseService.togglePin(conversationId);
    } catch (e) {
      throw CacheException('Failed to toggle pin: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAllConversations() async {
    try {
      await databaseService.deleteAllConversations();
    } catch (e) {
      throw CacheException('Failed to clear conversations: ${e.toString()}');
    }
  }

  @override
  Future<List<ConversationDTO>> getPinnedConversations() async {
    try {
      final conversations = await databaseService.getPinnedConversations();
      return conversations.map((c) => ConversationDTO.fromModel(c)).toList();
    } catch (e) {
      throw CacheException('Failed to get pinned conversations: ${e.toString()}');
    }
  }
}
