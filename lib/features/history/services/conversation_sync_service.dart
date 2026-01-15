import 'package:firebase_auth/firebase_auth.dart';
import '../../settings/services/settings_service.dart';
import '../../auth/services/auth_service.dart';
import '../models/conversation_model.dart';
import '../../search/models/message_branch_model.dart';
import 'conversation_database_service.dart';
import 'conversation_cloud_service.dart';

/// Hybrid service that combines local Hive storage with optional cloud sync
/// Provides unified interface for conversation management with privacy controls
class ConversationSyncService {
  static final ConversationSyncService _instance = ConversationSyncService._internal();
  factory ConversationSyncService() => _instance;
  ConversationSyncService._internal();

  final ConversationDatabaseService _localStorage = ConversationDatabaseService();
  final ConversationCloudService _cloudStorage = ConversationCloudService();
  final SettingsService _settings = SettingsService();
  final AuthService _auth = AuthService();

  bool _isInitialized = false;
  bool _isCloudSyncEnabled = false;
  DateTime? _lastSyncTimestamp;

  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isCloudSyncEnabled => _isCloudSyncEnabled;
  bool get isAuthenticated => _auth.isAuthenticated;
  DateTime? get lastSyncTimestamp => _lastSyncTimestamp;

  /// Initialize the hybrid service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing ConversationSyncService');

      // Initialize local storage
      await _localStorage.initialize();

      // Load cloud sync settings
      await _loadSettings();

      // Listen to auth state changes
      _auth.authStateChanges.listen(_onAuthStateChanged);

