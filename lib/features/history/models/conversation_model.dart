import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import '../database/conversation_database.dart';

/// Main conversation model for use in the app layer
class ConversationModel {
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
  final List<ConversationMessageModel> messages;

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

  /// Convert from Drift Conversation to ConversationModel
  static ConversationModel fromDrift(Conversation conversation, List<ConversationMessageModel> messages) {
    return ConversationModel(
      id: conversation.id,
      conversationId: conversation.conversationId,
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: conversation.updatedAt,
      isPinned: conversation.isPinned,
      messageCount: conversation.messageCount,
      lastQuery: conversation.lastQuery,
      lastAnswer: conversation.lastAnswer,
      tags: _decodeTags(conversation.tags),
      messages: messages,
    );
  }

  /// Convert to Drift ConversationsCompanion
  ConversationsCompanion toDriftCompanion() {
    return ConversationsCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      conversationId: drift.Value(conversationId),
      title: drift.Value(title),
      createdAt: drift.Value(createdAt),
      updatedAt: drift.Value(updatedAt),
      isPinned: drift.Value(isPinned),
      messageCount: drift.Value(messageCount),
      lastQuery: drift.Value(lastQuery),
      lastAnswer: drift.Value(lastAnswer),
      tags: drift.Value(_encodeTags(tags)),
    );
  }

  /// Encode tags to JSON string
  static String _encodeTags(List<String> tags) {
    return jsonEncode(tags);
  }

  /// Decode tags from JSON string
  static List<String> _decodeTags(String tagsJson) {
    try {
      final decoded = jsonDecode(tagsJson);
      return List<String>.from(decoded);
    } catch (e) {
      return [];
    }
  }
}

/// Message model within a conversation
class ConversationMessageModel {
  final int? id;
  final String messageId;
  final String query;
  final String answer;
  final DateTime timestamp;
  final List<ConversationSourceModel> sources;
  final List<String> relatedQuestions;
  final List<String> images;
  final List<ConversationVideoModel> videos;
  final List<ConversationAttachmentModel> attachments;
  final bool isFallback;
  final String? errorMessage;
  final String? branchId;
  final String? parentBranchId;
  final int branchIndex;
  final int totalBranches;

  ConversationMessageModel({
    this.id,
    this.messageId = '',
    this.query = '',
    this.answer = '',
    required this.timestamp,
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
  });

  /// Create a message with specific timestamp
  static ConversationMessageModel create({
    int? id,
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
    return ConversationMessageModel(
      id: id,
      messageId: messageId,
      query: query,
      answer: answer,
      timestamp: timestamp,
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
  }

  /// Convert from Drift Message to ConversationMessageModel
  static ConversationMessageModel fromDrift(
    Message message,
    List<ConversationSourceModel> sources,
    List<ConversationVideoModel> videos,
    List<ConversationAttachmentModel> attachments,
  ) {
    return ConversationMessageModel(
      id: message.id,
      messageId: message.messageId,
      query: message.query,
      answer: message.answer,
      timestamp: message.timestamp,
      isFallback: message.isFallback,
      errorMessage: message.errorMessage,
      branchId: message.branchId,
      parentBranchId: message.parentBranchId,
      branchIndex: message.branchIndex,
      totalBranches: message.totalBranches,
      relatedQuestions: _decodeStringList(message.relatedQuestions),
      images: _decodeStringList(message.images),
      sources: sources,
      videos: videos,
      attachments: attachments,
    );
  }

  /// Convert to Drift MessagesCompanion
  MessagesCompanion toDriftCompanion(int conversationId) {
    return MessagesCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      conversationId: drift.Value(conversationId),
      messageId: drift.Value(messageId),
      query: drift.Value(query),
      answer: drift.Value(answer),
      timestamp: drift.Value(timestamp),
      isFallback: drift.Value(isFallback),
      errorMessage: drift.Value(errorMessage),
      branchId: drift.Value(branchId),
      parentBranchId: drift.Value(parentBranchId),
      branchIndex: drift.Value(branchIndex),
      totalBranches: drift.Value(totalBranches),
      relatedQuestions: drift.Value(_encodeStringList(relatedQuestions)),
      images: drift.Value(_encodeStringList(images)),
    );
  }

  /// Encode string list to JSON
  static String _encodeStringList(List<String> list) {
    return jsonEncode(list);
  }

  /// Decode string list from JSON
  static List<String> _decodeStringList(String json) {
    try {
      final decoded = jsonDecode(json);
      return List<String>.from(decoded);
    } catch (e) {
      return [];
    }
  }
}

/// Source model
class ConversationSourceModel {
  final int? id;
  final String thumbnail;
  final String? favicon;
  final String url;
  final String title;
  final String description;
  final String domain;
  final DateTime? publishedDate;
  final String? source;

