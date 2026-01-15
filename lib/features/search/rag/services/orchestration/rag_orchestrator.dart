import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/context_window_config.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/services/searxng_service.dart';
import 'package:searvo/features/search/services/search_cache_service.dart';
import 'package:searvo/features/search/services/intent/intent_classifier.dart';
import 'package:searvo/features/search/models/search_intent.dart';
import 'package:searvo/features/search/tools/search_tools.dart';
import 'package:searvo/features/search/models/search_step.dart';
import 'package:uuid/uuid.dart';
import '../query_processing/query_analyzer.dart';
import '../data_ingestion/rag_scraper_adapter.dart';
import 'package:searvo/features/search/models/search_mode.dart';

import '../../../models/message_data.dart';
import '../document_processing/document_ranker.dart';

import '../document_processing/context_fusion.dart';
import '../citation/citation_manager.dart';
import '../query_processing/prompt_engineer.dart';
import '../data_ingestion/attachment_processor.dart';

/// Advanced RAG orchestrator with attachment support, conversation history, and intelligent web scraping
class RAGOrchestrator {
  final SearXNGService _searxngService;
  final DocumentRanker _documentRanker;

  final ContextFusion _contextFusion;
  final CitationManager _citationManager;
  final LLMProviderManager _llmManager;
  final PromptEngineer _promptEngineer;
  final AttachmentProcessor _attachmentProcessor;
  final QueryAnalyzer _queryAnalyzer;
  final RAGScraperAdapter _scraperAdapter;

  final IntentClassifier _intentClassifier;
  late final List<SearchTool> _tools;

  final Map<String, dynamic> _performanceMetrics = {};

  RAGOrchestrator({
    SearXNGService? searxngService,
    DocumentRanker? documentRanker,

    ContextFusion? contextFusion,
    CitationManager? citationManager,
    LLMProviderManager? llmManager,
    PromptEngineer? promptEngineer,
    AttachmentProcessor? attachmentProcessor,
    QueryAnalyzer? queryAnalyzer,
    RAGScraperAdapter? scraperAdapter,
    SearchCacheService? cacheService,
    IntentClassifier? intentClassifier,
  }) : _searxngService = searxngService ?? SearXNGService(),
       _documentRanker = documentRanker ?? DocumentRanker(),

       _contextFusion = contextFusion ?? ContextFusion(),
       _citationManager = citationManager ?? CitationManager(),
       _llmManager = llmManager ?? LLMProviderManager(),
       _promptEngineer = promptEngineer ?? PromptEngineer(),
       _attachmentProcessor = attachmentProcessor ?? AttachmentProcessor(),
       _queryAnalyzer = queryAnalyzer ?? QueryAnalyzer(),
       _scraperAdapter = scraperAdapter ?? RAGScraperAdapter(),
       _intentClassifier = intentClassifier ?? IntentClassifier() {
    _tools = [WebSearchTool(_searxngService), ImageSearchTool(_searxngService)];
  }

  /// Get adaptive context length based on current LLM provider and model
  Future<int> _getAdaptiveContextLength({
    int? overrideLength,
    String? complexity,
  }) async {
    // If override provided, use it
    if (overrideLength != null && overrideLength > 0) return overrideLength;

    try {
      final providerName =
          await LLMProviderManager.getActiveProviderName() ?? 'openai';

      String modelName = '';

      // Parse provider type from name
      final providerLower = providerName.toLowerCase();
      if (providerLower.contains('openai')) {
        modelName = await LLMProviderManager.getOpenAIModel();
      } else if (providerLower.contains('google') ||
          providerLower.contains('gemini')) {
        modelName = await LLMProviderManager.getGoogleModel();
      } else if (providerLower.contains('ollama')) {
        modelName = await LLMProviderManager.getOllamaModel();
      } else if (providerLower.contains('anthropic')) {
        modelName = await LLMProviderManager.getAnthropicModel();
      } else if (providerLower.contains('openrouter')) {
        modelName = await LLMProviderManager.getOpenRouterModel();
      } else {
        modelName = 'default';
      }

      // Get context length based on complexity if provided
      if (complexity != null) {
        final adaptiveLength = ContextWindowConfig.getRecommendedContextLength(
          providerName,
          modelName,
          complexity,
        );
        print(
          '📊 Adaptive context length: $adaptiveLength chars for $providerName/$modelName ($complexity complexity)',
        );
        return adaptiveLength;
      }

      // Otherwise get maximum context length
      final maxLength = ContextWindowConfig.getMaxContextLength(
        providerName,
        modelName,
      );
      print(
        '📊 Maximum context length: $maxLength chars for $providerName/$modelName',
      );
      return maxLength;
    } catch (e) {
      print('⚠️  Failed to get adaptive context length, using default: $e');
      return 32000; // Safe default for modern LLMs
    }
  }

