import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/message_data.dart';
import '../models/message_branch_model.dart';
import '../models/search_mode.dart';
import '../../../common/widgets/attachment_input_widget.dart'; // For AttachmentData

part 'search_event.freezed.dart';

@freezed
class SearchEvent with _$SearchEvent {
  /// Perform initial search with query and optional conversation ID
  const factory SearchEvent.performInitialSearch({
    required String query,
    required SearchMode searchMode,
    List<dynamic>? attachments,
    String? conversationId,
  }) = _PerformInitialSearch;

  /// Add a new message to existing conversation
  const factory SearchEvent.addNewMessage({
    required String query,
    List<AttachmentData>? attachments,
  }) = _AddNewMessage;

  /// Rewrite a message at a specific index
  const factory SearchEvent.rewriteMessage({required int index}) =
      _RewriteMessage;

  /// Edit query at a specific index
  const factory SearchEvent.editQuery({
    required int index,
    required String newQuery,
  }) = _EditQuery;

  /// Clear all messages and reset conversation
  const factory SearchEvent.clearMessages() = _ClearMessages;

  /// Load a conversation from history
  const factory SearchEvent.loadConversation({
    required String conversationId,
    required String title,
    required List<MessageBranchManager> branches,
  }) = _LoadConversation;

  /// Switch to a different branch at an index
  const factory SearchEvent.switchBranch({
    required int messageIndex,
    required int branchIndex,
  }) = _SwitchBranch;

  /// Initialize the search service
  const factory SearchEvent.initialize() = _Initialize;
}
