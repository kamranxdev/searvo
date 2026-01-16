import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/message_branch_manager.dart';

part 'search_state.freezed.dart';

@freezed
class SearchState with _$SearchState {
  const factory SearchState.initial() = _Initial;

  const factory SearchState.loading({
    required List<MessageBranchManager> messageBranches,
    String? conversationId,
    String? conversationTitle,
  }) = _Loading;

  const factory SearchState.loaded({
    required List<MessageBranchManager> messageBranches,
    required bool isProcessing,
    String? conversationId,
    String? conversationTitle,
  }) = _Loaded;

  const factory SearchState.error({
    required String message,
    required List<MessageBranchManager> messageBranches,
    String? conversationId,
    String? conversationTitle,
  }) = _Error;
}

// Extension to make it easier to access common properties
extension SearchStateX on SearchState {
  List<MessageBranchManager> get messageBranches => when(
    initial: () => [],
    loading: (branches, _, __) => branches,
    loaded: (branches, _, __, ___) => branches,
    error: (_, branches, __, ___) => branches,
  );

  bool get isProcessing => when(
    initial: () => false,
    loading: (_, __, ___) => true,
    loaded: (_, isProcessing, __, ___) => isProcessing,
    error: (_, __, ___, ____) => false,
  );

  String? get conversationId => when(
    initial: () => null,
    loading: (_, id, __) => id,
    loaded: (_, __, id, ___) => id,
    error: (_, __, id, ___) => id,
  );

  String? get conversationTitle => when(
    initial: () => null,
    loading: (_, __, title) => title,
    loaded: (_, __, ___, title) => title,
    error: (_, __, ___, title) => title,
  );

  bool get hasActiveConversation => messageBranches.isNotEmpty;
}
