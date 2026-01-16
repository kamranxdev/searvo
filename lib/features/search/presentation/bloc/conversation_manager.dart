import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../domain/entities/message_branch_manager.dart'; // Direct import from domain
import '../../domain/entities/message_data.dart';
import '../../domain/entities/message_branch.dart';
import '../../domain/entities/message_generation_state.dart';

class ConversationState {
  final List<MessageBranchManager> messageBranches;
  final String conversationId;
  final String conversationTitle;
  final bool isProcessing;
  final String? errorMessage;

  const ConversationState({
    this.messageBranches = const [],
    this.conversationId = '',
    this.conversationTitle = '',
    this.isProcessing = false,
    this.errorMessage,
  });

  factory ConversationState.initial() => const ConversationState();

  ConversationState copyWith({
    List<MessageBranchManager>? messageBranches,
    String? conversationId,
    String? conversationTitle,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return ConversationState(
      messageBranches: messageBranches ?? this.messageBranches,
      conversationId: conversationId ?? this.conversationId,
      conversationTitle: conversationTitle ?? this.conversationTitle,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }
}

class ConversationManager {
  final _stateController = BehaviorSubject<ConversationState>.seeded(
    ConversationState.initial(),
  );

  Stream<ConversationState> get stateStream => _stateController.stream;
  ConversationState get state => _stateController.value;

  int _branchIdCounter = 0;

  void dispose() {
    _stateController.close();
  }

  // --- ID Generation ---

  String _generateBranchId() {
    return 'branch_${_branchIdCounter++}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateConversationId() {
    // Generate a UUID-like ID: 8-4-4-4-12 format
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random1 = (timestamp.hashCode & 0xFFFFFFFF)
        .toRadixString(16)
        .padLeft(8, '0');
    final random2 = ((timestamp >> 8).hashCode & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final random3 = ((timestamp >> 16).hashCode & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final random4 = ((timestamp >> 24).hashCode & 0xFFFF)
        .toRadixString(16)
        .padLeft(4, '0');
    final random5 = (timestamp.hashCode & 0xFFFFFFFFFFFF)
        .toRadixString(16)
        .padLeft(12, '0');

    return '$random1-$random2-$random3-$random4-$random5';
  }

  String _generateConversationTitle(String query) {
    if (query.length <= 50) return query;
    return '${query.substring(0, 47)}...';
  }

  // --- Actions ---

  void loadConversation(
    String conversationId,
    String title,
    List<MessageBranchManager> branches,
  ) {
    _emit(
      state.copyWith(
        messageBranches: branches,
        conversationId: conversationId,
        conversationTitle: title,
        isProcessing: false,
        errorMessage: null,
      ),
    );
  }

  void clearConversation() {
    _emit(ConversationState.initial());
  }

  void setProcessing(bool isProcessing) {
    _emit(state.copyWith(isProcessing: isProcessing));
  }

  void updateState({
    List<MessageBranchManager>? branches,
    String? conversationId,
    String? conversationTitle,
    bool? isProcessing,
  }) {
    _emit(
      state.copyWith(
        messageBranches: branches,
        conversationId: conversationId,
        conversationTitle: conversationTitle,
        isProcessing: isProcessing,
      ),
    );
  }

  void updateCurrentMessage(MessageData newMessage) {
    if (state.messageBranches.isEmpty) return;

    final currentBranches = List<MessageBranchManager>.from(
      state.messageBranches,
    );
    final activeManager = currentBranches.last;

    activeManager.updateCurrentBranch(newMessage);

    _emit(state.copyWith(messageBranches: currentBranches));
  }

  void setError(String message) {
    _emit(state.copyWith(errorMessage: message, isProcessing: false));
  }

  void updateTitle(String newTitle) {
    if (newTitle.trim().isNotEmpty) {
      _emit(state.copyWith(conversationTitle: newTitle));
    }
  }

  // --- Logic ported from Bloc ---

  MessageBranchManager startNewConversation(
    String query, {
    String? providedId,
  }) {
    final conversationId = providedId ?? _generateConversationId();
    final conversationTitle = _generateConversationTitle(query);

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

    _emit(
      state.copyWith(
        messageBranches: [branchManager],
        conversationId: conversationId,
        conversationTitle: conversationTitle,
        isProcessing: true,
      ),
    );

    return branchManager;
  }

  MessageBranchManager? addNewMessage(String query) {
    if (state.isProcessing) return null;

    final currentBranches = List<MessageBranchManager>.from(
      state.messageBranches,
    );

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

    currentBranches.add(newBranchManager);

    _emit(state.copyWith(messageBranches: currentBranches, isProcessing: true));

    return newBranchManager;
  }

  MessageBranchManager? rewriteMessage(int index) {
    if (state.isProcessing ||
        index < 0 ||
        index >= state.messageBranches.length) {
      return null;
    }

    final currentBranches = List<MessageBranchManager>.from(
      state.messageBranches,
    );
    final branchManager = currentBranches[index];
    final oldMessage = branchManager.currentMessage;

    final generatingMessage = MessageData(
      query: oldMessage.query,
      answer: '',
      generationState: MessageGenerationState.searching,
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

    _emit(state.copyWith(messageBranches: currentBranches, isProcessing: true));

    return branchManager;
  }

  MessageBranchManager? editQuery(int index, String newQuery) {
    if (state.isProcessing ||
        newQuery.trim().isEmpty ||
        index < 0 ||
        index >= state.messageBranches.length) {
      return null;
    }

    final currentBranches = List<MessageBranchManager>.from(
      state.messageBranches,
    );
    final branchManager = currentBranches[index];
    final oldMessage = branchManager.currentMessage;

    final generatingMessage = MessageData(
      query: newQuery,
      answer: '',
      generationState: MessageGenerationState.searching,
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
    currentBranches[index] = branchManager;

    _emit(state.copyWith(messageBranches: currentBranches, isProcessing: true));

    return branchManager;
  }

  void switchBranch(int messageIndex, int branchIndex) {
    if (messageIndex < 0 || messageIndex >= state.messageBranches.length) {
      return;
    }

    final currentBranches = List<MessageBranchManager>.from(
      state.messageBranches,
    );
    final branchManager = currentBranches[messageIndex];

    if (branchIndex >= 0 && branchIndex < branchManager.branches.length) {
      branchManager.goToBranch(branchIndex);

      _emit(state.copyWith(messageBranches: currentBranches));
    }
  }

  void _emit(ConversationState newState) {
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }
}
