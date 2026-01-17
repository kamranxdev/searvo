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

import '../../rag/services/verification/source_verifier.dart';
import '../../rag/services/verification/confidence_scorer.dart';
import '../../rag/services/query_processing/query_analyzer.dart';

/// Advanced RAG orchestrator with attachment support, conversation history, and intelligent web scraping
class RAGDataSource {
  final SearXNGRemoteDataSource _searxngService;
  final LLMProviderManager _llmManager;
  final QueryAnalyzer _queryAnalyzer;
  final RAGScraperAdapter _scraperAdapter;
  final LangChainService _langChainService;
  final QdrantVectorStore _vectorStore;
  final Map<String, dynamic> _performanceMetrics = {};

  // Verification services (no LLM calls)
  final SourceVerifier _sourceVerifier = SourceVerifier();
  final ConfidenceScorer _confidenceScorer = ConfidenceScorer();

  late final List<AgentTool> _tools;

  RAGDataSource({
    SearXNGRemoteDataSource? searxngService,
    LLMProviderManager? llmManager,
    QueryAnalyzer? queryAnalyzer,
    RAGScraperAdapter? scraperAdapter,
    LangChainService? langChainService,
    QdrantVectorStore? vectorStore,
  }) : _searxngService = searxngService ?? SearXNGRemoteDataSource(),
       _llmManager = llmManager ?? LLMProviderManager(),
       _queryAnalyzer = queryAnalyzer ?? QueryAnalyzer(),
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

    // Add to Vector Store (Indexing) with Fallback
    bool isVectorStoreAvailable = true;
    try {
      // Note: We should probably clear old context or use a unique collection/session.
      // For this refactor, just add.
      await _vectorStore.addDocuments(documents: lcDocuments);

      updateStep(
        processingStep.id,
        status: SearchStepStatus.completed,
        description: "Indexed ${lcDocuments.length} documents",
      );
    } catch (e) {
      print('Vector Store unavailable: $e');
      isVectorStoreAvailable = false;
      updateStep(
        processingStep.id,
        status: SearchStepStatus.completed,
        description: "Knowledge Base offline - using fresh results",
      );
    }

    // 3. Retrieval & Generation
    final thinkingStep = createStep("Generating answer");
    yield RAGUpdate(status: RAGStatus.thinking, steps: List.from(steps));

    List<lc.Document> retrievedDocs;
    if (isVectorStoreAvailable) {
      try {
        // Use LangChain to query
        final chainResult = await _langChainService.query(
          query,
          vectorStore: _vectorStore,
          k: maxRelevantDocuments,
        );
        retrievedDocs = chainResult['docs'] as List<lc.Document>;
      } catch (e) {
        print('Vector Store query failed: $e');
        // Fallback to top documents if query fails
        retrievedDocs = lcDocuments.take(maxRelevantDocuments).toList();
      }
    } else {
      // Direct usage of documents if Vector Store is down
      retrievedDocs = lcDocuments.take(maxRelevantDocuments).toList();
    }

    final StringBuffer fullAnswer = StringBuffer();

    // Generate Answer with Retry Logic for Rate Limits
    int retryCount = 0;
    const maxRetries = 3;
    bool generationSuccess = false;

    while (!generationSuccess && retryCount <= maxRetries) {
      try {
        // Use LangChainService to generate the answer stream
        await for (final token in _langChainService.generateAnswer(
          query,
          retrievedDocs,
          previousMessages: previousMessages,
        )) {
          fullAnswer.write(token);
          yield RAGUpdate(
            status: RAGStatus.streaming,
            token: token,
            steps: List.from(steps),
          );
        }
        generationSuccess = true;
      } catch (e) {
        final errorStr = e.toString();
        // Check for Rate Limit (429) or Quota Exceeded
        if (errorStr.contains('429') ||
            errorStr.toLowerCase().contains('quota') ||
            errorStr.toLowerCase().contains('rate limit')) {
          retryCount++;
          if (retryCount <= maxRetries) {
            updateStep(
              thinkingStep.id,
              description: "Rate limit hit. Retrying in ${2 * retryCount}s...",
            );
            yield RAGUpdate(
              status: RAGStatus.thinking,
              steps: List.from(steps),
            );

            await Future.delayed(Duration(seconds: 2 * retryCount));
            // Create a fresh buffer for the retry?
            // Usually we want to clear partial answer if it failed midway,
            // but RateLimit usually fails at the start.
            if (fullAnswer.isNotEmpty) {
              // If we already had content and it failed mid-stream,
              // we technically might be duplicating or losing context.
              // For now, simpler to clear and restart or keep appending?
              // Rate limit unlikely checks in mid-stream, usually at start.
              fullAnswer.clear();
            }
            continue;
          }
        }

        // If not rate limit or retries exhausted
        print('Generation failed: $e');
        updateStep(
          thinkingStep.id,
          status: SearchStepStatus.failed,
          description: "Generation failed: $e",
        );

        // Yield a friendly error helper if we haven't yielded anything yet
        if (fullAnswer.isEmpty) {
          fullAnswer.write(
            "I apologize, but I'm currently experiencing high traffic or connection issues. Here is what I found from the search results:\n\n",
          );
          // Append simple summary of sources
          for (var doc in retrievedDocs.take(3)) {
            fullAnswer.write(
              "- ${doc.metadata['title']}: ${doc.pageContent.substring(0, 100)}...\n",
            );
          }
          generationSuccess = true; // Treat fallback as success
        } else {
          // We already streamed some content, just stop.
          generationSuccess = true;
        }
      }
    }

    if (!generationSuccess && fullAnswer.isEmpty) {
      // Should have been handled in catch block fallback, but just in case
      fullAnswer.write("Unable to generate response due to repeated errors.");
    }

    updateStep(thinkingStep.id, status: SearchStepStatus.completed);

    // Verify response quality (no LLM calls - pure algorithmic)
    final answerText = fullAnswer.toString();
    final verification = _sourceVerifier.verifyResponse(
      answerText,
      allRawDocuments,
    );
    final confidence = _confidenceScorer.calculateScore(
      answerText,
      allRawDocuments,
    );

    print(
      '📊 Response verification: ${verification.confidenceLevel} (${(verification.overallScore * 100).toStringAsFixed(1)}%)',
    );
    print(
      '📊 Confidence score: ${confidence.level} (${confidence.percentage}%)',
    );
    if (verification.unverifiedEntities.isNotEmpty) {
      print(
        '⚠️ Unverified entities: ${verification.unverifiedEntities.take(3).join(", ")}',
      );
    }

    // Convert raw documents to SourceItems for the final result
    final sourceItems = allRawDocuments
        .map(
          (doc) => SourceItem(
            title: doc.title,
            url: doc.url,
            description: doc.snippet,
            thumbnail: doc.metadata['thumbnail'] ?? '',
            domain: doc.source,
            source: doc.source,
            publishedDate: doc.publishedDate,
          ),
        )
        .toList();

    yield RAGUpdate(
      status: RAGStatus.completed,
      finalResult: MessageData(
        query: query,
        answer: answerText,
        steps: steps,
        sources: sourceItems,
        confidenceScore: confidence.percentage,
        confidenceLevel: confidence.level,
      ),
      steps: List.from(steps),
      documents: allRawDocuments,
    );
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
      final fallbackPrompt = _langChainService.createFallbackPrompt(query);
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
    return _queryAnalyzer.validateQuery(query);
  }

  String enhanceQuery(String query) {
    return _queryAnalyzer.enhanceQuery(query);
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
    final validation = _queryAnalyzer.validateQuery(query);
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
