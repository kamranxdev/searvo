import 'message_data.dart';

/// Represents a single branch in the conversation tree
class MessageBranch {
  final String id;
  final MessageData message;
  final DateTime createdAt;
  final String? parentBranchId;

  MessageBranch({
    required this.id,
    required this.message,
    required this.createdAt,
    this.parentBranchId,
  });

  MessageBranch copyWith({
    String? id,
    MessageData? message,
    DateTime? createdAt,
    String? parentBranchId,
  }) {
    return MessageBranch(
      id: id ?? this.id,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      parentBranchId: parentBranchId ?? this.parentBranchId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': {
        'query': message.query,
        'answer': message.answer,
        'sources': message.sources.map((s) => s.toMap()).toList(),
        'relatedQuestions': message.relatedQuestions,
        'attachments': message.attachments
            .map(
              (a) => {
                'id': a.id,
                'name': a.name,
                'path': a.path,
                'type': a.type,
                'size': a.size,
              },
            )
            .toList(),
      },
      'createdAt': createdAt.toIso8601String(),
      'parentBranchId': parentBranchId,
    };
  }

  @override
  String toString() {
    return 'MessageBranch(id: $id, query: ${message.query}, createdAt: $createdAt)';
  }
}
