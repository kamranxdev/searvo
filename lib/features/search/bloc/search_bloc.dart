import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../models/message_data.dart';
import '../models/message_branch_model.dart';
import '../services/search_service.dart';
import '../services/conversation_manager.dart';
import '../models/search_mode.dart';
import '../../../common/widgets/attachment_input_widget.dart';
import '../rag/models/rag_models.dart';
import '../../history/services/conversation_sync_service.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService _searchService;
  final ConversationManager _conversationManager;
  final ConversationSyncService _conversationSyncService;

  SearchBloc({
    required SearchService searchService,
    required ConversationSyncService conversationSyncService,
    ConversationManager? conversationManager,
  }) : _searchService = searchService,
       _conversationSyncService = conversationSyncService,
       _conversationManager = conversationManager ?? ConversationManager(),
       super(const SearchState.initial()) {
    on<SearchEvent>((event, emit) async {
      await event.when(
        initialize: () => _onInitialize(emit),
        performInitialSearch:
            (query, searchMode, attachments, conversationId) =>
                _onPerformInitialSearch(
                  query,
                  searchMode,
                  attachments,
                  conversationId,
                  emit,
                ),
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
    await _searchService.initialize();
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
    SearchMode searchMode,
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

      await _searchService
          .generateSearchStream(
            query,
            attachments: attachments,
            searchMode: searchMode,
          )
          .forEach((update) {
            // Handle token updates or final result
            if (update.finalResult != null) {
              accumulatedAnswer = update.finalResult!.answer;
            } else if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
              tokenBufferCount++;
            }

            // Map RAG status
            final genState = update.status == RAGStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == RAGStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            // Map documents
            List<SourceItem>? sourceItems;
            if (update.documents != null && update.documents!.isNotEmpty) {
              sourceItems = update.documents!
                  .map(
                    (d) => SourceItem(
                      thumbnail: d.metadata['thumbnail'] ?? '',
                      url: d.url,
                      title: d.title,
                      description: d.snippet,
                      domain: d.source,
                      source: d.source,
                      publishedDate: d.publishedDate,
                    ),
                  )
                  .toList();
            } else if (update.finalResult != null &&
                update.finalResult!.sources.isNotEmpty) {
              sourceItems = update.finalResult!.sources;
            }

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
                (update.steps != null && update.status != RAGStatus.streaming);

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
    final branchManager = _conversationManager.addNewMessage(query);
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

      await _searchService
          .generateFollowUpStream(
            query,
            conversationHistory,
            attachments: attachments,
            maxHistoryMessages: 5,
          )
          .forEach((update) {
            if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
            }

            final genState = update.status == RAGStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == RAGStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            List<SourceItem>? sourceItems;
            if (update.documents != null && update.documents!.isNotEmpty) {
              sourceItems = update.documents!
                  .map(
                    (d) => SourceItem(
                      thumbnail: d.metadata['thumbnail'] ?? '',
                      url: d.url,
                      title: d.title,
                      description: d.snippet,
                      domain: d.source,
                      source: d.source,
                      publishedDate: d.publishedDate,
                    ),
                  )
                  .toList();
            } else if (update.finalResult != null &&
                update.finalResult!.sources.isNotEmpty) {
              sourceItems = update.finalResult!.sources;
            }

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

      await _searchService
          .generateSearchStream(
            oldMessageQuery,
            attachments: oldMessageAttachments,
            searchMode: SearchMode.search,
          )
          .forEach((update) {
            if (update.finalResult != null) {
              accumulatedAnswer = update.finalResult!.answer;
            } else if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
            }

            final genState = update.status == RAGStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == RAGStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            List<SourceItem>? sourceItems;
            if (update.documents != null && update.documents!.isNotEmpty) {
              sourceItems = update.documents!
                  .map(
                    (d) => SourceItem(
                      thumbnail: d.metadata['thumbnail'] ?? '',
                      url: d.url,
                      title: d.title,
                      description: d.snippet,
                      domain: d.source,
                      source: d.source,
                      publishedDate: d.publishedDate,
                    ),
                  )
                  .toList();
            } else if (update.finalResult != null &&
                update.finalResult!.sources.isNotEmpty) {
              sourceItems = update.finalResult!.sources;
            }

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

      await _searchService
          .generateSearchStream(
            newQuery,
            attachments: generatingMessage.attachments,
            searchMode: SearchMode.search,
          )
          .forEach((update) {
            if (update.finalResult != null) {
              accumulatedAnswer = update.finalResult!.answer;
            } else if (update.token != null) {
              accumulatedAnswer += update.token!;
              streamController.add(update.token!);
            }

            final genState = update.status == RAGStatus.streaming
                ? MessageGenerationState.streaming
                : update.status == RAGStatus.completed
                ? MessageGenerationState.completed
                : MessageGenerationState.generating;

            List<SourceItem>? sourceItems;
            if (update.documents != null && update.documents!.isNotEmpty) {
              sourceItems = update.documents!
                  .map(
                    (d) => SourceItem(
                      thumbnail: d.metadata['thumbnail'] ?? '',
                      url: d.url,
                      title: d.title,
                      description: d.snippet,
                      domain: d.source,
                      source: d.source,
                      publishedDate: d.publishedDate,
                    ),
                  )
                  .toList();
            } else if (update.finalResult != null &&
                update.finalResult!.sources.isNotEmpty) {
              sourceItems = update.finalResult!.sources;
            }

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
      final existing = await _conversationSyncService.getConversationById(
        conversationId,
      );

      if (existing == null) {
        await _conversationSyncService.saveConversation(
          conversationId: conversationId,
          title: title,
          messageBranches: messages,
        );
      } else {
        await _conversationSyncService.updateConversation(
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
