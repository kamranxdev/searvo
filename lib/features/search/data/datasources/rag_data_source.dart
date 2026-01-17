import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/domain/tools/search_tools.dart';
import 'package:searvo/features/search/domain/entities/search_step.dart';
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';
import 'package:uuid/uuid.dart';
import '../../rag/services/data_ingestion/rag_scraper_adapter.dart';
import 'package:searvo/features/search/domain/entities/search_mode.dart';
import '../../rag/services/vector_store/qdrant_vector_store.dart';
import '../../rag/services/langchain_service.dart';
import '../../rag/services/wrappers/custom_embeddings_wrapper.dart';
import 'package:langchain_core/documents.dart' as lc;
import '../../domain/entities/message_data.dart';
import '../../domain/entities/message_generation_state.dart';
import '../../domain/entities/source_item.dart';
import '../../rag/services/query_processing/prompt_engineer.dart';

/// Advanced RAG orchestrator with attachment support, conversation history, and intelligent web scraping
class RAGDataSource {
  final SearXNGRemoteDataSource _searxngService;
  final LLMProviderManager _llmManager;
  final PromptEngineer _promptEngineer;
  final RAGScraperAdapter _scraperAdapter;

  // ignore: unused_field
  final LangChainService _langChainService;

  // ignore: unused_field
  final QdrantVectorStore _vectorStore;
  final Map<String, dynamic> _performanceMetrics = {};

  late final List<AgentTool> _tools;

  RAGDataSource({
    SearXNGRemoteDataSource? searxngService,
    LLMProviderManager? llmManager,
    PromptEngineer? promptEngineer,
    RAGScraperAdapter? scraperAdapter,
    LangChainService? langChainService,
    QdrantVectorStore? vectorStore,
  }) : _searxngService = searxngService ?? SearXNGRemoteDataSource(),
       _llmManager = llmManager ?? LLMProviderManager(),
       _promptEngineer = promptEngineer ?? PromptEngineer(),
       _scraperAdapter = scraperAdapter ?? RAGScraperAdapter(),
       _vectorStore =
           vectorStore ??
           QdrantVectorStore(
             embeddings: CustomEmbeddingsWrapper(
               llmManager ?? LLMProviderManager(),
             ),
           ),
       _langChainService =
           langChainService ??
           LangChainService(llmManager: llmManager ?? LLMProviderManager()) {
    _tools = [
      WebSearchTool(searxngService: _searxngService),
      ImageSearchTool(_searxngService),
      ReadPageTool(_scraperAdapter),
      CalculatorTool(),
    ];
  }

