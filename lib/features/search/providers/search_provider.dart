import 'package:flutter/material.dart';
import 'dart:async';
import '../models/message_data.dart';
import '../models/message_branch_model.dart';
import '../services/search_service.dart';
import '../widgets/search_box.dart';
import '../../../shared/widgets/attachment_input_widget.dart';

class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();

  List<MessageBranchManager> _messageBranches = [];
  bool _isProcessing = false;
  int _branchIdCounter = 0;
  String? _currentConversationId;
  String? _currentConversationTitle;
  
  // Callback for when conversation is updated (for auto-save)
  Function()? onConversationUpdate;

  List<MessageBranchManager> get messageBranches => _messageBranches;
  bool get isProcessing => _isProcessing;
  String? get currentConversationId => _currentConversationId;
  String? get currentConversationTitle => _currentConversationTitle;
  bool get hasActiveConversation => _messageBranches.isNotEmpty;

  Future<void> initialize() async {
    await _searchService.initialize();
  }

  String _generateBranchId() {
    return 'branch_${_branchIdCounter++}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate a unique conversation ID using UUID format
  String _generateConversationId() {
    // Generate a UUID-like ID: 8-4-4-4-12 format
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random1 = (timestamp.hashCode & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
    final random2 = ((timestamp >> 8).hashCode & 0xFFFF).toRadixString(16).padLeft(4, '0');
    final random3 = ((timestamp >> 16).hashCode & 0xFFFF).toRadixString(16).padLeft(4, '0');
    final random4 = ((timestamp >> 24).hashCode & 0xFFFF).toRadixString(16).padLeft(4, '0');
    final random5 = (timestamp.hashCode & 0xFFFFFFFFFFFF).toRadixString(16).padLeft(12, '0');
    
    return '$random1-$random2-$random3-$random4-$random5';
  }

  /// Generate conversation title from first query
  String _generateConversationTitle(String query) {
    // Limit title to 50 characters
    if (query.length <= 50) return query;
    return '${query.substring(0, 47)}...';
  }

  /// Load a conversation from history
  void loadConversation({
    required String conversationId,
    required String title,
    required List<MessageBranchManager> branches,
  }) {
    _messageBranches = branches;
    _currentConversationId = conversationId;
    _currentConversationTitle = title;
    notifyListeners();
  }

  Future<void> performInitialSearch(
    String query,
    SearchMode searchMode,
    List<dynamic>? attachments, {
    String? conversationId, // Accept conversation ID from URL
  }) async {
    // Use provided conversation ID or generate new one
    if (_currentConversationId == null) {
      _currentConversationId = conversationId ?? _generateConversationId();
      _currentConversationTitle = _generateConversationTitle(query);
    }

    final generatingMessage = MessageData(
      query: query,
      answer: '',
      generationState: MessageGenerationState.searching,
    );

    final initialBranch = MessageBranch(
      id: _generateBranchId(),
      message: generatingMessage,
      createdAt: DateTime.now(),
    );

    final branchManager = MessageBranchManager(
      branches: [initialBranch],
      currentBranchIndex: 0,
    );

    _messageBranches = [branchManager];
    _isProcessing = true;
    notifyListeners();

    try {
      final streamController = StreamController<String>();

      final messageData = await _searchService.generateSearchResponse(
        query,
        attachments: attachments,
        searchMode: searchMode,
        onSearchComplete: (partialData) {
          // Update with search results as soon as available
          final searchCompletedMessage = partialData.copyWith(
            generationState: MessageGenerationState.generating,
          );
          branchManager.updateCurrentBranch(searchCompletedMessage);
          notifyListeners();
        },
      );

      // Update with search results (images, videos, sources) but no answer yet
      final searchCompletedMessage = messageData.copyWith(
        answer: '',
        generationState: MessageGenerationState.generating,
        answerStream: null,
      );

      branchManager.updateCurrentBranch(searchCompletedMessage);
      notifyListeners();

      // Now start streaming the answer
      final streamingMessage = searchCompletedMessage.copyWith(
        generationState: MessageGenerationState.streaming,
        answerStream: streamController.stream,
      );

      branchManager.updateCurrentBranch(streamingMessage);
      notifyListeners();

      await _streamText(streamController, messageData.answer);
      streamController.close();

      final completedMessage = messageData.copyWith(
        generationState: MessageGenerationState.completed,
      );

      branchManager.updateCurrentBranch(completedMessage);
      _isProcessing = false;
      notifyListeners();
      
      // Trigger auto-save callback
      onConversationUpdate?.call();

    } catch (e) {
      print('Search failed: $e');
      _messageBranches = [];
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addNewMessage(
    String query,
    List<AttachmentData>? attachments,
  ) async {
    if (_isProcessing) return;

    final generatingMessage = MessageData(
      query: query,
      answer: '',
      generationState: MessageGenerationState.searching,
    );

    final newBranch = MessageBranch(
      id: _generateBranchId(),
      message: generatingMessage,
      createdAt: DateTime.now(),
    );

    final newBranchManager = MessageBranchManager(
      branches: [newBranch],
      currentBranchIndex: 0,
    );

    _messageBranches.add(newBranchManager);
    _isProcessing = true;
    notifyListeners();

    try {
      final streamController = StreamController<String>();

      final conversationHistory = _messageBranches
          .take(_messageBranches.length - 1)
          .map((bm) => bm.currentMessage)
          .where((m) => m.generationState == MessageGenerationState.completed)
          .toList();

      print('💬 Using conversation history: ${conversationHistory.length} messages');

      final newMessageData = await _searchService.generateFollowUpResponse(
        query,
        conversationHistory,
        attachments: attachments,
        maxHistoryMessages: 5,
        onSearchComplete: (partialData) {
          // Update with search results as soon as available
          final searchCompletedMessage = partialData.copyWith(
            generationState: MessageGenerationState.generating,
          );
          newBranchManager.updateCurrentBranch(searchCompletedMessage);
          notifyListeners();
        },
      );

      // Update with search results (images, videos, sources) but no answer yet
      final searchCompletedMessage = newMessageData.copyWith(
        answer: '',
        generationState: MessageGenerationState.generating,
        answerStream: null,
      );

      newBranchManager.updateCurrentBranch(searchCompletedMessage);
      notifyListeners();

      // Now start streaming the answer
      final streamingMessage = searchCompletedMessage.copyWith(
        generationState: MessageGenerationState.streaming,
        answerStream: streamController.stream,
      );

      newBranchManager.updateCurrentBranch(streamingMessage);
      notifyListeners();

      await _streamText(streamController, newMessageData.answer);
      streamController.close();

      final completedMessage = newMessageData.copyWith(
        generationState: MessageGenerationState.completed,
      );

      newBranchManager.updateCurrentBranch(completedMessage);
      _isProcessing = false;
      notifyListeners();
      
      // Trigger auto-save callback
      onConversationUpdate?.call();

    } catch (e) {
      print('Follow-up search failed: $e');
      _messageBranches.removeLast();
      _isProcessing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _streamText(StreamController<String> controller, String text) async {
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      controller.add(words[i] + (i < words.length - 1 ? ' ' : ''));
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  void clearMessages() {
    _messageBranches.clear();
    _isProcessing = false;
    _currentConversationId = null;
    _currentConversationTitle = null;
    notifyListeners();
  }

  Future<void> rewriteMessage(int index) async {
    if (_isProcessing || index < 0 || index >= _messageBranches.length) return;

    final branchManager = _messageBranches[index];
    final oldMessage = branchManager.currentMessage;

    final generatingMessage = MessageData(
      query: oldMessage.query,
      answer: '',
      generationState: MessageGenerationState.generating,
      sources: oldMessage.sources,
      relatedQuestions: oldMessage.relatedQuestions,
      attachments: oldMessage.attachments,
    );

    final rewriteBranch = MessageBranch(
      id: _generateBranchId(),
      message: generatingMessage,
      createdAt: DateTime.now(),
      parentBranchId: branchManager.currentBranch.id,
    );

    branchManager.addBranch(rewriteBranch);
    _isProcessing = true;
    notifyListeners();

    try {
      final streamController = StreamController<String>();

      final streamingMessage = generatingMessage.copyWith(
        generationState: MessageGenerationState.streaming,
        answerStream: streamController.stream,
      );

      branchManager.updateCurrentBranch(streamingMessage);
      notifyListeners();

      final messageData = await _searchService.generateSearchResponse(
        oldMessage.query,
        attachments: oldMessage.attachments,
        searchMode: SearchMode.search,
      );

      await _streamText(streamController, messageData.answer);
      streamController.close();

      final completedMessage = messageData.copyWith(
        generationState: MessageGenerationState.completed,
      );

      branchManager.updateCurrentBranch(completedMessage);
      _isProcessing = false;
      notifyListeners();

    } catch (e) {
      print('Rewrite failed: $e');
      // Fallback to original message
      final fallbackManager = MessageBranchManager(
        branches: [branchManager.currentBranch],
        currentBranchIndex: 0,
      );
      _messageBranches[index] = fallbackManager;
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> editQuery(int index, String newQuery) async {
    if (_isProcessing || newQuery.trim().isEmpty || index < 0 || index >= _messageBranches.length) return;

    final branchManager = _messageBranches[index];
    final oldMessage = branchManager.currentMessage;

    final generatingMessage = MessageData(
      query: newQuery,
      answer: '',
      generationState: MessageGenerationState.generating,
      sources: oldMessage.sources,
      relatedQuestions: oldMessage.relatedQuestions,
      attachments: oldMessage.attachments,
    );

    final editBranch = MessageBranch(
      id: _generateBranchId(),
      message: generatingMessage,
      createdAt: DateTime.now(),
      parentBranchId: branchManager.currentBranch.id,
    );

    branchManager.addBranch(editBranch);
    _messageBranches[index] = branchManager;
    _isProcessing = true;
    notifyListeners();

    try {
      final streamController = StreamController<String>();

      final streamingMessage = generatingMessage.copyWith(
        generationState: MessageGenerationState.streaming,
        answerStream: streamController.stream,
      );

      branchManager.updateCurrentBranch(streamingMessage);
      notifyListeners();

      final messageData = await _searchService.generateSearchResponse(
        newQuery,
        attachments: oldMessage.attachments,
        searchMode: SearchMode.search,
      );

      await _streamText(streamController, messageData.answer);
      streamController.close();

      final completedMessage = messageData.copyWith(
        generationState: MessageGenerationState.completed,
      );

      branchManager.updateCurrentBranch(completedMessage);
      _isProcessing = false;
      notifyListeners();

    } catch (e) {
      print('Edit query failed: $e');
      // Fallback to original message
      final fallbackManager = MessageBranchManager(
        branches: [branchManager.currentBranch],
        currentBranchIndex: 0,
      );
      _messageBranches[index] = fallbackManager;
      _isProcessing = false;
      notifyListeners();
    }
  }
}