      _isInitialized = true;
      print('✅ ConversationSyncService initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize ConversationSyncService: $e');
      rethrow;
    }
  }

  /// Load cloud sync settings
  Future<void> _loadSettings() async {
    _isCloudSyncEnabled = _settings.getCloudSyncEnabled();
    final timestampString = _settings.getLastSyncTimestamp();
    if (timestampString != null) {
      _lastSyncTimestamp = DateTime.tryParse(timestampString);
    }
  }

  /// Handle authentication state changes
  void _onAuthStateChanged(User? user) {
    if (user != null && _isCloudSyncEnabled) {
      // User signed in and cloud sync is enabled - could trigger sync
      print('🔄 User authenticated, cloud sync available');
    } else if (user == null) {
      // User signed out
      print('🔄 User signed out, cloud sync disabled');
    }
  }

  /// Enable or disable cloud sync
  Future<void> setCloudSyncEnabled(bool enabled) async {
    if (_isCloudSyncEnabled == enabled) return;

    _isCloudSyncEnabled = enabled;
    await _settings.setCloudSyncEnabled(enabled);

    if (enabled && isAuthenticated) {
      // If enabling and user is authenticated, offer to sync existing data
      print('✅ Cloud sync enabled');
    } else if (!enabled) {
      print('🚫 Cloud sync disabled');
    }
  }

  /// Save a new conversation (local + optional cloud sync)
  Future<ConversationModel> saveConversation({
    required String conversationId,
    required String title,
    required List<MessageBranchManager> messageBranches,
    List<String> tags = const [],
  }) async {
    // Always save locally first
    final conversation = await _localStorage.saveConversation(
      conversationId: conversationId,
      title: title,
      messageBranches: messageBranches,
      tags: tags,
    );

    // Sync to cloud if enabled and authenticated
    if (_isCloudSyncEnabled && isAuthenticated) {
      try {
        await _cloudStorage.syncConversation(conversation);
        await _updateLastSyncTimestamp();
        print('☁️ Conversation synced to cloud: ${conversation.conversationId}');
      } catch (e) {
        print('⚠️ Failed to sync conversation to cloud: $e');
        // Don't fail the operation if cloud sync fails
      }
    }

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
    // Update locally first
    final conversation = await _localStorage.updateConversation(
      conversationId: conversationId,
      title: title,
      messageBranches: messageBranches,
      isPinned: isPinned,
      tags: tags,
    );

    // Sync to cloud if enabled and authenticated
    if (_isCloudSyncEnabled && isAuthenticated) {
      try {
        await _cloudStorage.syncConversation(conversation);
        await _updateLastSyncTimestamp();
        print('☁️ Conversation update synced to cloud: ${conversation.conversationId}');
      } catch (e) {
        print('⚠️ Failed to sync conversation update to cloud: $e');
      }
    }

    return conversation;
  }

  /// Get a conversation by ID (checks local first, then cloud if needed)
  Future<ConversationModel?> getConversationById(String conversationId) async {
    // Try local storage first
    var conversation = await _localStorage.getConversationByConversationId(conversationId);

    // If not found locally and cloud sync is enabled, try cloud
    if (conversation == null && _isCloudSyncEnabled && isAuthenticated) {
      try {
        final cloudConversations = await _cloudStorage.getCloudConversations();
        try {
          conversation = cloudConversations.firstWhere(
            (c) => c.conversationId == conversationId,
          );
        } catch (e) {
          conversation = null;
        }

        // If found in cloud, save locally for future access
        if (conversation != null) {
          await _localStorage.saveConversation(
            conversationId: conversation.conversationId,
            title: conversation.title,
            messageBranches: _localStorage.convertMessagesToBranches(conversation.messages),
            tags: conversation.tags,
          );
          print('📥 Conversation restored from cloud: ${conversation.conversationId}');
        }
      } catch (e) {
        print('⚠️ Failed to check cloud for conversation: $e');
      }
    }

    return conversation;
  }

  /// Get all conversations (merges local and cloud data)
  Future<List<ConversationModel>> getAllConversations({
    bool pinnedFirst = true,
  }) async {
    final localConversations = await _localStorage.getAllConversations(pinnedFirst: pinnedFirst);

    // If cloud sync is enabled and authenticated, merge with cloud data
    if (_isCloudSyncEnabled && isAuthenticated) {
      try {
        final cloudConversations = await _cloudStorage.getCloudConversations();

        // Create a map for quick lookup
        final conversationMap = <String, ConversationModel>{};

        // Add local conversations
        for (final conv in localConversations) {
          conversationMap[conv.conversationId] = conv;
        }

        // Merge/add cloud conversations (prefer local if conflict)
        for (final cloudConv in cloudConversations) {
          if (!conversationMap.containsKey(cloudConv.conversationId)) {
            // New conversation from cloud - save locally
            await _localStorage.saveConversation(
              conversationId: cloudConv.conversationId,
              title: cloudConv.title,
              messageBranches: _localStorage.convertMessagesToBranches(cloudConv.messages),
              tags: cloudConv.tags,
            );
            conversationMap[cloudConv.conversationId] = cloudConv;
            print('📥 New conversation from cloud: ${cloudConv.conversationId}');
          }
        }

        return conversationMap.values.toList()
          ..sort((a, b) {
            if (pinnedFirst) {
              if (a.isPinned && !b.isPinned) return -1;
              if (!a.isPinned && b.isPinned) return 1;
            }
            return b.updatedAt.compareTo(a.updatedAt);
          });

      } catch (e) {
        print('⚠️ Failed to merge cloud conversations: $e');
        // Fall back to local only
      }
    }

    return localConversations;
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    final deleted = await _localStorage.deleteConversation(conversationId);

    if (deleted && _isCloudSyncEnabled && isAuthenticated) {
      try {
        await _cloudStorage.deleteCloudConversation(conversationId);
        print('☁️ Conversation deleted from cloud: $conversationId');
      } catch (e) {
        print('⚠️ Failed to delete conversation from cloud: $e');
      }
    }

    return deleted;
  }

  /// Delete all conversations
  Future<void> deleteAllConversations() async {
    await _localStorage.deleteAllConversations();

    if (_isCloudSyncEnabled && isAuthenticated) {
      try {
        // Note: Deleting all from cloud would require fetching all conversations first
        // For now, we'll just clear local and let cloud sync handle it over time
        print('☁️ Local conversations cleared, cloud will sync on next operation');
      } catch (e) {
        print('⚠️ Failed to handle cloud sync for delete all: $e');
      }
    }
  }

  /// Toggle pin status
  Future<void> togglePin(String conversationId) async {
    await _localStorage.togglePin(conversationId);

    if (_isCloudSyncEnabled && isAuthenticated) {
      try {
        final conversation = await getConversationById(conversationId);
        if (conversation != null) {
          await _cloudStorage.syncConversation(conversation);
        }
      } catch (e) {
        print('⚠️ Failed to sync pin status to cloud: $e');
      }
    }
  }

  /// Search conversations
  Future<List<ConversationModel>> searchConversations(String query) async {
    // Search locally (cloud search would be more complex and expensive)
    return await _localStorage.searchConversations(query);
  }

  /// Sync all local conversations to cloud (one-time migration)
  Future<void> syncAllToCloud() async {
    if (!_isCloudSyncEnabled || !isAuthenticated) {
      throw Exception('Cloud sync not enabled or user not authenticated');
    }

    try {
      print('🔄 Starting full sync to cloud...');
      final localConversations = await _localStorage.getAllConversations();

      for (final conversation in localConversations) {
        await _cloudStorage.syncConversation(conversation);
      }

      await _updateLastSyncTimestamp();
      print('✅ Full sync to cloud completed');
    } catch (e) {
      print('❌ Failed to sync all conversations to cloud: $e');
      rethrow;
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    _lastSyncTimestamp = DateTime.now();
    await _settings.setLastSyncTimestamp(_lastSyncTimestamp!.toIso8601String());
  }

  /// Get conversation count
  Future<int> getConversationCount() async {
    return await _localStorage.getConversationCount();
  }

  /// Get pinned conversations
  Future<List<ConversationModel>> getPinnedConversations() async {
    return await _localStorage.getPinnedConversations();
  }

  /// Get grouped conversations
  Future<Map<String, List<ConversationModel>>> getGroupedConversations() async {
    return await _localStorage.getGroupedConversations();
  }

  /// Convert ConversationMessageModel list back to MessageBranchManager list
  List<MessageBranchManager> convertMessagesToBranches(
      List<ConversationMessageModel> messages) {
    return _localStorage.convertMessagesToBranches(messages);
  }

  /// Delete multiple conversations
  Future<int> deleteConversations(List<String> conversationIds) async {
    int deletedCount = 0;

    for (final conversationId in conversationIds) {
      try {
        final deleted = await deleteConversation(conversationId);
        if (deleted) {
          deletedCount++;
        }
      } catch (e) {
        print('⚠️ Failed to delete conversation $conversationId: $e');
      }
    }

    return deletedCount;
  }

  /// Close all services
  Future<void> close() async {
    await _localStorage.close();
  }
}