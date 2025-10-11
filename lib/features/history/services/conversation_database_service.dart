import 'package:hive_flutter/hive_flutter.dart';
import '../models/conversation_model.dart';
import '../../search/models/message_data.dart';
import '../../search/models/message_branch_model.dart';

/// Service for managing conversation history in Hive database
class ConversationDatabaseService {
  static final ConversationDatabaseService _instance =
      ConversationDatabaseService._internal();
  factory ConversationDatabaseService() => _instance;
  ConversationDatabaseService._internal();

  Box<ConversationModel>? _box;
  int _nextId = 0;

  /// Initialize the database
  Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;

    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ConversationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ConversationMessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ConversationSourceModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ConversationVideoModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ConversationAttachmentModelAdapter());
    }

    _box = await Hive.openBox<ConversationModel>('conversations');
    
    // Find the next available ID
    if (_box!.isNotEmpty) {
      _nextId = _box!.keys.cast<int>().reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  /// Get the Hive box
  Box<ConversationModel> get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// Save a new conversation
  Future<ConversationModel> saveConversation({
    required String conversationId,
    required String title,
    required List<MessageBranchManager> messageBranches,
    List<String> tags = const [],
  }) async {
    final messages = _convertBranchesToMessages(messageBranches);

    final conversation = ConversationModel(
      id: _nextId++,
      conversationId: conversationId,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: messages.length,
      lastQuery: messages.isNotEmpty ? messages.last.query : null,
      lastAnswer: messages.isNotEmpty ? messages.last.answer : null,
      messages: messages,
      tags: tags,
    );

    await box.put(conversation.id!, conversation);

    return conversation;
  }

  /// Update an existing conversation
  Future<ConversationModel> updateConversation({
    required String conversationId,
    String? title,
    List<MessageBranchManager>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  }) async {
    final existing = await getConversationByConversationId(conversationId);
    if (existing == null) {
      throw Exception('Conversation not found: $conversationId');
    }

    final messages = messageBranches != null
        ? _convertBranchesToMessages(messageBranches)
        : existing.messages;

    final updated = ConversationModel(
      id: existing.id,
      conversationId: existing.conversationId,
      title: title ?? existing.title,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
      isPinned: isPinned ?? existing.isPinned,
      messageCount: messages.length,
      lastQuery: messages.isNotEmpty ? messages.last.query : existing.lastQuery,
      lastAnswer:
          messages.isNotEmpty ? messages.last.answer : existing.lastAnswer,
      messages: messages,
      tags: tags ?? existing.tags,
    );

    await box.put(updated.id!, updated);

    return updated;
  }

  /// Get a conversation by conversation ID
  Future<ConversationModel?> getConversationByConversationId(
      String conversationId) async {
    try {
      return box.values
          .cast<ConversationModel>()
          .firstWhere((conversation) => conversation.conversationId == conversationId);
    } catch (e) {
      return null;
    }
  }

  /// Get all conversations sorted by date
  Future<List<ConversationModel>> getAllConversations({
    bool pinnedFirst = true,
  }) async {
    final conversations = box.values.toList();

    if (pinnedFirst) {
      conversations.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    } else {
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    return conversations;
  }

  /// Get conversations grouped by time period
  Future<Map<String, List<ConversationModel>>> getGroupedConversations() async {
    final conversations = await getAllConversations();
    final grouped = <String, List<ConversationModel>>{};

    for (final conversation in conversations) {
      final category = conversation.timeCategory;
      grouped.putIfAbsent(category, () => []).add(conversation);
    }

    return grouped;
  }

  /// Search conversations by query
  Future<List<ConversationModel>> searchConversations(String query) async {
    final lowerQuery = query.toLowerCase();

    final allConversations = await getAllConversations();

    return allConversations.where((conversation) {
      // Search in title
      if (conversation.title.toLowerCase().contains(lowerQuery)) return true;

      // Search in queries
      if (conversation.lastQuery?.toLowerCase().contains(lowerQuery) ?? false) {
        return true;
      }

      // Search in answers
      if (conversation.lastAnswer?.toLowerCase().contains(lowerQuery) ??
          false) {
        return true;
      }

      // Search in messages
      for (final message in conversation.messages) {
        if (message.query.toLowerCase().contains(lowerQuery) ||
            message.answer.toLowerCase().contains(lowerQuery)) {
          return true;
        }
      }

      // Search in tags
      if (conversation.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    final conversation = await getConversationByConversationId(conversationId);
    if (conversation == null) return false;

    await box.delete(conversation.id!);

    return true;
  }

  /// Delete multiple conversations
  Future<int> deleteConversations(List<String> conversationIds) async {
    int deletedCount = 0;

    for (final conversationId in conversationIds) {
      final conversation =
          await getConversationByConversationId(conversationId);
      if (conversation != null) {
        await box.delete(conversation.id!);
        deletedCount++;
      }
    }

    return deletedCount;
  }

  /// Delete all conversations
  Future<void> deleteAllConversations() async {
    await box.clear();
  }

  /// Pin/Unpin a conversation
  Future<void> togglePin(String conversationId) async {
    final conversation = await getConversationByConversationId(conversationId);
    if (conversation == null) return;

    await updateConversation(
      conversationId: conversationId,
      isPinned: !conversation.isPinned,
    );
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    return box.length;
  }

  /// Get pinned conversations
  Future<List<ConversationModel>> getPinnedConversations() async {
    return box.values
        .where((conversation) => conversation.isPinned)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Convert MessageBranchManager list to ConversationMessageModel list
  List<ConversationMessageModel> _convertBranchesToMessages(
      List<MessageBranchManager> branches) {
    final messages = <ConversationMessageModel>[];

    for (final branchManager in branches) {
      final currentBranch = branchManager.currentBranch;
      final message = currentBranch.message;

      messages.add(ConversationMessageModel.create(
        messageId: currentBranch.id,
        query: message.query,
        answer: message.answer,
        timestamp: message.timestamp,
        sources: message.sources
            .map((s) => ConversationSourceModel(
                  thumbnail: s.thumbnail,
                  favicon: s.favicon,
                  url: s.url,
                  title: s.title,
                  description: s.description,
                  domain: s.domain,
                  publishedDate: s.publishedDate,
                  source: s.source,
                ))
            .toList(),
        relatedQuestions: message.relatedQuestions,
        images: message.images,
        videos: message.videos
            .map((v) => ConversationVideoModel(
                  thumbnail: v.thumbnail,
                  url: v.url,
                  title: v.title,
                  description: v.description,
                  domain: v.domain,
                  duration: v.duration,
                  publishedDate: v.publishedDate,
                  views: v.views,
                ))
            .toList(),
        attachments: message.attachments
            .map((a) => ConversationAttachmentModel.create(
                  attachmentId: a.id,
                  name: a.name,
                  path: a.path,
                  type: a.type,
                  size: a.size,
                  uploadedAt: a.uploadedAt,
                  extractedText: a.extractedText,
                ))
            .toList(),
        isFallback: message.isFallback,
        errorMessage: message.errorMessage,
        branchId: currentBranch.id,
        parentBranchId: currentBranch.parentBranchId,
        branchIndex: branchManager.currentBranchIndex,
        totalBranches: branchManager.totalBranches,
      ));
    }

    return messages;
  }

  /// Convert ConversationMessageModel list back to MessageBranchManager list
  List<MessageBranchManager> convertMessagesToBranches(
      List<ConversationMessageModel> messages) {
    final branches = <MessageBranchManager>[];

    for (final message in messages) {
      final messageData = MessageData(
        query: message.query,
        answer: message.answer,
        timestamp: message.timestamp,
        sources: message.sources
            .map((s) => SourceItem(
                  thumbnail: s.thumbnail,
                  favicon: s.favicon,
                  url: s.url,
                  title: s.title,
                  description: s.description,
                  domain: s.domain,
                  publishedDate: s.publishedDate,
                  source: s.source,
                ))
            .toList(),
        relatedQuestions: message.relatedQuestions,
        images: message.images,
        videos: message.videos
            .map((v) => VideoItem(
                  thumbnail: v.thumbnail,
                  url: v.url,
                  title: v.title,
                  description: v.description,
                  domain: v.domain,
                  duration: v.duration,
                  publishedDate: v.publishedDate,
                  views: v.views,
                ))
            .toList(),
        attachments: message.attachments
            .map((a) => AttachmentMetadata(
                  id: a.attachmentId,
                  name: a.name,
                  path: a.path,
                  type: a.type,
                  size: a.size,
                  uploadedAt: a.uploadedAt,
                  extractedText: a.extractedText,
                ))
            .toList(),
        isFallback: message.isFallback,
        errorMessage: message.errorMessage,
        generationState: MessageGenerationState.completed,
      );

      final branch = MessageBranch(
        id: message.branchId ?? message.messageId,
        message: messageData,
        createdAt: message.timestamp,
        parentBranchId: message.parentBranchId,
      );

      branches.add(MessageBranchManager(
        branches: [branch],
        currentBranchIndex: 0,
      ));
    }

    return branches;
  }

  /// Close the database
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
