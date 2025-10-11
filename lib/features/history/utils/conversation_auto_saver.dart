import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_history_provider.dart';
import '../../search/providers/search_provider.dart';
import '../../search/models/message_data.dart';

/// Utility class for auto-saving conversations
class ConversationAutoSaver {
  static bool _isSaving = false;

  /// Auto-save the current conversation
  static Future<void> autoSave(
    BuildContext context, {
    bool force = false,
  }) async {
    if (_isSaving && !force) return;

    try {
      _isSaving = true;

      final searchProvider = context.read<SearchProvider>();
      final historyProvider = context.read<ConversationHistoryProvider>();

      // Only save if there are messages and at least one is complete
      if (!searchProvider.hasActiveConversation) {
        _isSaving = false;
        return;
      }

      final messages = searchProvider.messageBranches;
      final hasCompletedMessage = messages.any(
        (branch) => branch.currentMessage.generationState ==
            MessageGenerationState.completed,
      );

      if (!hasCompletedMessage && !force) {
        _isSaving = false;
        return;
      }

      // Get conversation ID and title
      final conversationId = searchProvider.currentConversationId;
      final title = searchProvider.currentConversationTitle;

      if (conversationId == null || title == null) {
        _isSaving = false;
        return;
      }

      // Check if conversation already exists
      final existing =
          await historyProvider.getConversation(conversationId);

      if (existing == null) {
        // Save new conversation
        await historyProvider.saveConversation(
          conversationId: conversationId,
          title: title,
          messageBranches: messages,
        );
        print('✅ New conversation saved: $conversationId');
      } else {
        // Update existing conversation
        await historyProvider.updateConversation(
          conversationId: conversationId,
          messageBranches: messages,
        );
        print('✅ Conversation updated: $conversationId');
      }

      _isSaving = false;
    } catch (e) {
      _isSaving = false;
      print('❌ Auto-save failed: $e');
    }
  }

  /// Save conversation with a custom title
  static Future<void> saveWithTitle(
    BuildContext context,
    String title,
  ) async {
    try {
      final searchProvider = context.read<SearchProvider>();
      final historyProvider = context.read<ConversationHistoryProvider>();

      if (!searchProvider.hasActiveConversation) return;

      final conversationId = searchProvider.currentConversationId;
      if (conversationId == null) return;

      final existing =
          await historyProvider.getConversation(conversationId);

      if (existing == null) {
        await historyProvider.saveConversation(
          conversationId: conversationId,
          title: title,
          messageBranches: searchProvider.messageBranches,
        );
      } else {
        await historyProvider.updateConversation(
          conversationId: conversationId,
          title: title,
        );
      }

      print('✅ Conversation saved with custom title: $title');
    } catch (e) {
      print('❌ Save with title failed: $e');
    }
  }
}
