import 'package:searvo/features/settings/services/llm_settings_service.dart';
import '../../domain/entities/message_data.dart';

import 'rag_data_source.dart';
import '../../domain/entities/search_mode.dart';
import '../../domain/entities/search_enums.dart';

import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';

import '../models/search_response_model.dart';

import '../../../settings/services/search_provider_settings_service.dart';
import 'searxng_remote_data_source.dart';
import '../../rag/services/data_ingestion/rag_scraper_adapter.dart';
import '../../rag/services/data_ingestion/pdf_extractor_service.dart';
import '../../rag/services/query_processing/query_analyzer.dart';
import '../../rag/models/rag_models.dart';
import '../../domain/services/agent/intent_orchestrator.dart';
import '../../domain/services/agent/agent_executor.dart';
import '../../domain/services/agent/tool_registry.dart';
import '../../domain/tools/web_search/web_search_tool.dart';
import '../../domain/tools/image_generator/image_generation_tool.dart';
import '../../domain/tools/pdf_reader/pdf_reader_tool.dart';
import '../../domain/tools/video_analyzer/video_analyzer_tool.dart';
import '../../domain/tools/web_scraper/web_scraper_tool.dart';
import '../../domain/tools/calculator/calculator_tool.dart';
import '../../domain/tools/weather/weather_tool.dart';
import '../../domain/tools/time/time_tool.dart';
import '../../domain/tools/currency/currency_converter_tool.dart';
import '../../domain/tools/dictionary/dictionary_tool.dart';
import '../../domain/tools/wikipedia/wikipedia_tool.dart';
import '../../domain/tools/unit_converter/unit_converter_tool.dart';
import '../../domain/tools/country/country_info_tool.dart';
import '../../domain/tools/numbers/numbers_tool.dart';
import '../../domain/tools/holiday/holiday_tool.dart';
import '../../domain/tools/crypto/crypto_price_tool.dart';
import '../../domain/tools/stock/stock_price_tool.dart';

import '../../domain/entities/message_generation_state.dart';
import '../../rag/domain/entities/rag_update.dart';
import '../../rag/domain/entities/rag_status.dart';

export '../../rag/services/data_ingestion/pdf_extractor_service.dart'
    show PDFContent;
export '../../rag/services/query_processing/query_analyzer.dart'
    show QueryAnalysis;
export '../../rag/models/rag_models.dart' show Document;

/// Complete search dataSource with RAG, attachment support, and advanced search capabilities
class IntelligentSearchDataSource {
  IntelligentSearchDataSource({
    required RAGDataSource ragDataSource,
    required LLMSettingsService llmSettings,
    required SearchProviderSettingsService searchSettings,
    required RAGScraperAdapter scraperAdapter,
    required QueryAnalyzer queryAnalyzer,
  }) : _ragDataSource = ragDataSource,
       _llmSettings = llmSettings,
       _searchSettings = searchSettings,
       _scraperAdapter = scraperAdapter,
       _queryAnalyzer = queryAnalyzer;

  final RAGDataSource _ragDataSource;
  final LLMSettingsService _llmSettings;
  final SearchProviderSettingsService _searchSettings;
  final RAGScraperAdapter _scraperAdapter;
  final PDFExtractorService _pdfExtractor =
      PDFExtractorService(); // Kept as internal helper for now, can be injected later
  final QueryAnalyzer _queryAnalyzer;
  final SearXNGRemoteDataSource _searxngService = SearXNGRemoteDataSource();

  late final IntentOrchestrator _intentOrchestrator;
  late final AgentExecutor _agentExecutor;
  late final ToolRegistry _toolRegistry;

  bool _isInitialized = false;
  final List<String> _initializationErrors = [];

  int _totalSearches = 0;
  int _successfulSearches = 0;
  int _failedSearches = 0;
  DateTime? _lastSearchTime;

