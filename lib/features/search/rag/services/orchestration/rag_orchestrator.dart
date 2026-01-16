import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/llm/services/providers/context_window_config.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/data/datasources/search_local_data_source.dart';
import 'package:searvo/features/search/domain/services/intent_classifier.dart';
import 'package:searvo/features/search/domain/entities/search_intent.dart';
import 'package:searvo/features/search/tools/search_tools.dart';
import '../../../domain/entities/message_generation_state.dart';
import '../../../domain/entities/source_item.dart';
import '../../../domain/entities/attachment_metadata.dart';
import 'package:searvo/features/search/domain/entities/search_step.dart';
import 'package:uuid/uuid.dart';
import '../query_processing/query_analyzer.dart';
import '../data_ingestion/rag_scraper_adapter.dart';
import 'package:searvo/features/search/domain/entities/search_mode.dart';
import 'agent_orchestrator.dart'; // Add import
import '../vector_store/qdrant_vector_store.dart';

import '../../../domain/entities/message_data.dart';
import '../document_processing/document_ranker.dart';

import '../document_processing/context_fusion.dart';
import '../citation/citation_manager.dart';
import '../query_processing/prompt_engineer.dart';
import '../data_ingestion/attachment_processor.dart';

/// Advanced RAG orchestrator with attachment support, conversation history, and intelligent web scraping
class RAGOrchestrator {
  final SearXNGRemoteDataSource _searxngService;
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
  late final AgentOrchestrator _agentOrchestrator; // Add field

  final QdrantVectorStore _vectorStore;
  final Map<String, dynamic> _performanceMetrics = {};

