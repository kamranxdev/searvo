import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/history/domain/entities/conversation.dart';

part 'history_state.freezed.dart';

@freezed
class HistoryState with _$HistoryState {
  const factory HistoryState.initial() = _Initial;
  
  const factory HistoryState.loading() = _Loading;
  
  const factory HistoryState.loaded({
    required List<Conversation> conversations,
    required Map<String, List<Conversation>> groupedConversations,
    @Default([]) List<Conversation> searchResults,
    @Default('') String searchQuery,
    @Default(false) bool isSearching,
  }) = _Loaded;
  
  const factory HistoryState.error(Failure failure) = _Error;
}