  Future<void> initialize() async {
    if (_isInitialized) {
      print('ℹ️  Search service already initialized');
      return;
    }

    print('🚀 Initializing Search Service...');
    _initializationErrors.clear();

    try {
      print('🤖 Initializing LLM providers...');
      await _llmSettings.initializeLLMManager();

      if (_llmSettings.hasAnyConfiguredProvider()) {
        print('✅ LLM providers initialized');
      } else {
        final error = '⚠️  No LLM providers configured';
        print(error);
        _initializationErrors.add(error);
      }

      print('🔍 Initializing search providers...');
      await _initializeSearchProviders();

      print('🤖 Initializing Agent components...');
      _initializeAgent();

      final status = await performHealthCheck();
      if (status['overall'] == 'healthy') {
        _isInitialized = true;
        print('✅ Search Service ready');
      } else {
        print('⚠️  Search Service initialized with warnings');
      }
    } catch (e) {
      final error = 'Initialization failed: $e';
      print('❌ $error');
      _initializationErrors.add(error);
      throw Exception(error);
    }
  }

  Future<void> _initializeSearchProviders() async {
    try {
      // Use the class field instead of local variable
      final searxngEndpoint = _searchSettings.getSearXNGEndpoint();
      final timeout = _searchSettings.getSearchTimeout();

      await _searxngService.initialize(
        baseUrl: searxngEndpoint,
        timeout: timeout,
      );

      // Test connection
      final canConnect = await _searxngService.testConnection();
      if (canConnect) {
        print('✅ SearXNG connected at $searxngEndpoint');
      } else {
        final error = '⚠️  SearXNG at $searxngEndpoint is not reachable';
        print(error);
        _initializationErrors.add(error);
      }
    } catch (e) {
      final error = 'SearXNG initialization failed: $e';
      print('❌ $error');
      _initializationErrors.add(error);
      throw Exception(error);
    }
  }

  void _initializeAgent() {
    _toolRegistry = ToolRegistry();
    _toolRegistry.registerTools([
      WebSearchTool(searxngService: _searxngService),
      ImageGenerationTool(),
      PdfReaderTool(),
      VideoAnalyzerTool(),
      WebScraperTool(),
      CalculatorTool(),
      WeatherTool(),
      TimeTool(),
      CurrencyConverterTool(),
      DictionaryTool(),
      WikipediaTool(),
      UnitConverterTool(),
      CountryInfoTool(),
      NumbersTool(),
      HolidayTool(),
      CryptoPriceTool(),
      StockPriceTool(),
    ]);

    _intentOrchestrator = IntentOrchestrator(toolRegistry: _toolRegistry);
    _agentExecutor = AgentExecutor(toolRegistry: _toolRegistry);
  }

  /// Extract URLs from query text
  List<String> _extractUrls(String query) {
    final urlPattern = RegExp(r'https?://[^\s]+', caseSensitive: false);

    return urlPattern
        .allMatches(query)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Generate search response with optional attachments
  /// Generate streaming search response
  Stream<RAGUpdate> performDirectSearchStream(
    String query, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength,
    bool enableQueryEnhancement = true,
    bool enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
    bool isNewConversation = false,
  }) {
    return _ragDataSource.generateRAGStream(
      query,
      maxSearchResults: maxSearchResults,
      maxRelevantDocuments: maxRelevantDocuments,
      maxContextLength: maxContextLength,
      enableQueryEnhancement: enableQueryEnhancement,
      enableAdaptivePrompting: enableAdaptivePrompting,
      attachments: attachments,
      searchMode: searchMode,
      isNewConversation: isNewConversation,
    );
  }

