import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/conversation_database_service.dart';
import '../../search/models/message_branch_model.dart';

/// Provider for managing conversation history state
class ConversationHistoryProvider extends ChangeNotifier {
  final ConversationDatabaseService _dbService =
      ConversationDatabaseService();

  List<ConversationModel> _conversations = [];
  Map<String, List<ConversationModel>> _groupedConversations = {};
  List<ConversationModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  Map<String, List<ConversationModel>> get groupedConversations =>
      _groupedConversations;
  List<ConversationModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get error => _error;
  bool get hasConversations => _conversations.isNotEmpty;

  /// Initialize the provider
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _dbService.initialize();
      await loadConversations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize conversation history: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ History initialization error: $e');
    }
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();

      _conversations = await _dbService.getAllConversations();
      _groupedConversations = await _dbService.getGroupedConversations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load conversations: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Load conversations error: $e');
    }
  }

  /// Save a new conversation
  Future<ConversationModel?> saveConversation({
    required String conversationId,
    required String title,
    required List<MessageBranchManager> messageBranches,
    List<String> tags = const [],
  }) async {
    try {
      final conversation = await _dbService.saveConversation(
        conversationId: conversationId,
        title: title,
        messageBranches: messageBranches,
        tags: tags,
      );

      await loadConversations();
      return conversation;
    } catch (e) {
      _error = 'Failed to save conversation: $e';
      notifyListeners();
      print('❌ Save conversation error: $e');
      return null;
    }
  }

  /// Update an existing conversation
  Future<ConversationModel?> updateConversation({
    required String conversationId,
    String? title,
    List<MessageBranchManager>? messageBranches,
    bool? isPinned,
    List<String>? tags,
  }) async {
    try {
      final conversation = await _dbService.updateConversation(
        conversationId: conversationId,
        title: title,
        messageBranches: messageBranches,
        isPinned: isPinned,
        tags: tags,
      );

      await loadConversations();
      return conversation;
    } catch (e) {
      _error = 'Failed to update conversation: $e';
      notifyListeners();
      print('❌ Update conversation error: $e');
      return null;
    }
  }

  /// Get a specific conversation
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      return await _dbService.getConversationByConversationId(conversationId);
    } catch (e) {
      _error = 'Failed to get conversation: $e';
      notifyListeners();
      print('❌ Get conversation error: $e');
      return null;
    }
  }

  /// Search conversations
  Future<void> searchConversations(String query) async {
    try {
      _isSearching = true;
      _searchQuery = query;
      notifyListeners();

      if (query.trim().isEmpty) {
        _searchResults = [];
        _isSearching = false;
        notifyListeners();
        return;
      }

      _searchResults = await _dbService.searchConversations(query);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to search conversations: $e';
      _isSearching = false;
      notifyListeners();
      print('❌ Search conversations error: $e');
    }
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final success = await _dbService.deleteConversation(conversationId);
      if (success) {
        await loadConversations();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      notifyListeners();
      print('❌ Delete conversation error: $e');
      return false;
    }
  }

  /// Delete multiple conversations
  Future<int> deleteConversations(List<String> conversationIds) async {
    try {
      final count = await _dbService.deleteConversations(conversationIds);
      if (count > 0) {
        await loadConversations();
      }
      return count;
    } catch (e) {
      _error = 'Failed to delete conversations: $e';
      notifyListeners();
      print('❌ Delete conversations error: $e');
      return 0;
    }
  }

  /// Delete all conversations
  Future<void> deleteAllConversations() async {
    try {
      await _dbService.deleteAllConversations();
      await loadConversations();
    } catch (e) {
      _error = 'Failed to delete all conversations: $e';
      notifyListeners();
      print('❌ Delete all conversations error: $e');
    }
  }

  /// Toggle pin status
  Future<void> togglePin(String conversationId) async {
    try {
      await _dbService.togglePin(conversationId);
      await loadConversations();
    } catch (e) {
      _error = 'Failed to toggle pin: $e';
      notifyListeners();
      print('❌ Toggle pin error: $e');
    }
  }

  /// Get pinned conversations
  Future<List<ConversationModel>> getPinnedConversations() async {
    try {
      return await _dbService.getPinnedConversations();
    } catch (e) {
      _error = 'Failed to get pinned conversations: $e';
      notifyListeners();
      print('❌ Get pinned conversations error: $e');
      return [];
    }
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    try {
      return await _dbService.getConversationCount();
    } catch (e) {
      print('❌ Get conversation count error: $e');
      return 0;
    }
  }

  /// Convert stored messages back to branches for resuming conversation
  List<MessageBranchManager> convertToBranches(
      List<ConversationMessageModel> messages) {
    return _dbService.convertMessagesToBranches(messages);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _dbService.close();
    super.dispose();
  }
}