  RAGOrchestrator({
    SearXNGRemoteDataSource? searxngService,
    DocumentRanker? documentRanker,

    ContextFusion? contextFusion,
    QdrantVectorStore? vectorStore,
    CitationManager? citationManager,
    LLMProviderManager? llmManager,
    PromptEngineer? promptEngineer,
    AttachmentProcessor? attachmentProcessor,
    QueryAnalyzer? queryAnalyzer,
    RAGScraperAdapter? scraperAdapter,
    SearchLocalDataSource? cacheService,
    IntentClassifier? intentClassifier,
  }) : _searxngService = searxngService ?? SearXNGRemoteDataSource(),
       _documentRanker = documentRanker ?? DocumentRanker(),
       _contextFusion = contextFusion ?? ContextFusion(),
       _vectorStore = vectorStore ?? QdrantVectorStore(),
       _citationManager = citationManager ?? CitationManager(),
       _llmManager = llmManager ?? LLMProviderManager(),
       _promptEngineer = promptEngineer ?? PromptEngineer(),
       _attachmentProcessor = attachmentProcessor ?? AttachmentProcessor(),
       _queryAnalyzer = queryAnalyzer ?? QueryAnalyzer(),
       _scraperAdapter = scraperAdapter ?? RAGScraperAdapter(),
       _intentClassifier = intentClassifier ?? IntentClassifier() {
    _tools = [
      WebSearchTool(_searxngService),
      ImageSearchTool(_searxngService),
      ReadPageTool(_scraperAdapter),
      CalculatorTool(),
    ];
    _agentOrchestrator = AgentOrchestrator(
      llmManager: _llmManager,
      promptEngineer: _promptEngineer,
      tools: _tools,
    );
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
    bool isNewConversation = false,
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

    // 0. Complexity Check (Routing)
    final complexityAnalysis = analyzeQueryComplexity(query);
    // Trigger agent for complex OR moderate queries if in research mode
    // Also trigger if strictly complex
    final complexity = complexityAnalysis['complexity'];
    final shouldTriggerAgent =
        (complexity == 'complex') ||
        (complexity == 'moderate' && searchMode == SearchMode.research) ||
        (query.toLowerCase().contains("calculate")) ||
        (query.toLowerCase().contains("compare"));

    yield RAGUpdate(
      status: RAGStatus.planning,
      message: shouldTriggerAgent
          ? 'Switching to Agent Mode...'
          : 'Using Fast Search...',
      steps: List.from(steps),
    );

    // If complex (and not explicitly forced to simple), use Agent Loop
    if (shouldTriggerAgent) {
      yield* _agentOrchestrator.executeAgentLoop(query);
      return;
    }

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
        // Context Construction Strategy (Vector Search vs Standard)
        List<ContextChunk> contextChunks;
        final activeProvider = _llmManager.activeProvider;
        final supportsEmbeddings = activeProvider?.supportsEmbeddings ?? false;

        if (supportsEmbeddings) {
          final vectorStep = createStep("Semantic filtering (Vector Search)");
          yield RAGUpdate(status: RAGStatus.fusion, steps: List.from(steps));
          final vsStopwatch = Stopwatch()..start();

          try {
            // 1. Chunk all documents
            final allChunks = _contextFusion.chunkDocuments(
              enrichedDocuments,
              maxChunkSize: 1000, // Smaller chunks for vector search
              overlapSize: 100,
            );

            if (allChunks.isNotEmpty) {
              // 2. Generate embeddings for chunks
              final texts = allChunks.map((c) => c.content).toList();
              // Batch processing due to API limits usually handled by provider or we do simple serial for now
              final embeddings = <List<double>>[];

              for (final text in texts) {
                embeddings.add(await _llmManager.generateEmbeddings(text));
              }

              // 3. Clear previous vector store content
              // Note: For Qdrant, we might want to keep persistent data in future,
              // but for "session-based" RAG we clear.
              await _vectorStore.clear();

              // 4. Index chunks in Vector Store
              // _updateStatus(onUpdate, RAGStatus.fusion, 'Indexing ${embeddings.length} chunks...'); // This line was not in the original, and onUpdate is not available here.
              await _vectorStore.addDocuments(allChunks, embeddings);

              // 5. Generate embedding for user query
              final queryEmbedding = await _llmManager.generateEmbeddings(
                effectiveQuery,
              );

              // 6. Semantic Search
              // _updateStatus(onUpdate, RAGStatus.fusion, 'Finding most relevant context...'); // This line was not in the original, and onUpdate is not available here.
              final searchResults = await _vectorStore.search(
                queryEmbedding,
                limit: 15, // Increase limit as we fusion them next
                threshold: 0.3, // Adjust threshold
              );

              final retrievedChunks = searchResults
                  .map((r) => r.chunk)
                  .toList();

              updateStep(
                vectorStep.id,
                status: SearchStepStatus.completed,
                description:
                    "Retrieved ${retrievedChunks.length} semantic chunks",
                duration: vsStopwatch.elapsed,
              );

              // 6. Fuse the retrieved chunks
              contextChunks = _contextFusion.fuseChunks(
                retrievedChunks,
                maxTotalLength: attachmentContext != null
                    ? effectiveMaxContext ~/ 2
                    : effectiveMaxContext,
              );
            } else {
              contextChunks = [];
              updateStep(
                vectorStep.id,
                status: SearchStepStatus.completed,
                description: "No chunks to index",
              );
            }
          } catch (e) {
            print(
              '⚠️ Vector Search failed, falling back to standard fusion: $e',
            );
            updateStep(
              vectorStep.id,
              status: SearchStepStatus.failed,
              description: "Fallback to standard fusion: $e",
            );

            // Fallback to standard fusion
            contextChunks = _contextFusion.fuseContext(
              enrichedDocuments,
              maxTotalLength: attachmentContext != null
                  ? effectiveMaxContext ~/ 2
                  : effectiveMaxContext,
            );
          }
        } else {
          // Standard Fusion (No embeddings)
          contextChunks = _contextFusion.fuseContext(
            enrichedDocuments,
            maxTotalLength: attachmentContext != null
                ? effectiveMaxContext ~/ 2
                : effectiveMaxContext,
          );
        }

        // Generation Step
        final thinkingStep = createStep("Generating answer");
        yield RAGUpdate(status: RAGStatus.thinking, steps: List.from(steps));

        // ... Prompt Generation ...
        final systemPrompt = _promptEngineer.createSystemPrompt(
          searchMode: searchMode,
        );

        // Prepare conversation context if history exists
        String? conversationContext;
        if (previousMessages != null && previousMessages.isNotEmpty) {
          conversationContext = _promptEngineer.formatConversationHistory(
            previousMessages,
          );
        }

        final userPrompt = enableAdaptivePrompting
            ? _promptEngineer.createAdaptivePrompt(
                effectiveQuery,
                contextChunks,
                attachmentContext: attachmentContext,
                conversationContext: conversationContext, // Pass history
                generateTitle: isNewConversation,
              )
            : _promptEngineer.createUserPrompt(
                effectiveQuery,
                contextChunks,
                attachmentContext: attachmentContext,
                conversationContext: conversationContext, // Pass history
                generateTitle: isNewConversation,
              );
        final fullPrompt = '$systemPrompt\n\n$userPrompt';

        final StringBuffer fullAnswer = StringBuffer();

        updateStep(
          thinkingStep.id,
          status: SearchStepStatus.inProgress,
          description: "Streaming response...",
        );

        bool processingTitle = isNewConversation;
        final titleBuffer = StringBuffer();

        await for (final token in _llmManager.generateResponseStream(
          fullPrompt,
        )) {
          if (processingTitle) {
            titleBuffer.write(token);
            final bufferStr = titleBuffer.toString();

            // Check if we have the start tag
            if (bufferStr.contains('<title>')) {
              // Check if we have the end tag
              if (bufferStr.contains('</title>')) {
                final startIdx = bufferStr.indexOf('<title>');
                final endIdx = bufferStr.indexOf('</title>');

                if (startIdx != -1 && endIdx > startIdx) {
                  // Extract title
                  final extractedTitle = bufferStr
                      .substring(startIdx + 7, endIdx)
                      .trim();

                  yield RAGUpdate(
                    status: RAGStatus.streaming,
                    generatedTitle: extractedTitle,
                    steps: List.from(steps),
                  );

                  // Process remaining content (real answer)
                  final remaining = bufferStr.substring(endIdx + 8);
                  if (remaining.isNotEmpty) {
                    fullAnswer.write(remaining);
                    yield RAGUpdate(
                      status: RAGStatus.streaming,
                      token: remaining,
                      steps: List.from(steps),
                    );
                  }
                  processingTitle = false; // Done with title
                } else {
                  // Malformed tags? Just flush
                  fullAnswer.write(bufferStr);
                  yield RAGUpdate(
                    status: RAGStatus.streaming,
                    token: bufferStr,
                    steps: List.from(steps),
                  );
                  processingTitle = false;
                }
              }
              // Else keep buffering waiting for </title>
            } else {
              // If we don't have <title> yet
              // Logic check: if buffer is long enough and still no <title>, give up
              if (bufferStr.length > 20 && !bufferStr.contains('<title>')) {
                fullAnswer.write(bufferStr);
                yield RAGUpdate(
                  status: RAGStatus.streaming,
                  token: bufferStr,
                  steps: List.from(steps),
                );
                processingTitle = false;
              }
              // Else keep buffering
            }
          } else {
            // Normal streaming
            fullAnswer.write(token);
            yield RAGUpdate(
              status: RAGStatus.streaming,
              token: token,
              steps: List.from(steps),
            );
          }
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
