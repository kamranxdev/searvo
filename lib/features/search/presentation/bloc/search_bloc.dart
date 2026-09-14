import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../domain/entities/message_branch_manager.dart';
import '../../domain/entities/message_generation_state.dart';
import '../../domain/entities/source_item.dart';
import '../../domain/entities/search_stream_status.dart';
import '../../data/datasources/search_data_source.dart';
import 'conversation_manager.dart';

import '../../../../common/widgets/attachment_input_widget.dart';
import '../../../history/services/conversation_database_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRemoteDataSource _searchRemoteDataSource;
  final ConversationManager _conversationManager;
  final ConversationDatabaseService _conversationDatabaseService;

  SearchBloc({
    required SearchRemoteDataSource searchRemoteDataSource,
    required ConversationDatabaseService conversationDatabaseService,
    ConversationManager? conversationManager,
  }) : _searchRemoteDataSource = searchRemoteDataSource,
       _conversationDatabaseService = conversationDatabaseService,
       _conversationManager = conversationManager ?? ConversationManager(),
       super(const SearchState.initial()) {
    on<SearchEvent>((event, emit) async {
      await event.when(
        initialize: () => _onInitialize(emit),
        performInitialSearch: (query, attachments, conversationId) =>
            _onPerformInitialSearch(query, attachments, conversationId, emit),
        addNewMessage: (query, attachments) =>
            _onAddNewMessage(query, attachments, emit),
        rewriteMessage: (index) => _onRewriteMessage(index, emit),
        editQuery: (index, newQuery) => _onEditQuery(index, newQuery, emit),
        clearMessages: () => _onClearMessages(emit),
        loadConversation: (conversationId, title, branches) =>
            _onLoadConversation(conversationId, title, branches, emit),
        switchBranch: (messageIndex, branchIndex) =>
            _onSwitchBranch(messageIndex, branchIndex, emit),
      );
    });
  }

  Future<void> _onInitialize(Emitter<SearchState> emit) async {
    await _searchRemoteDataSource.initialize();
  }

  Future<void> _onLoadConversation(
    String conversationId,
    String title,
    List<MessageBranchManager> branches,
    Emitter<SearchState> emit,
  ) async {
    _conversationManager.loadConversation(conversationId, title, branches);
    emit(
      SearchState.loaded(
        messageBranches: branches,
        isProcessing: false,
        conversationId: conversationId,
        conversationTitle: title,
      ),
    );
  }

  Future<void> _onPerformInitialSearch(
    String query,
    List<dynamic>? attachments,
    String? providedConversationId,
    Emitter<SearchState> emit,
  ) async {
    final branchManager = _conversationManager.startNewConversation(
      query,
      providedId: providedConversationId,
    );

    emit(
      SearchState.loading(
        messageBranches: _conversationManager.state.messageBranches,
        conversationId: _conversationManager.state.conversationId,
        conversationTitle: _conversationManager.state.conversationTitle,
      ),
    );

    try {
      final streamController = StreamController<String>.broadcast();
      String accumulatedAnswer = '';

      // Set up streaming message
      final generatingMessage = branchManager.currentMessage;
      final streamingMessage = generatingMessage.copyWith(
        generationState: MessageGenerationState.searching,
        answerStream: streamController.stream,
      );

      _conversationManager.updateCurrentMessage(streamingMessage);

      // Start the stream
      int tokenBufferCount = 0;
      DateTime lastEmitTime = DateTime.now();

      await _searchRemoteDataSource
          .streamSearch(
            query,
            attachments: attachments,
            isNewConversation: true,
          )
          .forEach((update) {
            // Handle valid title generation
            if (update.generatedTitle != null) {
              print('✨ Smart Title Generated: ${update.generatedTitle}');
              _conversationManager.updateTitle(update.generatedTitle!);
            }

            // Handle token updates or final result
            if (update.finalResult != null) {
              accumulatedAnswer = update.finalResult!.answer;
            } else if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
              tokenBufferCount++;
            }
            print(
              'SearchBloc: Update processed. Answer length: ${accumulatedAnswer.length}. First 50 chars: "${accumulatedAnswer.length > 50 ? accumulatedAnswer.substring(0, 50) : accumulatedAnswer}..."',
            );

            // Map search stream status
            final genState = update.status == SearchStreamStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == SearchStreamStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            final List<SourceItem>? sourceItems = (update.finalResult?.sources.isNotEmpty == true)
                ? update.finalResult!.sources
                : null;

            // Get current message from manager state to ensure we have latest branches
            final currentManagerBranch =
                _conversationManager.state.messageBranches.last;

            final currentMessage = currentManagerBranch.currentMessage.copyWith(
              answer: accumulatedAnswer,
              generationState: genState,
              images: (update.finalResult?.images.isNotEmpty == true)
                  ? update.finalResult!.images
                  : (update.images?.isNotEmpty == true ? update.images : null),
              videos: (update.finalResult?.videos.isNotEmpty == true)
                  ? update.finalResult!.videos
                  : (update.videos?.isNotEmpty == true ? update.videos : null),
              toolWidgets: (update.finalResult?.toolWidgets.isNotEmpty == true)
                  ? update.finalResult!.toolWidgets
                  : null,
              sources:
                  sourceItems ?? currentManagerBranch.currentMessage.sources,
              steps: update.steps ?? currentManagerBranch.currentMessage.steps,
            );

            _conversationManager.updateCurrentMessage(currentMessage);

            // Throttle emissions during streaming to reduce UI jank
            final isStreaming = genState == MessageGenerationState.streaming;
            final hasSignificantUpdate =
                sourceItems != null ||
                (update.images?.isNotEmpty == true) ||
                (update.videos?.isNotEmpty == true) ||
                (update.steps != null && update.status != SearchStreamStatus.streaming);

            final shouldEmit =
                !isStreaming ||
                hasSignificantUpdate ||
                tokenBufferCount >= 10 ||
                DateTime.now().difference(lastEmitTime).inMilliseconds >= 100 ||
                genState == MessageGenerationState.completed;

            if (shouldEmit) {
              tokenBufferCount = 0;
              lastEmitTime = DateTime.now();
              emit(
                SearchState.loading(
                  messageBranches: _conversationManager.state.messageBranches,
                  conversationId: _conversationManager.state.conversationId,
                  conversationTitle:
                      _conversationManager.state.conversationTitle,
                ),
              );
            }
          });

      await streamController.close();

      final currentManagerBranch =
          _conversationManager.state.messageBranches.last;
      final completedMessage = currentManagerBranch.currentMessage.copyWith(
        generationState: MessageGenerationState.completed,
      );

      _conversationManager.updateCurrentMessage(completedMessage);
      _conversationManager.setProcessing(false);

      emit(
        SearchState.loaded(
          messageBranches: _conversationManager.state.messageBranches,
          isProcessing: false,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );

      await _saveConversation();
    } catch (e) {
      print('Search failed: $e');
      _conversationManager.setError(e.toString());
      emit(
        SearchState.error(
          message: e.toString(),
          messageBranches: _conversationManager.state.messageBranches,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );
    }
  }

  Future<void> _onAddNewMessage(
    String query,
    List<AttachmentData>? attachments,
    Emitter<SearchState> emit,
  ) async {
    print('🔔 SearchBloc._onAddNewMessage called');
    print('   query: "$query", attachments: ${attachments?.length ?? 0}');
    print(
      '   current isProcessing: ${_conversationManager.state.isProcessing}',
    );
    print(
      '   current messageBranches count: ${_conversationManager.state.messageBranches.length}',
    );

    final branchManager = _conversationManager.addNewMessage(query);
    if (branchManager == null) {
      print(
        '   ❌ addNewMessage returned null (blocked by isProcessing or empty state)',
      );
      return;
    }
    print(
      '   ✅ New branchManager created, branches now: ${_conversationManager.state.messageBranches.length}',
    );

    emit(
      SearchState.loading(
        messageBranches: _conversationManager.state.messageBranches,
        conversationId: _conversationManager.state.conversationId,
        conversationTitle: _conversationManager.state.conversationTitle,
      ),
    );

    try {
      final streamController = StreamController<String>.broadcast();
      String accumulatedAnswer = '';

      final currentBranches = _conversationManager.state.messageBranches;
      // Construct history
      final conversationHistory = currentBranches
          .take(currentBranches.length - 1)
          .map((bm) => bm.currentMessage)
          .where((m) => m.generationState == MessageGenerationState.completed)
          .toList();

      print(
        '💬 Using conversation history: ${conversationHistory.length} messages',
      );

      final generatingMessage = branchManager.currentMessage;
      final streamingMessage = generatingMessage.copyWith(
        generationState: MessageGenerationState.searching,
        answerStream: streamController.stream,
      );

      _conversationManager.updateCurrentMessage(streamingMessage);

      await _searchRemoteDataSource
          .streamFollowUp(
            query: query,
            previousMessages: conversationHistory,
            attachments: attachments,
            maxHistoryMessages: 5,
          )
          .forEach((update) {
            if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
            }

            final genState = update.status == SearchStreamStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == SearchStreamStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            final List<SourceItem>? sourceItems = (update.finalResult?.sources.isNotEmpty == true)
                ? update.finalResult!.sources
                : null;

            final currentManagerBranch =
                _conversationManager.state.messageBranches.last;
            final currentMessage = currentManagerBranch.currentMessage.copyWith(
              answer: accumulatedAnswer,
              generationState: genState,
              images: (update.finalResult?.images.isNotEmpty == true)
                  ? update.finalResult!.images
                  : (update.images?.isNotEmpty == true ? update.images : null),
              videos: (update.finalResult?.videos.isNotEmpty == true)
                  ? update.finalResult!.videos
                  : (update.videos?.isNotEmpty == true ? update.videos : null),
              toolWidgets: (update.finalResult?.toolWidgets.isNotEmpty == true)
                  ? update.finalResult!.toolWidgets
                  : null,
              sources:
                  sourceItems ?? currentManagerBranch.currentMessage.sources,
              steps: update.steps ?? currentManagerBranch.currentMessage.steps,
            );

            _conversationManager.updateCurrentMessage(currentMessage);

            emit(
              SearchState.loading(
                messageBranches: _conversationManager.state.messageBranches,
                conversationId: _conversationManager.state.conversationId,
                conversationTitle: _conversationManager.state.conversationTitle,
              ),
            );
          });

      await streamController.close();

      final currentManagerBranch =
          _conversationManager.state.messageBranches.last;
      final completedMessage = currentManagerBranch.currentMessage.copyWith(
        generationState: MessageGenerationState.completed,
      );

      _conversationManager.updateCurrentMessage(completedMessage);
      _conversationManager.setProcessing(false);

      emit(
        SearchState.loaded(
          messageBranches: _conversationManager.state.messageBranches,
          isProcessing: false,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );

      await _saveConversation();
    } catch (e) {
      print('Follow-up search failed: $e');
      _conversationManager.setError(e.toString());
      emit(
        SearchState.error(
          message: e.toString(),
          messageBranches: _conversationManager.state.messageBranches,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );
    }
  }

  Future<void> _onRewriteMessage(int index, Emitter<SearchState> emit) async {
    final branchManager = _conversationManager.rewriteMessage(index);
    if (branchManager == null) return;

    emit(
      SearchState.loading(
        messageBranches: _conversationManager.state.messageBranches,
        conversationId: _conversationManager.state.conversationId,
        conversationTitle: _conversationManager.state.conversationTitle,
      ),
    );

    try {
      final streamController = StreamController<String>.broadcast();
      String accumulatedAnswer = '';

      final generatingMessage = branchManager.currentMessage;
      final streamingMessage = generatingMessage.copyWith(
        generationState: MessageGenerationState.searching,
        answerStream: streamController.stream,
      );

      // Mutate local to update manager via updateState
      var allBranches = List<MessageBranchManager>.from(
        _conversationManager.state.messageBranches,
      );
      branchManager.updateCurrentBranch(streamingMessage);
      allBranches[index] = branchManager;
      _conversationManager.updateState(branches: allBranches);

      emit(
        SearchState.loading(
          messageBranches: _conversationManager.state.messageBranches,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );

      final oldMessageQuery = generatingMessage.query;
      final oldMessageAttachments = generatingMessage.attachments;

      await _searchRemoteDataSource
          .streamSearch(
            oldMessageQuery,
            attachments: oldMessageAttachments,
          )
          .forEach((update) {
            if (update.finalResult != null) {
              accumulatedAnswer = update.finalResult!.answer;
            } else if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
            }

            final genState = update.status == SearchStreamStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == SearchStreamStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            final List<SourceItem>? sourceItems = (update.finalResult?.sources.isNotEmpty == true)
                ? update.finalResult!.sources
                : null;

            final currentMessage = branchManager.currentMessage.copyWith(
              answer: accumulatedAnswer,
              generationState: genState,
              images: (update.finalResult?.images.isNotEmpty == true)
                  ? update.finalResult!.images
                  : (update.images?.isNotEmpty == true ? update.images : null),
              videos: (update.finalResult?.videos.isNotEmpty == true)
                  ? update.finalResult!.videos
                  : (update.videos?.isNotEmpty == true ? update.videos : null),
              toolWidgets: (update.finalResult?.toolWidgets.isNotEmpty == true)
                  ? update.finalResult!.toolWidgets
                  : null,
              sources: sourceItems ?? branchManager.currentMessage.sources,
              steps: update.steps ?? branchManager.currentMessage.steps,
            );

            branchManager.updateCurrentBranch(currentMessage);

            allBranches = List<MessageBranchManager>.from(
              _conversationManager.state.messageBranches,
            );
            allBranches[index] = branchManager;
            _conversationManager.updateState(branches: allBranches);

            emit(
              SearchState.loading(
                messageBranches: _conversationManager.state.messageBranches,
                conversationId: _conversationManager.state.conversationId,
                conversationTitle: _conversationManager.state.conversationTitle,
              ),
            );
          });

      await streamController.close();

      final completedMessage = branchManager.currentMessage.copyWith(
        generationState: MessageGenerationState.completed,
      );

      branchManager.updateCurrentBranch(completedMessage);

      allBranches = List<MessageBranchManager>.from(
        _conversationManager.state.messageBranches,
      );
      allBranches[index] = branchManager;
      _conversationManager.updateState(
        branches: allBranches,
        isProcessing: false,
      );

      emit(
        SearchState.loaded(
          messageBranches: _conversationManager.state.messageBranches,
          isProcessing: false,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );
    } catch (e) {
      print('Rewrite failed: $e');
      _conversationManager.setError(e.toString());
      emit(
        SearchState.error(
          message: e.toString(),
          messageBranches: _conversationManager.state.messageBranches,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );
    }
  }

  Future<void> _onEditQuery(
    int index,
    String newQuery,
    Emitter<SearchState> emit,
  ) async {
    final branchManager = _conversationManager.editQuery(index, newQuery);
    if (branchManager == null) return;

    emit(
      SearchState.loading(
        messageBranches: _conversationManager.state.messageBranches,
        conversationId: _conversationManager.state.conversationId,
        conversationTitle: _conversationManager.state.conversationTitle,
      ),
    );

    try {
      final streamController = StreamController<String>.broadcast();
      String accumulatedAnswer = '';

      final generatingMessage = branchManager.currentMessage;
      final streamingMessage = generatingMessage.copyWith(
        generationState: MessageGenerationState.searching,
        answerStream: streamController.stream,
      );

      var allBranches = List<MessageBranchManager>.from(
        _conversationManager.state.messageBranches,
      );
      branchManager.updateCurrentBranch(streamingMessage);
      allBranches[index] = branchManager;
      _conversationManager.updateState(branches: allBranches);

      emit(
        SearchState.loading(
          messageBranches: _conversationManager.state.messageBranches,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );

      await _searchRemoteDataSource
          .streamSearch(
            newQuery,
            attachments: generatingMessage.attachments,
          )
          .forEach((update) {
            if (update.finalResult != null) {
              accumulatedAnswer = update.finalResult!.answer;
            } else if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
            }

            final genState = update.status == SearchStreamStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == SearchStreamStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            final List<SourceItem>? sourceItems = (update.finalResult?.sources.isNotEmpty == true)
                ? update.finalResult!.sources
                : null;

            final currentMessage = branchManager.currentMessage.copyWith(
              answer: accumulatedAnswer,
              generationState: genState,
              images: (update.finalResult?.images.isNotEmpty == true)
                  ? update.finalResult!.images
                  : (update.images?.isNotEmpty == true ? update.images : null),
              videos: (update.finalResult?.videos.isNotEmpty == true)
                  ? update.finalResult!.videos
                  : (update.videos?.isNotEmpty == true ? update.videos : null),
              toolWidgets: (update.finalResult?.toolWidgets.isNotEmpty == true)
                  ? update.finalResult!.toolWidgets
                  : null,
              sources: sourceItems ?? branchManager.currentMessage.sources,
              steps: update.steps ?? branchManager.currentMessage.steps,
            );

            branchManager.updateCurrentBranch(currentMessage);

            allBranches = List<MessageBranchManager>.from(
              _conversationManager.state.messageBranches,
            );
            allBranches[index] = branchManager;
            _conversationManager.updateState(branches: allBranches);

            emit(
              SearchState.loading(
                messageBranches: _conversationManager.state.messageBranches,
                conversationId: _conversationManager.state.conversationId,
                conversationTitle: _conversationManager.state.conversationTitle,
              ),
            );
          });

      await streamController.close();

      final completedMessage = branchManager.currentMessage.copyWith(
        generationState: MessageGenerationState.completed,
      );

      branchManager.updateCurrentBranch(completedMessage);

      allBranches = List<MessageBranchManager>.from(
        _conversationManager.state.messageBranches,
      );
      allBranches[index] = branchManager;
      _conversationManager.updateState(
        branches: allBranches,
        isProcessing: false,
      );

      emit(
        SearchState.loaded(
          messageBranches: _conversationManager.state.messageBranches,
          isProcessing: false,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );
    } catch (e) {
      print('Edit query failed: $e');
      _conversationManager.setError(e.toString());
      emit(
        SearchState.error(
          message: e.toString(),
          messageBranches: _conversationManager.state.messageBranches,
          conversationId: _conversationManager.state.conversationId,
          conversationTitle: _conversationManager.state.conversationTitle,
        ),
      );
    }
  }

  Future<void> _onClearMessages(Emitter<SearchState> emit) async {
    _conversationManager.clearConversation();
    emit(const SearchState.initial());
  }

  Future<void> _onSwitchBranch(
    int messageIndex,
    int branchIndex,
    Emitter<SearchState> emit,
  ) async {
    _conversationManager.switchBranch(messageIndex, branchIndex);

    emit(
      SearchState.loaded(
        messageBranches: _conversationManager.state.messageBranches,
        isProcessing: false,
        conversationId: _conversationManager.state.conversationId,
        conversationTitle: _conversationManager.state.conversationTitle,
      ),
    );
  }

  Future<void> _saveConversation() async {
    final state = this.state;
    if (!state.hasActiveConversation) return;

    final conversationId = state.conversationId;
    final title = state.conversationTitle;
    final messages = state.messageBranches;

    if (conversationId == null || title == null) return;

    // Check if there are any completed messages to save
    final hasCompletedMessage = messages.any(
      (branch) =>
          branch.currentMessage.generationState ==
          MessageGenerationState.completed,
    );

    if (!hasCompletedMessage) return;

    try {
      // Check if conversation already exists to decide between save (new) or update
      final existing = await _conversationDatabaseService
          .getConversationByConversationId(conversationId);

      if (existing == null) {
        await _conversationDatabaseService.saveConversation(
          conversationId: conversationId,
          title: title,
          messageBranches: messages,
        );
      } else {
        await _conversationDatabaseService.updateConversation(
          conversationId: conversationId,
          title: title, // Update title just in case it changed
          messageBranches: messages,
        );
      }
    } catch (e) {
      print('Failed to auto-save conversation: $e');
    }
  }
}
