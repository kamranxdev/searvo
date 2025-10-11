import 'package:hive/hive.dart';

part 'conversation_model.g.dart';

/// Main conversation model stored in Hive database
@HiveType(typeId: 0)
class ConversationModel {
  @HiveField(0)
  int? id;

  @HiveField(1)
  late String conversationId;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  int messageCount;

  @HiveField(7)
  String? lastQuery;

  @HiveField(8)
  String? lastAnswer;

  @HiveField(9)
  List<String> tags;

  /// Embedded messages in the conversation
  @HiveField(10)
  List<ConversationMessageModel> messages;

  ConversationModel({
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
    this.messages = const [],
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
}

/// Embedded message model within a conversation
@HiveType(typeId: 1)
class ConversationMessageModel {
  @HiveField(0)
  late String messageId;

  @HiveField(1)
  late String query;

  @HiveField(2)
  late String answer;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  List<ConversationSourceModel> sources;

  @HiveField(5)
  List<String> relatedQuestions;

  @HiveField(6)
  List<String> images;

  @HiveField(7)
  List<ConversationVideoModel> videos;

  @HiveField(8)
  List<ConversationAttachmentModel> attachments;

  @HiveField(9)
  late bool isFallback;

  @HiveField(10)
  String? errorMessage;

  /// Branch information for multi-branch conversations
  @HiveField(11)
  String? branchId;

  @HiveField(12)
  String? parentBranchId;

  @HiveField(13)
  late int branchIndex;

  @HiveField(14)
  late int totalBranches;

  ConversationMessageModel({
    this.messageId = '',
    this.query = '',
    this.answer = '',
    this.sources = const [],
    this.relatedQuestions = const [],
    this.images = const [],
    this.videos = const [],
    this.attachments = const [],
    this.isFallback = false,
    this.errorMessage,
    this.branchId,
    this.parentBranchId,
    this.branchIndex = 0,
    this.totalBranches = 1,
  }) {
    timestamp = DateTime.now();
  }

  /// Create a message with specific timestamp
  static ConversationMessageModel create({
    String messageId = '',
    String query = '',
    String answer = '',
    required DateTime timestamp,
    List<ConversationSourceModel> sources = const [],
    List<String> relatedQuestions = const [],
    List<String> images = const [],
    List<ConversationVideoModel> videos = const [],
    List<ConversationAttachmentModel> attachments = const [],
    bool isFallback = false,
    String? errorMessage,
    String? branchId,
    String? parentBranchId,
    int branchIndex = 0,
    int totalBranches = 1,
  }) {
    final message = ConversationMessageModel(
      messageId: messageId,
      query: query,
      answer: answer,
      sources: sources,
      relatedQuestions: relatedQuestions,
      images: images,
      videos: videos,
      attachments: attachments,
      isFallback: isFallback,
      errorMessage: errorMessage,
      branchId: branchId,
      parentBranchId: parentBranchId,
      branchIndex: branchIndex,
      totalBranches: totalBranches,
    );
    message.timestamp = timestamp;
    return message;
  }
}

/// Embedded source model
@HiveType(typeId: 2)
class ConversationSourceModel {
  @HiveField(0)
  late String thumbnail;

  @HiveField(1)
  String? favicon;

  @HiveField(2)
  late String url;

  @HiveField(3)
  late String title;

  @HiveField(4)
  late String description;

  @HiveField(5)
  late String domain;

  @HiveField(6)
  DateTime? publishedDate;

  @HiveField(7)
  String? source;

  ConversationSourceModel({
    this.thumbnail = '',
    this.favicon,
    this.url = '',
    this.title = '',
    this.description = '',
    this.domain = '',
    this.publishedDate,
    this.source,
  });
}

/// Embedded video model
@HiveType(typeId: 3)
class ConversationVideoModel {
  @HiveField(0)
  late String thumbnail;

  @HiveField(1)
  late String url;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String description;

  @HiveField(4)
  late String domain;

  @HiveField(5)
  String? duration;

  @HiveField(6)
  DateTime? publishedDate;

  @HiveField(7)
  int? views;

  ConversationVideoModel({
    this.thumbnail = '',
    this.url = '',
    this.title = '',
    this.description = '',
    this.domain = '',
    this.duration,
    this.publishedDate,
    this.views,
  });
}

/// Embedded attachment model
@HiveType(typeId: 4)
class ConversationAttachmentModel {
  @HiveField(0)
  late String attachmentId;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String path;

  @HiveField(3)
  late String type;

  @HiveField(4)
  late int size;

  @HiveField(5)
  late DateTime uploadedAt;

  @HiveField(6)
  String? extractedText;

  ConversationAttachmentModel({
    this.attachmentId = '',
    this.name = '',
    this.path = '',
    this.type = '',
    this.size = 0,
    this.extractedText,
  }) {
    uploadedAt = DateTime.now();
  }

  /// Create an attachment with specific timestamp
  static ConversationAttachmentModel create({
    String attachmentId = '',
    String name = '',
    String path = '',
    String type = '',
    int size = 0,
    required DateTime uploadedAt,
    String? extractedText,
  }) {
    final attachment = ConversationAttachmentModel(
      attachmentId: attachmentId,
      name: name,
      path: path,
      type: type,
      size: size,
      extractedText: extractedText,
    );
    attachment.uploadedAt = uploadedAt;
    return attachment;
  }
}