  /// Generate intelligent search response (Orchestrator)
  Stream<RAGUpdate> generateSearchStream(
    String query, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength,
    bool enableQueryEnhancement = true,
    bool enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
    bool isNewConversation = false,
  }) async* {
    print(
      'IntelligentSearchDataSource: generateSearchStream called for "$query"',
    );
    if (!_isInitialized) {
      yield RAGUpdate(
        status: RAGStatus.failed,
        message: 'Service not initialized',
      );
      return;
    }

    try {
      print('IntelligentSearchDataSource: Yielding analyzing request...');
      yield RAGUpdate(
        status: RAGStatus.planning,
        message: 'Analyzing request...',
      );

      // 1. Plan
      print(
        'IntelligentSearchDataSource: Requesting plan from orchestrator...',
      );
      final plan = await _intentOrchestrator.plan(query);
      print('IntelligentSearchDataSource: Plan received');

      yield RAGUpdate(
        status: RAGStatus.planning,
        message: 'Plan created: ${plan.reasoning}',
      );

      // 2. Execute
      final stream = _agentExecutor.executePlan(query, plan);

      await for (final messageData in stream) {
        yield RAGUpdate(
          status: messageData.isGenerating
              ? RAGStatus.thinking
              : RAGStatus.streaming,
          finalResult: messageData,
          steps: messageData.steps,
          // If it's a web search result, we might populate documents?
          // For now, let's rely on MessageData to carry the UI state.
        );
        print(
          'IntelligentSearchDataSource: Yielding RAGUpdate. Status: ${messageData.isGenerating ? "thinking" : "streaming"}, Answer: "${messageData.answer}"',
        );

        // Track final result for synthesis
        if (messageData.generationState == MessageGenerationState.completed) {
          // If the agent finished but didn't generate an answer (e.g. only search results),
          // we need to synthesize an answer from the sources.
          if (messageData.answer.isEmpty && messageData.sources.isNotEmpty) {
            print(
              'IntelligentSearchDataSource: Agent finished with sources but no answer. Synthesizing...',
            );

            yield RAGUpdate(
              status: RAGStatus.thinking,
              message: 'Reading ${messageData.sources.length} sources...',
            );

            final llmManager = LLMProviderManager();
            final sourcesText = messageData.sources
                .map((s) => "- ${s.title}: ${s.description}")
                .join("\n");
            final prompt =
                "Based on the following search results, please answer the user's query: $query\n\nSearch Results:\n$sourcesText\n\nProvide a comprehensive and helpful answer.";

            final buffer = StringBuffer();
            await for (final token in llmManager.generateResponseStream(
              prompt,
            )) {
              buffer.write(token);
              // Yield streaming update combined with the existing message data (sources, etc.)
              final updatedData = messageData.copyWith(
                answer: buffer.toString(),
                generationState: MessageGenerationState.streaming,
              );

              yield RAGUpdate(
                status: RAGStatus.streaming,
                finalResult: updatedData,
                steps: messageData.steps,
                token: token,
              );
            }

            // correct the final state
            final finalData = messageData.copyWith(
              answer: buffer.toString(),
              generationState: MessageGenerationState.completed,
            );

            yield RAGUpdate(
              status: RAGStatus.completed,
              finalResult: finalData,
              steps: messageData.steps,
            );
            return; // Done
          }

          yield RAGUpdate(
            status: RAGStatus.completed,
            finalResult: messageData,
            steps: messageData.steps,
          );
        }
      }
    } catch (e) {
      print('Orchestrator failed: $e. Falling back to direct search.');
      yield RAGUpdate(
        status: RAGStatus.failed,
        message: 'Agent failed, falling back...',
      );

      // Fallback to direct search
      yield* performDirectSearchStream(
        query,
        maxSearchResults: maxSearchResults,
        maxRelevantDocuments: maxRelevantDocuments,
        maxContextLength: maxContextLength,
        enableQueryEnhancement: enableQueryEnhancement,
        enableAdaptivePrompting: enableAdaptivePrompting,
        attachments: attachments,
        searchMode: searchMode,
        isNewConversation: isNewConversation,
      );
    }
  }

  /// Generate intelligent search response (Orchestrator)
  Future<MessageData> generateSearchResponse(
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
    // Collect stream
    MessageData? finalData;
    await for (final update in generateSearchStream(
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
        finalData = update.finalResult;
        if (onSearchComplete != null) {
          onSearchComplete(finalData!);
        }
      }
    }

    return finalData ??
        MessageData(query: query, answer: "Failed to generate response");
  }

  /// Generate search response (Legacy)
  Future<MessageData> performDirectSearchResponse(
    String query, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength, // Nullable for auto-detection based on LLM
    bool enableQueryEnhancement = true,
    bool enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
    Function(MessageData)? onSearchComplete,
  }) async {
    if (!isReady) {
      throw Exception(
        'Search service not ready. Please configure an API key.\n'
        'Errors: ${_initializationErrors.join(", ")}',
      );
    }

    if (query.trim().isEmpty) {
      throw ArgumentError('Query cannot be empty');
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔎 New Search Request (Mode: ${searchMode.name})');
    if (attachments != null && attachments.isNotEmpty) {
      print('📎 With ${attachments.length} attachments');
    }

    // Detect URLs in query
    final urlsInQuery = _extractUrls(query);
    if (urlsInQuery.isNotEmpty) {
      print('🔗 Detected ${urlsInQuery.length} URL(s) in query:');
      for (final url in urlsInQuery) {
        print('   - $url');
      }
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _totalSearches++;
    final searchStart = DateTime.now();

    try {
      if (enableQueryEnhancement) {
        final validation = _ragDataSource.validateQuery(query);
        if (validation['quality'] < 40) {
          print('⚠️  Low quality query (${validation['quality']}/100)');
        }
      }

      final complexity = _ragDataSource.analyzeQueryComplexity(query);
      print('📊 Complexity: ${complexity['complexity']}');

      // Adjust parameters based on search mode
      int effectiveMaxDocs =
          complexity['recommendations']['maxRelevantDocuments'] as int;
      // Don't override context length - let adaptive system handle it
      int? effectiveMaxContext =
          maxContextLength; // Use provided or let RAG orchestrator auto-detect

      switch (searchMode) {
        case SearchMode.research:
          // Deep research mode - more documents and context
          effectiveMaxDocs = (effectiveMaxDocs * 1.5).round();
          // Let adaptive system handle context length
          print(
            '🔬 Research mode: Enhanced to $effectiveMaxDocs docs, adaptive context',
          );
          break;
        case SearchMode.study:
          // Study mode - balanced for learning
          effectiveMaxDocs = (effectiveMaxDocs * 1.2).round();
          // Let adaptive system handle context length
          print(
            '📚 Study mode: Enhanced to $effectiveMaxDocs docs, adaptive context',
          );
          break;
        case SearchMode.search:
          // Fast search mode - keep defaults
          print('⚡ Search mode: Using default parameters');
          break;
      }

      final response = await _ragDataSource.generateRAGResponse(
        query,
        maxSearchResults: maxSearchResults,
        maxRelevantDocuments: effectiveMaxDocs,
        maxContextLength: effectiveMaxContext,
        enableQueryEnhancement: enableQueryEnhancement,
        enableAdaptivePrompting: enableAdaptivePrompting,
        attachments: attachments,
        searchMode: searchMode,
        onSearchComplete: onSearchComplete,
      );

      _successfulSearches++;
      _lastSearchTime = DateTime.now();

      final duration = _lastSearchTime!.difference(searchStart);
      print('\n✅ Search completed in ${duration.inSeconds}s');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return response;
    } catch (e, stackTrace) {
      _failedSearches++;
      print('\n❌ Search failed: $e');
      print('Stack trace: $stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      throw Exception('Failed to generate search response: $e');
    }
  }

  /// Generate follow-up streaming response
  Stream<RAGUpdate> generateFollowUpStream(
    String query,
    List<MessageData> previousMessages, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength,
    int maxHistoryMessages = 3,
    List<dynamic>? attachments,
  }) {
    return _ragDataSource.generateRAGStream(
      query,
      maxSearchResults: maxSearchResults,
      maxRelevantDocuments: maxRelevantDocuments,
      maxContextLength: maxContextLength,
      maxHistoryMessages: maxHistoryMessages,
      attachments: attachments,
      searchMode: SearchMode.search, // Usually follow-ups are standard search
      previousMessages: previousMessages,
    );
  }

  /// Generate follow-up response with history
  Future<MessageData> generateFollowUpResponse(
    String query,
    List<MessageData> previousMessages, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int? maxContextLength, // Nullable for auto-detection based on LLM
    int maxHistoryMessages = 3,
    List<dynamic>? attachments,
    Function(MessageData)? onSearchComplete,
  }) async {
    if (!isReady) {
      throw Exception('Search service not ready');
    }

    if (query.trim().isEmpty) {
      throw ArgumentError('Query cannot be empty');
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 Follow-up Search Request');
    print('💬 History: ${previousMessages.length} messages');
    if (attachments != null && attachments.isNotEmpty) {
      print('📎 With ${attachments.length} attachments');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _totalSearches++;
    final searchStart = DateTime.now();

    try {
      final response = await _ragDataSource.generateRAGResponseWithHistory(
        query,
        previousMessages,
        maxSearchResults: maxSearchResults,
        maxRelevantDocuments: maxRelevantDocuments,
        maxContextLength: maxContextLength,
        maxHistoryMessages: maxHistoryMessages,
        attachments: attachments,
        onSearchComplete: onSearchComplete,
      );

      _successfulSearches++;
      _lastSearchTime = DateTime.now();

      final duration = _lastSearchTime!.difference(searchStart);
      print('\n✅ Follow-up completed in ${duration.inSeconds}s');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return response;
    } catch (e) {
      _failedSearches++;
      print('\n❌ Follow-up failed: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      throw Exception('Failed to generate follow-up response: $e');
    }
  }

  Map<String, dynamic> validateQuery(String query) {
    return _ragDataSource.validateQuery(query);
  }

  String enhanceQuery(String query) {
    return _ragDataSource.enhanceQuery(query);
  }

  Map<String, dynamic> analyzeQueryComplexity(String query) {
    return _ragDataSource.analyzeQueryComplexity(query);
  }

  /// Analyze query to understand intent, complexity, and generate sub-queries
  ///
  /// Example:
  /// ```dart
  /// final analysis = searchService.analyzeQuery("Compare Python vs JavaScript");
  /// print('Intent: ${analysis.intentType}');
  /// print('Sub-queries: ${analysis.subQueries}');
  /// ```
  QueryAnalysis analyzeQuery(String query) {
    return _queryAnalyzer.analyzeQuery(query);
  }

  /// Scrape full content from a URL
  ///
  /// Example:
  /// ```dart
  /// final content = await searchService.scrapeUrl(
  ///   url: "https://example.com/article",
  ///   includeImages: true,
  /// );
  /// print('Content: ${content.content} (${content.metadata["wordCount"]} words)');
  /// ```
  Future<Document> scrapeUrl({
    required String url,
    bool includeImages = false,
    bool includeLinks = false,
  }) async {
    return await _scraperAdapter.scrape(url);
  }

  /// Scrape multiple URLs in parallel
  ///
  /// Example:
  /// ```dart
  /// final urls = ["https://example1.com", "https://example2.com"];
  /// final contents = await searchService.scrapeMultipleUrls(urls);
  /// ```
  Future<List<Document>> scrapeMultipleUrls(
    List<String> urls, {
    bool includeImages = false,
    int maxConcurrent = 3,
  }) async {
    return await _scraperAdapter.scrapeMultiple(urls);
  }

  /// Extract text content from a PDF URL
  ///
  /// Example:
  /// ```dart
  /// final pdf = await searchService.extractPdfContent(
  ///   url: "https://example.com/paper.pdf",
  /// );
  /// print('PDF Text: ${pdf.text} (${pdf.pageCount} pages)');
  /// ```
  Future<PDFContent> extractPdfContent(String url) async {
    return await _pdfExtractor.extractFromUrl(url);
  }

  /// Perform a typed search (news, scholar, shopping, images, videos)
  ///
  /// Example:
  /// ```dart
  /// // News search with recency filter
  /// final news = await searchService.searchByType(
  ///   query: "AI developments",
  ///   searchType: SearchType.news,
  ///   recency: SearchRecency.day,
  /// );
  ///
  /// // Scholar search
  /// final papers = await searchService.searchByType(
  ///   query: "machine learning",
  ///   searchType: SearchType.scholar,
  /// );
  /// ```
  Future<SearchResponseModel> searchByType({
    required String query,
    SearchType searchType = SearchType.general,
    SearchRecency recency = SearchRecency.any,
    int maxResults = 10,
    String language = 'auto',
  }) async {
    final searxngService = SearXNGRemoteDataSource();
    if (!searxngService.isConfigured) {
      throw Exception('SearXNG is not configured');
    }

    return await searxngService.search(
      query,
      resultsPerPage: maxResults,
      searchType: searchType,
      recency: recency,
      language: language,
    );
  }

  bool get isReady {
    return _isInitialized &&
        _ragDataSource.isReady &&
        SearXNGRemoteDataSource().isConfigured;
  }

  bool get isConfigured => _llmSettings.hasAnyConfiguredProvider();

  String get activeProviderName {
    return _ragDataSource.getStatus()['activeLLMProvider'] as String? ?? 'None';
  }

  String get activeSearchProviderName {
    return 'SearXNG';
  }

  Map<String, dynamic> getStatus() {
    final ragStatus = _ragDataSource.getStatus();

    return {
      'isReady': isReady,
      'isInitialized': _isInitialized,
      'isConfigured': isConfigured,
      'activeLLMProvider': activeProviderName,
      'activeSearchProvider': activeSearchProviderName,
      'statistics': {
        'totalSearches': _totalSearches,
        'successfulSearches': _successfulSearches,
        'failedSearches': _failedSearches,
        'successRate': _totalSearches > 0
            ? (_successfulSearches / _totalSearches * 100).toStringAsFixed(1) +
                  '%'
            : 'N/A',
        'lastSearchTime': _lastSearchTime?.toIso8601String(),
      },
      'initializationErrors': _initializationErrors,
      'ragStatus': ragStatus,
    };
  }

  Map<String, dynamic> getDetailedStatus() {
    final basicStatus = getStatus();
    final perfStats = _ragDataSource.getPerformanceStats();

    return {...basicStatus, 'performance': perfStats};
  }

  Future<Map<String, dynamic>> testProvider() async {
    if (!isReady) {
      throw Exception('No provider configured. Status: ${getStatus()}');
    }

    print('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🧪 Testing Provider Configuration');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final testStart = DateTime.now();

    try {
      final response = await _ragDataSource.generateRAGResponse(
        'Hello, can you confirm you are working?',
        maxSearchResults: 5,
        maxRelevantDocuments: 3,
        maxContextLength: 2000,
      );

      final duration = DateTime.now().difference(testStart);

      final result = {
        'success': true,
        'duration': duration.inMilliseconds,
        'provider': activeProviderName,
        'searchProvider': activeSearchProviderName,
        'responseLength': response.answer.length,
        'sourcesCount': response.sources.length,
        'message': 'Provider test successful',
      };

      print('✅ Test passed in ${duration.inMilliseconds}ms');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return result;
    } catch (e, stackTrace) {
      print('❌ Test failed: $e');
      print('Stack trace: $stackTrace');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      return {
        'success': false,
        'error': e.toString(),
        'message': 'Provider test failed',
      };
    }
  }

  Future<Map<String, dynamic>> performHealthCheck() async {
    print('🏥 Performing health check...');

    final health = await _ragDataSource.performHealthCheck();
    health['searchService'] = _isInitialized ? 'healthy' : 'not_initialized';
    health['statistics'] = getStatus()['statistics'];

    print('   Overall: ${health['overall']}');
    return health;
  }

  void resetStatistics() {
    _totalSearches = 0;
    _successfulSearches = 0;
    _failedSearches = 0;
    _lastSearchTime = null;
    _ragDataSource.clearMetrics();

    print('📊 Statistics reset');
  }

  Map<String, dynamic> getPerformanceStatistics() {
    return {
      'searchService': {
        'totalSearches': _totalSearches,
        'successfulSearches': _successfulSearches,
        'failedSearches': _failedSearches,
        'successRate': _totalSearches > 0
            ? (_successfulSearches / _totalSearches * 100).toStringAsFixed(1) +
                  '%'
            : 'N/A',
        'lastSearchTime': _lastSearchTime?.toIso8601String(),
      },
      'ragOrchestrator': _ragDataSource.getPerformanceStats(),
    };
  }

  Future<void> reinitialize() async {
    print('🔄 Reinitializing Search Service...');

    _isInitialized = false;
    _initializationErrors.clear();

    await initialize();
  }

  List<String> get initializationErrors =>
      List.unmodifiable(_initializationErrors);
  bool get hasInitializationErrors => _initializationErrors.isNotEmpty;
}