  /// Generate RAG stream with optional history support
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
  }) async* {
    final List<SearchStep> steps = [];
    final uuid = Uuid();

    // Helper to emit step update
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
      Duration? duration,
    }) {
      final index = steps.indexWhere((s) => s.id == id);
      if (index != -1) {
        steps[index] = steps[index].copyWith(
          status: status,
          description: description,
          duration: duration,
        );
      }
    }

    // Initial yield
    yield RAGUpdate(
      status: RAGStatus.planning,
      message: 'Starting search...',
      steps: List.from(steps),
    );

    // 1. Intent Classification Step
    final intentStep = createStep("Analyzing query intent");
    yield RAGUpdate(status: RAGStatus.planning, steps: List.from(steps));

    final stopwatch = Stopwatch()..start();
    final intent = await _intentClassifier.classify(query);
    stopwatch.stop();

    updateStep(
      intentStep.id,
      status: SearchStepStatus.completed,
      description: "Identified as ${intent.name} search",
      duration: stopwatch.elapsed,
    );
    yield RAGUpdate(status: RAGStatus.planning, steps: List.from(steps));

    String effectiveQuery = query;
    if (previousMessages != null && previousMessages.isNotEmpty) {
      // Analyze dependency
      final analysis = _queryAnalyzer.analyzeQuery(query);

      if (analysis.requiresContext) {
        yield RAGUpdate(
          status: RAGStatus.planning,
          message: 'Resolving context...',
          steps: List.from(steps),
        );
        effectiveQuery = _promptEngineer.resolveContextualQuery(
          query,
          previousMessages,
          maxHistoryMessages: maxHistoryMessages,
        );
      }
    }

    // Step 0: Process attachments (Parallel)
    String? attachmentContext;
    final List<AttachmentMetadata> attachmentMetadata = [];

    if (attachments != null && attachments.isNotEmpty) {
      final attachmentStep = createStep(
        "Processing ${attachments.length} attachments",
      );
      yield RAGUpdate(
        status: RAGStatus.planning,
        message: 'Processing attachments...',
        steps: List.from(steps),
      );

      final stopwatch = Stopwatch()..start();
      final attachmentResults = await _processAttachments(attachments);
      stopwatch.stop();

      attachmentContext = _attachmentProcessor.createAttachmentContext(
        attachmentResults.where((r) => r.success).toList(),
      );

      for (int i = 0; i < attachments.length; i++) {
        final attachment = attachments[i];
        final result = attachmentResults[i];
        attachmentMetadata.add(
          AttachmentMetadata.fromAttachmentData(
            attachment,
            result.extractedText,
          ),
        );
      }

      updateStep(
        attachmentStep.id,
        status: SearchStepStatus.completed,
        description:
            "Processed ${attachmentResults.where((r) => r.success).length} files",
        duration: stopwatch.elapsed,
      );
    }

    // Step 0.5: Determine adaptive context length
    final effectiveMaxContext = await _getAdaptiveContextLength(
      overrideLength: maxContextLength,
    );
    try {
      // 2. Tool Selection & Execution

      // Determine tools based on intent
      final toolsToUse = <SearchTool>[];

      if (intent == SearchIntent.visual) {
        toolsToUse.add(_tools.firstWhere((t) => t is ImageSearchTool));
        // Also add web search for context
        toolsToUse.add(_tools.firstWhere((t) => t is WebSearchTool));
      } else if (intent == SearchIntent.coding) {
        toolsToUse.add(_tools.firstWhere((t) => t is WebSearchTool));
        // In future: add CodeSearchTool
      } else {
        toolsToUse.add(_tools.firstWhere((t) => t is WebSearchTool));
      }

      final allRawDocuments = <Document>[];
      final imageUrls = <String>[];

      // Execute Tools in Parallel
      final toolFutures = toolsToUse.map((tool) async {
        final step = createStep("Searching ${tool.name}...");
        // Yield inside map is tricky, we'll rely on periodic yields or just final yield of this block

        final toolStopwatch = Stopwatch()..start();
        final result = await tool.execute(effectiveQuery);
        toolStopwatch.stop();

        if (result.success) {
          updateStep(
            step.id,
            status: SearchStepStatus.completed,
            description: "Found ${result.documents.length} results",
            duration: toolStopwatch.elapsed,
          );

          if (tool is ImageSearchTool) {
            // Extract images specifically
            // Logic to extract image URLs from documents/result
            // For now assuming documents have metadata or specific handling
            // Adapting existing logic:
            for (final doc in result.documents) {
              if (doc.thumbnail != null)
                imageUrls.add(doc.thumbnail!);
              else if (doc.url.endsWith('.jpg') || doc.url.endsWith('.png'))
                imageUrls.add(doc.url);
            }
          }

          allRawDocuments.addAll(result.documents);
        } else {
          updateStep(
            step.id,
            status: SearchStepStatus.failed,
            description: result.errorMessage,
            duration: toolStopwatch.elapsed,
          );
        }
      });

      yield RAGUpdate(status: RAGStatus.searching, steps: List.from(steps));

      // Execute all tools in parallel and wait for results
      await Future.wait(toolFutures);

      yield RAGUpdate(
        status: RAGStatus.ranking,
        steps: List.from(steps),
        images: imageUrls,
      );

      // ... Proceed with existing ranking/scraping/generation logic ...
      // But wrapping "Scraping" and "Ranking" in steps

      if (allRawDocuments.isNotEmpty) {
        final rankingStep = createStep("Ranking & Filtering results");
        yield RAGUpdate(status: RAGStatus.ranking, steps: List.from(steps));

        final rankStopwatch = Stopwatch()..start();
        var rankedDocuments = await _documentRanker.rankDocuments(
          effectiveQuery,
          allRawDocuments,
        );
        final filteredDocuments = _documentRanker.filterDocuments(
          rankedDocuments,
          maxDocuments: maxRelevantDocuments,
        );
        rankStopwatch.stop();

        updateStep(
          rankingStep.id,
          status: SearchStepStatus.completed,
          description:
              "Selected ${filteredDocuments.length} most relevant sources",
          duration: rankStopwatch.elapsed,
        );

        // Scraping Step
        final scrapingStep = createStep("Reading content from sources");
        yield RAGUpdate(status: RAGStatus.scraping, steps: List.from(steps));

        final scrapeStopwatch = Stopwatch()..start();
        final urlsToScrape = filteredDocuments.map((doc) => doc.url).toList();
        final scrapedDocuments = await _scraperAdapter.scrapeMultiple(
          urlsToScrape,
          relevanceScore: 1.0,
        );
        scrapeStopwatch.stop();

        updateStep(
          scrapingStep.id,
          status: SearchStepStatus.completed,
          description: "Read ${scrapedDocuments.length} pages",
          duration: scrapeStopwatch.elapsed,
        );

        // Merge logic ...
        final enrichedDocuments = <Document>[];
        for (int i = 0; i < filteredDocuments.length; i++) {
          final doc = filteredDocuments[i];
          // simplified merge for brevity
          if (i < scrapedDocuments.length) {
            enrichedDocuments.add(
              scrapedDocuments[i].withRelevanceScore(doc.relevanceScore),
            );
          } else {
            enrichedDocuments.add(doc);
          }
        }

        // Context Fusion
        final contextChunks = _contextFusion.fuseContext(
          enrichedDocuments,
          maxTotalLength: attachmentContext != null
              ? effectiveMaxContext ~/ 2
              : effectiveMaxContext,
        );

        // Generation Step
        final thinkingStep = createStep("Generating answer");
        yield RAGUpdate(status: RAGStatus.thinking, steps: List.from(steps));

        // ... Prompt Generation ...
        final systemPrompt = _promptEngineer.createSystemPrompt(
          searchMode: searchMode,
        );
        final userPrompt = enableAdaptivePrompting
            ? _promptEngineer.createAdaptivePrompt(
                effectiveQuery, // Use effectiveQuery
                contextChunks,
                attachmentContext: attachmentContext,
              )
            : _promptEngineer.createUserPrompt(
                effectiveQuery,
                contextChunks,
                attachmentContext: attachmentContext,
              );
        final fullPrompt = '$systemPrompt\n\n$userPrompt';

        final StringBuffer fullAnswer = StringBuffer();

        updateStep(
          thinkingStep.id,
          status: SearchStepStatus.inProgress,
          description: "Streaming response...",
        );

        await for (final token in _llmManager.generateResponseStream(
          fullPrompt,
        )) {
          fullAnswer.write(token);
          yield RAGUpdate(
            status: RAGStatus.streaming,
            token: token,
            steps: List.from(steps),
          );
        }

        updateStep(
          thinkingStep.id,
          status: SearchStepStatus.completed,
          description: "Completed",
        );

        // Final Result Construction
        final citedMessageData = _citationManager.createCitedMessageData(
          query: query,
          answer: fullAnswer.toString(),
          contextChunks: contextChunks,
          allScrapedDocuments: enrichedDocuments,
          images: imageUrls,
        );

        // Update message with steps!!
        final finalDataWithSteps = citedMessageData.copyWith(steps: steps);

        yield RAGUpdate(
          status: RAGStatus.completed,
          finalResult: finalDataWithSteps,
          steps: List.from(steps),
        );
      } else {
        // Fallback
        yield RAGUpdate(
          status: RAGStatus.completed,
          finalResult: await _generateFallbackResponse(query),
        );
      }
    } catch (e) {
      print('RAG Stream Error: $e');
      yield RAGUpdate(
        status: RAGStatus.failed,
        message: e.toString(),
        steps: List.from(steps),
      );
    }
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

  /// Process attachments and extract content
  Future<List<AttachmentProcessResult>> _processAttachments(
    List<dynamic> attachments,
  ) async {
    // Process attachments in parallel to reduce wait time
    final futures = attachments.map((attachment) async {
      try {
        final result = await _attachmentProcessor.processAttachment(
          attachment.path,
          attachment.name,
        );
        return result;
      } catch (e) {
        print('⚠️ Failed to process ${attachment.name}: $e');
        return AttachmentProcessResult(
          success: false,
          errorMessage: e.toString(),
        );
      }
    });

    return await Future.wait(futures);
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

    await for (final update in generateRAGStream(
      query,
      maxSearchResults: maxSearchResults,
      maxRelevantDocuments: maxRelevantDocuments,
      maxContextLength: maxContextLength,
      maxHistoryMessages: maxHistoryMessages,
      attachments: attachments,
      previousMessages: previousMessages,
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
            steps: update.steps ?? const [],
            sources:
                update.documents
                    ?.map(
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
                    .toList() ??
                const [],
            generationState: MessageGenerationState.generating,
          ),
        );
      }
    }
    return lastData ?? await _generateFallbackResponse(query);
  }

  /// Generate fallback response
  Future<MessageData> _generateFallbackResponse(String query) async {
    try {
      print('📄 Generating fallback response');

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
    } else if (wordCount > 20) {
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
