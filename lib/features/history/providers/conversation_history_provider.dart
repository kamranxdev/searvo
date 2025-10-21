import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../services/conversation_sync_service.dart';
import '../../search/models/message_branch_model.dart';

/// Provider for managing conversation history state
class ConversationHistoryProvider extends ChangeNotifier {
  final ConversationSyncService _syncService =
      ConversationSyncService();

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

      await _syncService.initialize();
      await loadConversations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize conversation history: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all conversations
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();

      _conversations = await _syncService.getAllConversations();
      _groupedConversations = await _syncService.getGroupedConversations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load conversations: $e';
      _isLoading = false;
      notifyListeners();
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
      final conversation = await _syncService.saveConversation(
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
      final conversation = await _syncService.updateConversation(
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
      return null;
    }
  }

  /// Get a specific conversation
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      return await _syncService.getConversationById(conversationId);
    } catch (e) {
      _error = 'Failed to get conversation: $e';
      notifyListeners();
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

      _searchResults = await _syncService.searchConversations(query);
      _isSearching = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to search conversations: $e';
      _isSearching = false;
      notifyListeners();
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
      final success = await _syncService.deleteConversation(conversationId);
      if (success) {
        await loadConversations();
      }
      return success;
    } catch (e) {
      _error = 'Failed to delete conversation: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete multiple conversations
  Future<int> deleteConversations(List<String> conversationIds) async {
    try {
      final count = await _syncService.deleteConversations(conversationIds);
      if (count > 0) {
        await loadConversations();
      }
      return count;
    } catch (e) {
      _error = 'Failed to delete conversations: $e';
      notifyListeners();
      return 0;
    }
  }

  /// Delete all conversations
  Future<void> deleteAllConversations() async {
    try {
      await _syncService.deleteAllConversations();
      await loadConversations();
    } catch (e) {
      _error = 'Failed to delete all conversations: $e';
      notifyListeners();
    }
  }

  /// Toggle pin status
  Future<void> togglePin(String conversationId) async {
    try {
      await _syncService.togglePin(conversationId);
      await loadConversations();
    } catch (e) {
      _error = 'Failed to toggle pin: $e';
      notifyListeners();
    }
  }

  /// Get pinned conversations
  Future<List<ConversationModel>> getPinnedConversations() async {
    try {
      return await _syncService.getPinnedConversations();
    } catch (e) {
      _error = 'Failed to get pinned conversations: $e';
      notifyListeners();
      return [];
    }
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    try {
      return await _syncService.getConversationCount();
    } catch (e) {
      return 0;
    }
  }

  /// Convert stored messages back to branches for resuming conversation
  List<MessageBranchManager> convertToBranches(
      List<ConversationMessageModel> messages) {
    return _syncService.convertMessagesToBranches(messages);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncService.close();
    super.dispose();
  }
}
