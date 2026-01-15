import 'dart:convert';
import '../database/conversation_database.dart';
import '../models/conversation_model.dart';
import '../../search/models/message_data.dart';
import '../../search/models/message_branch_model.dart';

/// Service for managing conversation history in Drift database
class ConversationDatabaseService {
  static final ConversationDatabaseService _instance =
      ConversationDatabaseService._internal();
  factory ConversationDatabaseService() => _instance;
  ConversationDatabaseService._internal();

  ConversationDatabase? _database;

  /// Initialize the database
  Future<void> initialize() async {
    if (_database != null) return;
    _database = ConversationDatabase();
  }

  /// Get the database instance
  ConversationDatabase get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Save a new conversation
  Future<ConversationModel> saveConversation({
    required String conversationId,
    required String title,
    required List<MessageBranchManager> messageBranches,
    List<String> tags = const [],
  }) async {
    final db = database;
    final messages = _convertBranchesToMessages(messageBranches);

    final conversationCompanion = ConversationModel(
      conversationId: conversationId,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messageCount: messages.length,
      lastQuery: messages.isNotEmpty ? messages.last.query : null,
      lastAnswer: messages.isNotEmpty ? messages.last.answer : null,
      tags: tags,
    ).toDriftCompanion();

    // Insert conversation and get the ID
    final convId = await db.insertConversation(conversationCompanion);

    // Insert messages and their related data
    for (final message in messages) {
      final messageCompanion = message.toDriftCompanion(convId);
      final messageId = await db.insertMessage(messageCompanion);

      // Insert sources
      if (message.sources.isNotEmpty) {
        final sourceCompanions =
            message.sources.map((s) => s.toDriftCompanion(messageId)).toList();
        await db.insertSources(sourceCompanions);
      }

      // Insert videos
      if (message.videos.isNotEmpty) {
        final videoCompanions =
            message.videos.map((v) => v.toDriftCompanion(messageId)).toList();
        await db.insertVideos(videoCompanions);
      }

      // Insert attachments
      if (message.attachments.isNotEmpty) {
        final attachmentCompanions = message.attachments
            .map((a) => a.toDriftCompanion(messageId))
            .toList();
        await db.insertAttachments(attachmentCompanions);
      }
    }

    // Return the saved conversation with all messages
    return _loadFullConversation(convId);
  }

  /// Update an existing conversation
  Future<ConversationModel> updateConversation({
    required String conversationId,
    String? title,
    List<MessageBranchManager>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  }) async {
    final db = database;
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
      tags: tags ?? existing.tags,
    );

    // Update conversation
    final driftConversation = Conversation(
      id: updated.id!,
      conversationId: updated.conversationId,
      title: updated.title,
      createdAt: updated.createdAt,
      updatedAt: updated.updatedAt,
      isPinned: updated.isPinned,
      messageCount: updated.messageCount,
      lastQuery: updated.lastQuery,
      lastAnswer: updated.lastAnswer,
      tags: jsonEncode(updated.tags),
    );
    await db.updateConversation(driftConversation);

    // If messages were updated, replace them
    if (messageBranches != null) {
      // Delete old messages (cascade will delete related data)
      await db.deleteMessagesForConversation(updated.id!);

      // Insert new messages
      for (final message in messages) {
        final messageCompanion = message.toDriftCompanion(updated.id!);
        final messageId = await db.insertMessage(messageCompanion);

        // Insert sources
        if (message.sources.isNotEmpty) {
          final sourceCompanions =
              message.sources.map((s) => s.toDriftCompanion(messageId)).toList();
          await db.insertSources(sourceCompanions);
        }

        // Insert videos
        if (message.videos.isNotEmpty) {
          final videoCompanions =
              message.videos.map((v) => v.toDriftCompanion(messageId)).toList();
          await db.insertVideos(videoCompanions);
        }

        // Insert attachments
        if (message.attachments.isNotEmpty) {
          final attachmentCompanions = message.attachments
              .map((a) => a.toDriftCompanion(messageId))
              .toList();
          await db.insertAttachments(attachmentCompanions);
        }
      }
    }

    return _loadFullConversation(updated.id!);
  }

  /// Get a conversation by conversation ID
  Future<ConversationModel?> getConversationByConversationId(
      String conversationId) async {
    final db = database;
    final conversation =
        await db.getConversationByConversationId(conversationId);
    if (conversation == null) return null;

    return _loadFullConversation(conversation.id);
  }

  /// Get all conversations sorted by date
  Future<List<ConversationModel>> getAllConversations({
    bool pinnedFirst = true,
  }) async {
    final db = database;
    final conversations = await db.getAllConversations(pinnedFirst: pinnedFirst);

    final result = <ConversationModel>[];
    for (final conversation in conversations) {
      final fullConversation = await _loadFullConversation(conversation.id);
      result.add(fullConversation);
    }

    return result;
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
    final db = database;
    final conversations = await db.searchConversations(query);

    final result = <ConversationModel>[];
    for (final conversation in conversations) {
      final fullConversation = await _loadFullConversation(conversation.id);
      result.add(fullConversation);
    }

    return result;
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    final db = database;
    final count = await db.deleteConversationByConversationId(conversationId);
    return count > 0;
  }

  /// Delete multiple conversations
  Future<int> deleteConversations(List<String> conversationIds) async {
    final db = database;
    int deletedCount = 0;

    for (final conversationId in conversationIds) {
      final count = await db.deleteConversationByConversationId(conversationId);
      if (count > 0) deletedCount++;
    }

    return deletedCount;
  }

  /// Delete all conversations
  Future<void> deleteAllConversations() async {
    final db = database;
    await db.deleteAllConversations();
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
    final db = database;
    return db.getConversationCount();
  }

  /// Get pinned conversations
  Future<List<ConversationModel>> getPinnedConversations() async {
    final db = database;
    final conversations = await db.getPinnedConversations();

    final result = <ConversationModel>[];
    for (final conversation in conversations) {
      final fullConversation = await _loadFullConversation(conversation.id);
      result.add(fullConversation);
    }

    return result;
  }

  /// Load a full conversation with all messages and related data
  Future<ConversationModel> _loadFullConversation(int conversationId) async {
    final db = database;
    final conversation = await db.select(db.conversations)
      ..where((c) => c.id.equals(conversationId));
    final conversationData = await conversation.getSingle();

    // Load all messages for this conversation
    final messagesList = await db.getMessagesForConversation(conversationId);

    final messages = <ConversationMessageModel>[];
    for (final message in messagesList) {
      // Load sources
      final sourcesList = await db.getSourcesForMessage(message.id);
      final sources = sourcesList
          .map((s) => ConversationSourceModel.fromDrift(s))
          .toList();

      // Load videos
      final videosList = await db.getVideosForMessage(message.id);
      final videos = videosList
          .map((v) => ConversationVideoModel.fromDrift(v))
          .toList();

      // Load attachments
      final attachmentsList = await db.getAttachmentsForMessage(message.id);
      final attachments = attachmentsList
          .map((a) => ConversationAttachmentModel.fromDrift(a))
          .toList();

      messages.add(
        ConversationMessageModel.fromDrift(
          message,
          sources,
          videos,
          attachments,
        ),
      );
    }

    return ConversationModel.fromDrift(conversationData, messages);
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
    await _database?.close();
    _database = null;
  }
}