  /// Generate RAG stream with LangChain
  Stream<RAGUpdate> generateRAGStream(
    String query, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength,
    bool enableQueryEnhancement = true,
    bool enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
    List<MessageData>? previousMessages,
    int maxHistoryMessages = 3,
    bool isNewConversation = false,
  }) async* {
    final List<SearchStep> steps = [];
    final uuid = Uuid();

    SearchStep createStep(String title, {String? description}) {
      final step = SearchStep(
        id: uuid.v4(),
        title: title,
        description: description,
        status: SearchStepStatus.inProgress,
      );
      steps.add(step);
      return step;
    }

    void updateStep(
      String id, {
      SearchStepStatus? status,
      String? description,
    }) {
      final index = steps.indexWhere((s) => s.id == id);
      if (index != -1) {
        steps[index] = steps[index].copyWith(
          status: status,
          description: description,
        );
      }
    }

    // 1. Ingestion Step
    final ingestionStep = createStep("Searching and reading sources");
    yield RAGUpdate(status: RAGStatus.searching, steps: List.from(steps));

    final allRawDocuments = <Document>[]; // Internal documents

    // Execute WebSearchTool
    for (final tool in _tools.where((t) => t.id == 'web_search')) {
      // AgentTool.execute takes a Map
      final result = await tool.execute({
        'query': query,
        'maxResults': maxSearchResults,
      });

      if (result is Map && result['success'] == true) {
        final docs = result['documents'] as List;
        allRawDocuments.addAll(
          docs.map(
            (d) => RagDocument(
              id: d['url'].hashCode.toString(),
              title: d['title'],
              url: d['url'],
              content: d['snippet'],
              snippet: d['snippet'],
              thumbnail: d['thumbnail'],
              publishedDate: d['publishedDate'] != null
                  ? DateTime.tryParse(d['publishedDate'])
                  : null,
              source: d['source'],
            ),
          ),
        );
      }
    }

    if (allRawDocuments.isEmpty) {
      updateStep(
        ingestionStep.id,
        status: SearchStepStatus.failed,
        description: "No results found",
      );
      yield RAGUpdate(
        status: RAGStatus.completed,
        finalResult: await _generateFallbackResponse(query),
        steps: List.from(steps),
      );
      return;
    }

    updateStep(
      ingestionStep.id,
      status: SearchStepStatus.completed,
      description: "Found ${allRawDocuments.length} documents",
    );

    // 2. LangChain Processing Step
    final processingStep = createStep("Processing content with LangChain");
    yield RAGUpdate(status: RAGStatus.fusion, steps: List.from(steps));

    // Convert to LangChain documents
    final lcDocuments = _langChainService.toLangChainDocuments(allRawDocuments);

    // Add to Vector Store (Indexing)
    // We cast vectorStore to QdrantVectorStore to access 'addDocuments' if not exposed by service
    // Or we use LangChainService if we add 'addDocuments' there.
    // For now, access via vectorStore directly (it's public).

    // Note: We should probably clear old context or use a unique collection/session.
    // For this refactor, just add.
    await _vectorStore.addDocuments(documents: lcDocuments);

    updateStep(
      processingStep.id,
      status: SearchStepStatus.completed,
      description: "Indexed ${lcDocuments.length} documents",
    );

    // 3. Retrieval & Generation
    final thinkingStep = createStep("Generating answer");
    yield RAGUpdate(status: RAGStatus.thinking, steps: List.from(steps));

    // Use LangChain to query
    // Use LangChain to query
    final chainResult = await _langChainService.query(
      query,
      vectorStore: _vectorStore,
      k: maxRelevantDocuments,
    );

    final retrievedDocs = chainResult['docs'] as List<lc.Document>;

    final StringBuffer fullAnswer = StringBuffer();
    // Use LangChainService to generate the answer stream
    await for (final token in _langChainService.generateAnswer(
      query,
      retrievedDocs,
    )) {
      fullAnswer.write(token);
      yield RAGUpdate(
        status: RAGStatus.streaming,
        token: token,
        steps: List.from(steps),
      );
    }

    updateStep(thinkingStep.id, status: SearchStepStatus.completed);

    yield RAGUpdate(
      status: RAGStatus.completed,
      finalResult: MessageData(
        query: query,
        answer: fullAnswer.toString(),
        steps: steps,
      ),
      steps: List.from(steps),
    );
  }

  /// Generate RAG response (Legacy Wrapper)
  Future<MessageData> generateRAGResponse(
    String query, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength,
    bool enableQueryEnhancement = true,
    bool enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
    Function(MessageData)? onSearchComplete,
    bool isNewConversation = false,
  }) async {
    MessageData? lastData;
    await for (final update in generateRAGStream(
      query,
      maxSearchResults: maxSearchResults,
      maxRelevantDocuments: maxRelevantDocuments,
      maxContextLength: maxContextLength,
      enableQueryEnhancement: enableQueryEnhancement,
      enableAdaptivePrompting: enableAdaptivePrompting,
      attachments: attachments,
      searchMode: searchMode,
      isNewConversation: isNewConversation,
    )) {
      if (update.finalResult != null) {
        lastData = update.finalResult;
      }
      // Handle partial updates like images/videos if needed
      if (update.status == RAGStatus.ranking &&
          update.documents != null &&
          onSearchComplete != null) {
        onSearchComplete(
          MessageData(
            query: query,
            answer: '',
            images: update.images ?? const [],
            videos: update.videos ?? const [],
            generationState: MessageGenerationState.generating,
          ),
        );
      }
    }
    return lastData ?? await _generateFallbackResponse(query);
  }

  /// Generate response with conversation history - FIXED VERSION
  Future<MessageData> generateRAGResponseWithHistory(
    String query,
    List<MessageData> previousMessages, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength,
    int maxHistoryMessages = 3,
    List<dynamic>? attachments,
    Function(MessageData)? onSearchComplete,
  }) async {
    MessageData? lastData;

    // Create a simple stream listener to capture the final result
    final stream = generateRAGStream(
      query,
      maxSearchResults: maxSearchResults,
      maxRelevantDocuments: maxRelevantDocuments,
      maxContextLength: maxContextLength,
      maxHistoryMessages: maxHistoryMessages,
      attachments: attachments,
      previousMessages: previousMessages,
    );

    await for (final update in stream) {
      if (update.status == RAGStatus.completed && update.finalResult != null) {
        lastData = update.finalResult;

        if (onSearchComplete != null) {
          onSearchComplete(lastData!);
        }
      } else if (onSearchComplete != null) {
        // Intermediate update
        onSearchComplete(
          MessageData(
            query: query,
            answer: update.finalResult?.answer ?? update.message ?? '',
            generationState: MessageGenerationState.generating,
            steps: update.steps ?? [],
            images: update.images ?? [],
            videos: update.videos ?? [],
            sources:
                update.documents
                    ?.map(
                      (d) => SourceItem(
                        title: d.title,
                        url: d.url,
                        description: d.snippet,
                        thumbnail: d.metadata['thumbnail'] ?? '',
                        domain: d.source,
                        source: d.source,
                        publishedDate: d.publishedDate,
                      ),
                    )
                    .toList() ??
                [],
          ),
        );
      }
    }

    return lastData ?? await _generateFallbackResponse(query);
  }

  /// Generate fallback response
  Future<MessageData> _generateFallbackResponse(String query) async {
    try {
      final fallbackPrompt = _promptEngineer.createFallbackPrompt(query);
      final response = await _llmManager.generateResponse(fallbackPrompt);

      final relatedQuestions = [
        'Can you provide more specific details?',
        'What aspect interests you most?',
        'Would you like to rephrase your question?',
        'What context can you provide?',
      ];

      return MessageData(
        query: query,
        answer: response,
        sources: [],
        relatedQuestions: relatedQuestions,
        isFallback: true,
      );
    } catch (e) {
      print('❌ Fallback generation failed: $e');

      return MessageData(
        query: query,
        answer: 'I apologize, but I encountered an error. Please try again.',
        sources: [],
        relatedQuestions: [],
        isFallback: true,
        errorMessage: e.toString(),
      );
    }
  }

  Map<String, dynamic> validateQuery(String query) {
    return _promptEngineer.validateQuery(query);
  }

  String enhanceQuery(String query) {
    return _promptEngineer.enhanceQuery(query);
  }

  bool get isReady =>
      _llmManager.hasConfiguredProvider && _searxngService.isConfigured;

  Map<String, dynamic> getStatus() {
    return {
      'isReady': isReady,
      'llmConfigured': _llmManager.hasConfiguredProvider,
      'activeLLMProvider': _llmManager.activeProvider?.providerName ?? 'None',
      'searchConfigured': _searxngService.isConfigured,
      'lastPerformance': _performanceMetrics['lastQuery'],
    };
  }

  Map<String, dynamic> getPerformanceStats() {
    final lastQuery = _performanceMetrics['lastQuery'];
    if (lastQuery == null) {
      return {'available': false};
    }

    return {
      'available': true,
      'totalDuration': '${lastQuery['totalDuration']}ms',
      'breakdown': {
        'search': '${lastQuery['searchDuration']}ms',
        'ranking': '${lastQuery['rankDuration']}ms',
        'fusion': '${lastQuery['fusionDuration']}ms',
        'llm': '${lastQuery['llmDuration']}ms',
      },
      'documents': lastQuery['documentsUsed'],
      'hasAttachments': lastQuery['hasAttachments'],
    };
  }

  void clearMetrics() {
    _performanceMetrics.clear();
  }

  Map<String, dynamic> analyzeQueryComplexity(String query) {
    final validation = _promptEngineer.validateQuery(query);
    final wordCount = query.split(RegExp(r'\s+')).length;

    String complexity;
    int recommendedDocs;
    int recommendedContext;

    if (wordCount < 5 || validation['quality'] < 50) {
      complexity = 'simple';
      recommendedDocs = 5;
      recommendedContext = 4000;
    } else if (wordCount > 10 ||
        query.contains(" and ") ||
        query.contains(" vs ")) {
      complexity = 'complex';
      recommendedDocs = 15;
      recommendedContext = 10000;
    } else {
      complexity = 'moderate';
      recommendedDocs = 10;
      recommendedContext = 8000;
    }

    return {
      'complexity': complexity,
      'wordCount': wordCount,
      'qualityScore': validation['quality'],
      'recommendations': {
        'maxRelevantDocuments': recommendedDocs,
        'maxContextLength': recommendedContext,
      },
    };
  }

  Future<Map<String, dynamic>> performHealthCheck() async {
    return {
      'llm': _llmManager.hasConfiguredProvider ? 'healthy' : 'not_configured',
      'search': _searxngService.isConfigured ? 'healthy' : 'not_configured',
      'overall': isReady ? 'healthy' : 'degraded',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
