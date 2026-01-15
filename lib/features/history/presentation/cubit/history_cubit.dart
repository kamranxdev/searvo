import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/features/history/domain/usecases/delete_conversation.dart';
import 'package:searvo/features/history/domain/usecases/delete_all_conversations.dart';
import 'package:searvo/features/history/domain/usecases/get_all_conversations.dart';
import 'package:searvo/features/history/domain/usecases/get_conversation_by_id.dart';
import 'package:searvo/features/history/domain/usecases/get_grouped_conversations.dart';
import 'package:searvo/features/history/domain/usecases/search_conversations.dart';
import 'package:searvo/features/history/domain/usecases/toggle_pin_conversation.dart';
import 'package:searvo/features/history/presentation/cubit/history_state.dart';
import 'package:searvo/core/usecases/usecase.dart';

/// Cubit for managing conversation history state
/// Uses use cases from domain layer
class HistoryCubit extends Cubit<HistoryState> {
  final GetAllConversations getAllConversations;
  final GetGroupedConversations getGroupedConversations;
  final GetConversationById getConversationById;
  final SearchConversations searchConversations;
  final DeleteConversation deleteConversation;
  final DeleteAllConversations deleteAllConversations;
  final TogglePinConversation togglePinConversation;

  HistoryCubit({
    required this.getAllConversations,
    required this.getGroupedConversations,
    required this.getConversationById,
    required this.searchConversations,
    required this.deleteConversation,
    required this.deleteAllConversations,
    required this.togglePinConversation,
  }) : super(const HistoryState.initial());

  /// Load all conversations
  Future<void> loadConversations() async {
    emit(const HistoryState.loading());

    final conversationsResult = await getAllConversations();
    final groupedResult = await getGroupedConversations();

    conversationsResult.fold((failure) => emit(HistoryState.error(failure)), (
      conversations,
    ) {
      groupedResult.fold(
        (failure) => emit(HistoryState.error(failure)),
        (grouped) => emit(
          HistoryState.loaded(
            conversations: conversations,
            groupedConversations: grouped,
          ),
        ),
      );
    });
  }

  /// Get a specific conversation by ID
  Future<void> getConversation(String conversationId) async {
    final result = await getConversationById(conversationId);

    result.fold((failure) => emit(HistoryState.error(failure)), (conversation) {
      // Conversation retrieved successfully
      // This can be used by search_results_screen to load a conversation
    });
  }

  /// Search conversations
  Future<void> search(String query) async {
    await state.maybeWhen(
      loaded: (conversations, grouped, _, __, ___) async {
        if (query.trim().isEmpty) {
          emit(
            HistoryState.loaded(
              conversations: conversations,
              groupedConversations: grouped,
              searchResults: [],
              searchQuery: '',
              isSearching: false,
            ),
          );
          return;
        }

        emit(
          HistoryState.loaded(
            conversations: conversations,
            groupedConversations: grouped,
            searchResults: [],
            searchQuery: query,
            isSearching: true,
          ),
        );

        final result = await searchConversations(
          SearchConversationsParams(query: query),
        );

        result.fold(
          (failure) => emit(HistoryState.error(failure)),
          (results) => emit(
            HistoryState.loaded(
              conversations: conversations,
              groupedConversations: grouped,
              searchResults: results,
              searchQuery: query,
              isSearching: false,
            ),
          ),
        );
      },
      orElse: () async {
        // Load conversations first if not loaded
        await loadConversations();
        // Then search after loading
        await state.maybeWhen(
          loaded: (_, __, ___, ____, _____) async {
            await search(query);
          },
          orElse: () async {},
        );
      },
    );
  }

  /// Delete a conversation
  Future<void> delete(String conversationId) async {
    await state.maybeWhen(
      loaded:
          (
            conversations,
            grouped,
            searchResults,
            searchQuery,
            isSearching,
          ) async {
            final result = await deleteConversation(
              DeleteConversationParams(conversationId: conversationId),
            );

            result.fold(
              (failure) => emit(HistoryState.error(failure)),
              (_) => loadConversations(), // Reload after deletion
            );
          },
      orElse: () async {},
    );
  }

  /// Delete all conversations
  Future<void> deleteAll() async {
    await state.maybeWhen(
      loaded: (conversations, grouped, _, __, ___) async {
        final result = await deleteAllConversations(NoParams());

        result.fold(
          (failure) => emit(HistoryState.error(failure)),
          (_) => loadConversations(), // Reload to show empty state
        );
      },
      orElse: () async {},
    );
  }

  /// Toggle pin status
  Future<void> togglePin(String conversationId) async {
    await state.maybeWhen(
      loaded:
          (
            conversations,
            grouped,
            searchResults,
            searchQuery,
            isSearching,
          ) async {
            final result = await togglePinConversation(
              TogglePinConversationParams(conversationId: conversationId),
            );

            result.fold(
              (failure) => emit(HistoryState.error(failure)),
              (_) => loadConversations(), // Reload after toggling pin
            );
          },
      orElse: () async {},
    );
  }

  /// Clear search
  void clearSearch() {
    state.maybeWhen(
      loaded: (conversations, grouped, _, __, ___) {
        emit(
          HistoryState.loaded(
            conversations: conversations,
            groupedConversations: grouped,
            searchResults: [],
            searchQuery: '',
            isSearching: false,
          ),
        );
      },
      orElse: () {},
    );
  }
}
