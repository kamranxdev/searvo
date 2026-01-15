import 'package:searvo/features/history/domain/entities/conversation.dart';
import 'package:searvo/features/history/models/conversation_model.dart';

/// Data Transfer Object for Conversation
/// Handles conversion between data layer and domain layer
class ConversationDTO {
  final int? id;
  final String conversationId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final int messageCount;
  final String? lastQuery;
  final String? lastAnswer;
  final List<String> tags;

  ConversationDTO({
    this.id,
    required this.conversationId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.messageCount = 0,
    this.lastQuery,
    this.lastAnswer,
    this.tags = const [],
  });

  /// Convert from ConversationModel (existing model)
  factory ConversationDTO.fromModel(ConversationModel model) {
    return ConversationDTO(
      id: model.id,
      conversationId: model.conversationId,
      title: model.title,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
      isPinned: model.isPinned,
      messageCount: model.messageCount,
      lastQuery: model.lastQuery,
      lastAnswer: model.lastAnswer,
      tags: model.tags,
    );
  }

  /// Convert to domain entity
  Conversation toEntity() {
    return Conversation(
      id: id,
      conversationId: conversationId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isPinned: isPinned,
      messageCount: messageCount,
      lastQuery: lastQuery,
      lastAnswer: lastAnswer,
      tags: tags,
    );
  }

  /// Convert from domain entity
  factory ConversationDTO.fromEntity(Conversation entity) {
    return ConversationDTO(
      id: entity.id,
      conversationId: entity.conversationId,
      title: entity.title,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isPinned: entity.isPinned,
      messageCount: entity.messageCount,
      lastQuery: entity.lastQuery,
      lastAnswer: entity.lastAnswer,
      tags: entity.tags,
    );
  }
}