  ConversationSourceModel({
    this.id,
    this.thumbnail = '',
    this.favicon,
    this.url = '',
    this.title = '',
    this.description = '',
    this.domain = '',
    this.publishedDate,
    this.source,
  });

  /// Convert from Drift Source to ConversationSourceModel
  static ConversationSourceModel fromDrift(Source source) {
    return ConversationSourceModel(
      id: source.id,
      thumbnail: source.thumbnail,
      favicon: source.favicon,
      url: source.url,
      title: source.title,
      description: source.description,
      domain: source.domain,
      publishedDate: source.publishedDate,
      source: source.source,
    );
  }

  /// Convert to Drift SourcesCompanion
  SourcesCompanion toDriftCompanion(int messageId) {
    return SourcesCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      messageId: drift.Value(messageId),
      thumbnail: drift.Value(thumbnail),
      favicon: drift.Value(favicon),
      url: drift.Value(url),
      title: drift.Value(title),
      description: drift.Value(description),
      domain: drift.Value(domain),
      publishedDate: drift.Value(publishedDate),
      source: drift.Value(source),
    );
  }
}

/// Video model
class ConversationVideoModel {
  final int? id;
  final String thumbnail;
  final String url;
  final String title;
  final String description;
  final String domain;
  final String? duration;
  final DateTime? publishedDate;
  final int? views;

  ConversationVideoModel({
    this.id,
    this.thumbnail = '',
    this.url = '',
    this.title = '',
    this.description = '',
    this.domain = '',
    this.duration,
    this.publishedDate,
    this.views,
  });

  /// Convert from Drift Video to ConversationVideoModel
  static ConversationVideoModel fromDrift(Video video) {
    return ConversationVideoModel(
      id: video.id,
      thumbnail: video.thumbnail,
      url: video.url,
      title: video.title,
      description: video.description,
      domain: video.domain,
      duration: video.duration,
      publishedDate: video.publishedDate,
      views: video.views,
    );
  }

  /// Convert to Drift VideosCompanion
  VideosCompanion toDriftCompanion(int messageId) {
    return VideosCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      messageId: drift.Value(messageId),
      thumbnail: drift.Value(thumbnail),
      url: drift.Value(url),
      title: drift.Value(title),
      description: drift.Value(description),
      domain: drift.Value(domain),
      duration: drift.Value(duration),
      publishedDate: drift.Value(publishedDate),
      views: drift.Value(views),
    );
  }
}

/// Attachment model
class ConversationAttachmentModel {
  final int? id;
  final String attachmentId;
  final String name;
  final String path;
  final String type;
  final int size;
  final DateTime uploadedAt;
  final String? extractedText;

  ConversationAttachmentModel({
    this.id,
    this.attachmentId = '',
    this.name = '',
    this.path = '',
    this.type = '',
    this.size = 0,
    required this.uploadedAt,
    this.extractedText,
  });

  /// Create an attachment with specific timestamp
  static ConversationAttachmentModel create({
    int? id,
    String attachmentId = '',
    String name = '',
    String path = '',
    String type = '',
    int size = 0,
    required DateTime uploadedAt,
    String? extractedText,
  }) {
    return ConversationAttachmentModel(
      id: id,
      attachmentId: attachmentId,
      name: name,
      path: path,
      type: type,
      size: size,
      uploadedAt: uploadedAt,
      extractedText: extractedText,
    );
  }

  /// Convert from Drift Attachment to ConversationAttachmentModel
  static ConversationAttachmentModel fromDrift(Attachment attachment) {
    return ConversationAttachmentModel(
      id: attachment.id,
      attachmentId: attachment.attachmentId,
      name: attachment.name,
      path: attachment.path,
      type: attachment.type,
      size: attachment.size,
      uploadedAt: attachment.uploadedAt,
      extractedText: attachment.extractedText,
    );
  }

  /// Convert to Drift AttachmentsCompanion
  AttachmentsCompanion toDriftCompanion(int messageId) {
    return AttachmentsCompanion(
      id: id != null ? drift.Value(id!) : const drift.Value.absent(),
      messageId: drift.Value(messageId),
      attachmentId: drift.Value(attachmentId),
      name: drift.Value(name),
      path: drift.Value(path),
      type: drift.Value(type),
      size: drift.Value(size),
      uploadedAt: drift.Value(uploadedAt),
      extractedText: drift.Value(extractedText),
    );
  }
}
