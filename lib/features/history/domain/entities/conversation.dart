import 'package:equatable/equatable.dart';

/// Domain entity for a conversation
/// Pure Dart class with business logic, no external dependencies
class Conversation extends Equatable {
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

  const Conversation({
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

  /// Get preview text for conversation list
  String get preview {
    if (lastAnswer != null && lastAnswer!.isNotEmpty) {
      return lastAnswer!.length > 100
          ? '${lastAnswer!.substring(0, 100)}...'
          : lastAnswer!;
    }
    return lastQuery ?? 'No messages';
  }

  /// Get time category for grouping
  String get timeCategory {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) return 'Today';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return 'Last 7 Days';
    if (difference.inDays < 30) return 'Last 30 Days';
    return 'Older';
  }

  Conversation copyWith({
    int? id,
    String? conversationId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    int? messageCount,
    String? lastQuery,
    String? lastAnswer,
    List<String>? tags,
  }) {
    return Conversation(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      messageCount: messageCount ?? this.messageCount,
      lastQuery: lastQuery ?? this.lastQuery,
      lastAnswer: lastAnswer ?? this.lastAnswer,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        title,
        createdAt,
        updatedAt,
        isPinned,
        messageCount,
        lastQuery,
        lastAnswer,
        tags,
      ];
}
