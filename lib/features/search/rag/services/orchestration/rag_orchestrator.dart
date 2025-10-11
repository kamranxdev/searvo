import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/services/searxng_service.dart';
import '../query_processing/query_analyzer.dart';
import '../data_ingestion/web_scraper_service.dart';
import 'package:searvo/features/search/widgets/search_box.dart' show SearchMode;

import '../../../models/message_data.dart';
import '../document_processing/document_ranker.dart';
import '../document_processing/media_ranker.dart';
import '../document_processing/context_fusion.dart';
import '../citation/citation_manager.dart';
import '../query_processing/prompt_engineer.dart';
import '../data_ingestion/attachment_processor.dart';

/// Advanced RAG orchestrator with attachment support, conversation history, and web scraping
class RAGOrchestrator {
  final SearXNGService _searxngService;
  final DocumentRanker _documentRanker;
  final MediaRanker _mediaRanker;
  final ContextFusion _contextFusion;
  final CitationManager _citationManager;
  final LLMProviderManager _llmManager;
  final PromptEngineer _promptEngineer;
  final AttachmentProcessor _attachmentProcessor;
  final QueryAnalyzer _queryAnalyzer;
  final WebScraperService _webScraper;

  final Map<String, dynamic> _performanceMetrics = {};

  RAGOrchestrator({
    SearXNGService? searxngService,
    DocumentRanker? documentRanker,
    MediaRanker? mediaRanker,
    ContextFusion? contextFusion,
    CitationManager? citationManager,
    LLMProviderManager? llmManager,
    PromptEngineer? promptEngineer,
    AttachmentProcessor? attachmentProcessor,
    QueryAnalyzer? queryAnalyzer,
    WebScraperService? webScraper,
  })  : _searxngService = searxngService ?? SearXNGService(),
        _documentRanker = documentRanker ?? DocumentRanker(),
        _mediaRanker = mediaRanker ?? MediaRanker(),
        _contextFusion = contextFusion ?? ContextFusion(),
        _citationManager = citationManager ?? CitationManager(),
        _llmManager = llmManager ?? LLMProviderManager(),
        _promptEngineer = promptEngineer ?? PromptEngineer(),
        _attachmentProcessor = attachmentProcessor ?? AttachmentProcessor(),
        _queryAnalyzer = queryAnalyzer ?? QueryAnalyzer(),
        _webScraper = webScraper ?? WebScraperService();

  /// Generate RAG response with optional attachments
  Future<MessageData> generateRAGResponse(
    String query, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int maxContextLength = 8000,
    bool enableQueryEnhancement = true,
    bool enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
    Function(MessageData)? onSearchComplete,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      print('🔍 RAG Pipeline Started (Mode: ${searchMode.name})');
      print('📝 Query: $query');
      if (attachments != null && attachments.isNotEmpty) {
        print('📎 Attachments: ${attachments.length}');
      }

      // Step 0: Process attachments if provided
      String? attachmentContext;
      final List<AttachmentMetadata> attachmentMetadata = [];
      
      if (attachments != null && attachments.isNotEmpty) {
        final attachmentResults = await _processAttachments(attachments);
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
        
        print('✅ Processed ${attachmentResults.where((r) => r.success).length} attachments');
      }

      // Step 0.5: Analyze query using QueryAnalyzer
      final queryAnalysis = _queryAnalyzer.analyzeQuery(query);
      print('📊 Query Analysis:');
      print('   Intent: ${queryAnalysis.intentType}');
      print('   Complexity: ${queryAnalysis.complexity['level']}');
      print('   Temporal: ${queryAnalysis.hasTemporalContext}');
      print('   Sub-queries: ${queryAnalysis.subQueries.length}');
      print('   Suggested types: ${queryAnalysis.suggestedSearchTypes.join(", ")}');

      // Step 1: Query enhancement
      String processedQuery = query;
      if (enableQueryEnhancement) {
        final validation = _promptEngineer.validateQuery(query);
        print('✓ Query Quality: ${validation['quality']}/100');

        if (validation['quality'] < 60) {
          processedQuery = _promptEngineer.enhanceQuery(query);
          print('✨ Enhanced Query: $processedQuery');
        }
      }

      // Step 2: Multi-type search with recency filters
      final searchStart = DateTime.now();

      if (!_searxngService.isConfigured) {
        throw Exception('SearXNG is not configured');
      }

      // Perform multiple searches across different types
      final allRawDocuments = <Document>[];
      List<String> searchTypes = queryAnalysis.suggestedSearchTypes.take(3).toList();
      
      // ALWAYS include images and videos search for every query
      // This ensures the Images and Videos tabs are always populated with relevant media
      if (!searchTypes.contains('images')) {
        searchTypes.add('images');
      }
      
      if (!searchTypes.contains('videos')) {
        searchTypes.add('videos');
      }
      
      print('🎯 Search types: ${searchTypes.join(", ")}');
      
      // Collections for images and videos
      final List<String> imageUrls = [];
      final List<VideoItem> videoItems = [];
      
      // Map recency
      SearchRecency searchRecency = SearchRecency.any;
      if (queryAnalysis.hasTemporalContext && queryAnalysis.recency != null) {
        switch (queryAnalysis.recency) {
          case 'day':
            searchRecency = SearchRecency.day;
            break;
          case 'week':
            searchRecency = SearchRecency.week;
            break;
          case 'month':
            searchRecency = SearchRecency.month;
            break;
          case 'year':
            searchRecency = SearchRecency.year;
            break;
        }
      }

      // Perform searches
      for (final searchTypeStr in searchTypes) {
        SearchType searchType = SearchType.general;
        switch (searchTypeStr) {
          case 'news':
            searchType = SearchType.news;
            break;
          case 'scholar':
            searchType = SearchType.scholar;
            break;
          case 'shopping':
            searchType = SearchType.shopping;
            break;
          case 'images':
            searchType = SearchType.images;
            break;
          case 'videos':
            searchType = SearchType.videos;
            break;
          default:
            searchType = SearchType.general;
        }

        if (!_searxngService.supportsSearchType(searchType)) {
          continue;
        }

        try {
          final response = await _searxngService.search(
            processedQuery,
            resultsPerPage: maxSearchResults ~/ searchTypes.length,
            searchType: searchType,
            recency: searchRecency,
          );

          final docs = response.results.map((result) {
            return Document.fromSearchResult(result);
          }).toList();

          allRawDocuments.addAll(docs);
          
          // Collect images if this is an image search
          if (searchType == SearchType.images) {
            int validImages = 0;
            int rejectedImages = 0;
            for (final result in response.results) {
              // For image searches, SearxNG returns img_src field with the actual image URL
              final imageUrl = result.imgSrc ?? result.url;
              if (imageUrl.isNotEmpty && imageUrls.length < 12) {
                // Validate it's a proper image URL
                if (_isValidImageUrl(imageUrl)) {
                  imageUrls.add(imageUrl);
                  validImages++;
                } else {
                  rejectedImages++;
                  if (rejectedImages <= 3) {
                    print('   ⚠️  Rejected non-image URL: $imageUrl');
                  }
                }
              }
            }
            print('   ✓ ${searchTypeStr}: ${docs.length} results (${validImages} valid images, ${rejectedImages} rejected)');
          }
          // Collect videos if this is a video search
          else if (searchType == SearchType.videos) {
            int validVideos = 0;
            int rejectedVideos = 0;
            for (final result in response.results) {
              if (videoItems.length < 12) {
                // For video searches, SearxNG returns iframe_src or url for the video
                final videoUrl = result.iframeSrc ?? result.url;
                // Check if this looks like a valid video result
                final isVideo = _isValidVideoResult(result);
                if (isVideo && videoUrl.isNotEmpty) {
                  final domain = _extractDomain(result.url);
                  videoItems.add(VideoItem(
                    thumbnail: result.thumbnailSrc ?? result.thumbnail ?? '',
                    url: result.url,
                    title: result.title,
                    description: result.snippet,
                    domain: domain,
                    duration: result.length,
                    publishedDate: result.publishedDate,
                    views: result.views != null ? int.tryParse(result.views!) : null,
                  ));
                  validVideos++;
                } else {
                  rejectedVideos++;
                  if (rejectedVideos <= 3) {
                    print('   ⚠️  Rejected non-video URL: ${result.url}');
                  }
                }
              }
            }
            print('   ✓ ${searchTypeStr}: ${docs.length} results (${validVideos} valid videos, ${rejectedVideos} rejected)');
          }
          else {
            print('   ✓ ${searchTypeStr}: ${docs.length} results');
          }
        } catch (e) {
          print('   ✗ ${searchTypeStr} search failed: $e');
        }
      }

      // Perform sub-query searches for complex queries
      if (queryAnalysis.isComplex && queryAnalysis.subQueries.isNotEmpty) {
        print('🔍 Executing ${queryAnalysis.subQueries.length} sub-queries...');
        for (final subQuery in queryAnalysis.subQueries.take(2)) {
          try {
            final subResponse = await _searxngService.search(
              subQuery,
              resultsPerPage: 5,
              searchType: SearchType.general,
            );

            final subDocs = subResponse.results.map((result) {
              return Document.fromSearchResult(result);
            }).toList();

            allRawDocuments.addAll(subDocs);
            print('   ✓ Sub-query: "$subQuery" → ${subDocs.length} results');
          } catch (e) {
            print('   ✗ Sub-query failed: $e');
          }
        }
      }

      final searchDuration = DateTime.now().difference(searchStart);
      print('🔎 Found ${allRawDocuments.length} total documents in ${searchDuration.inMilliseconds}ms');

      // Step 2.5: Media ranking using relevance scoring
      final mediaRankStart = DateTime.now();
      
      // Rank images if any were found
      if (imageUrls.isNotEmpty) {
        print('🖼️  Ranking ${imageUrls.length} images...');
        final rankedImages = _mediaRanker.rankImages(query, imageUrls);
        imageUrls.clear();
        imageUrls.addAll(rankedImages);
        print('✅ Ranked images by relevance');
      }
      
      // Rank videos if any were found
      if (videoItems.isNotEmpty) {
        print('🎥 Ranking ${videoItems.length} videos...');
        final rankedVideos = _mediaRanker.rankVideos(query, videoItems);
        videoItems.clear();
        videoItems.addAll(rankedVideos);
        print('✅ Ranked videos by relevance');
      }
      
      final mediaRankDuration = DateTime.now().difference(mediaRankStart);
      print('🎯 Media ranking completed in ${mediaRankDuration.inMilliseconds}ms');

      // Call callback with search results if provided
      if (onSearchComplete != null) {
        final partialMessageData = MessageData(
          query: query,
          answer: '',
          images: imageUrls,
          videos: videoItems,
          generationState: MessageGenerationState.generating,
        );
        onSearchComplete(partialMessageData);
      }

      if (allRawDocuments.isEmpty && attachmentContext == null) {
        return await _generateFallbackResponse(query);
      }

      // Step 3: Document ranking
      final rankStart = DateTime.now();
      final rankedDocuments = _documentRanker.rankDocuments(
        processedQuery,
        allRawDocuments,
      );
      
      final filteredDocuments = _documentRanker.filterDocuments(
        rankedDocuments,
        maxDocuments: maxRelevantDocuments * 2, // Get more docs for scraping
      );
      
      final rankDuration = DateTime.now().difference(rankStart);
      print('⭐ Ranked to ${filteredDocuments.length} documents in ${rankDuration.inMilliseconds}ms');

      // Step 3.5: Adaptive scraping with rich content extraction
      final scrapeStart = DateTime.now();
      final topDocuments = filteredDocuments.take(maxRelevantDocuments).toList();
      final urlsToScrape = topDocuments.map((doc) => doc.url).toList();
      
      // Adaptive configuration based on search mode
      final enableRichContent = searchMode == SearchMode.research;
      final concurrency = searchMode == SearchMode.search ? 5 : (searchMode == SearchMode.study ? 3 : 2);
      
      print('🌐 Scraping ${urlsToScrape.length} URLs (mode: ${searchMode.name}, rich: $enableRichContent, concurrency: $concurrency)...');
      
      final scrapedContents = await _webScraper.scrapeMultiple(
        urlsToScrape,
        includeImages: enableRichContent,
        includeLinks: enableRichContent,
        maxConcurrent: concurrency,
        onProgress: (completed, total) {
          print('   📊 Progress: $completed/$total URLs scraped');
        },
      );

      // Merge scraped content with documents
      final enrichedDocuments = <Document>[];
      int totalImages = 0;
      int totalLinks = 0;
      
      for (int i = 0; i < topDocuments.length; i++) {
        final doc = topDocuments[i];
        final scraped = scrapedContents[i];
        
        if (scraped.success && scraped.text.isNotEmpty) {
          // Replace snippet with full scraped content
          enrichedDocuments.add(scraped.toDocument(doc.relevanceScore));
          totalImages += scraped.images.length;
          totalLinks += scraped.links.length;
          print('   ✓ ${doc.url} → ${scraped.wordCount} words${enableRichContent ? ", ${scraped.images.length} images, ${scraped.links.length} links" : ""}');
        } else {
          // Keep original document
          enrichedDocuments.add(doc);
          print('   ✗ ${doc.url} → using snippet (${scraped.error ?? "unknown error"})');
        }
      }

      final scrapeDuration = DateTime.now().difference(scrapeStart);
      print('🌐 Scraped content in ${scrapeDuration.inMilliseconds}ms');
      if (enableRichContent) {
        print('   🖼️  Total images extracted: $totalImages');
        print('   🔗 Total links extracted: $totalLinks');
      }

      // Step 4: Context fusion with enriched content
      final fusionStart = DateTime.now();
      final contextChunks = _contextFusion.fuseContext(
        enrichedDocuments,
        maxTotalLength: attachmentContext != null ? maxContextLength ~/ 2 : maxContextLength,
        maxChunksPerDocument: 2, // Limit chunks per document for source diversity
        optimizeForQuality: true,
      );
      
      final fusionDuration = DateTime.now().difference(fusionStart);
      print('🧩 Created ${contextChunks.length} context chunks in ${fusionDuration.inMilliseconds}ms');

      // Step 5: Adaptive prompt generation
      final promptStart = DateTime.now();
      final systemPrompt = _promptEngineer.createSystemPrompt();
      
      String userPrompt;
      if (enableAdaptivePrompting) {
        userPrompt = _promptEngineer.createAdaptivePrompt(
          query, 
          contextChunks,
          attachmentContext: attachmentContext,
        );
      } else {
        userPrompt = _promptEngineer.createUserPrompt(
          query, 
          contextChunks,
          attachmentContext: attachmentContext,
        );
      }

      final fullPrompt = '$systemPrompt\n\n$userPrompt';
      final promptDuration = DateTime.now().difference(promptStart);
      print('📄 Prompt ready in ${promptDuration.inMilliseconds}ms');

      // Step 6: LLM response generation
      final llmStart = DateTime.now();
      final llmResponse = await _llmManager.generateResponse(fullPrompt);
      final llmDuration = DateTime.now().difference(llmStart);
      print('🤖 LLM responded in ${llmDuration.inSeconds}s');

      // Step 7: Citation processing
      final citationStart = DateTime.now();
      final citationValidation = _citationManager.validateCitations(
        llmResponse,
        contextChunks,
      );
      
      print('📚 Citations: ${citationValidation['stats']['totalCitations']}');

      // Step 8: Generate related questions based on actual content
      print('💡 Generating follow-up questions from ${contextChunks.length} chunks');
      final relatedQuestions = _promptEngineer.generateFollowUpQuestions(
        query,
        contextChunks,
        hasAttachments: attachmentContext != null,
      );
      print('✅ Generated ${relatedQuestions.length} follow-up questions');

      // Create final message
      final citedMessageData = _citationManager.createCitedMessageData(
        query: query,
        answer: llmResponse,
        contextChunks: contextChunks,
        customRelatedQuestions: relatedQuestions,
        attachments: attachmentMetadata,
        images: imageUrls.isNotEmpty ? imageUrls : null,
        videos: videoItems.isNotEmpty ? videoItems : null,
      );
      
      final citationDuration = DateTime.now().difference(citationStart);

      // Store metrics
      stopwatch.stop();
      _performanceMetrics['lastQuery'] = {
        'query': query,
        'totalDuration': stopwatch.elapsedMilliseconds,
        'searchDuration': searchDuration.inMilliseconds,
        'rankDuration': rankDuration.inMilliseconds,
        'scrapeDuration': scrapeDuration.inMilliseconds,
        'fusionDuration': fusionDuration.inMilliseconds,
        'promptDuration': promptDuration.inMilliseconds,
        'llmDuration': llmDuration.inMilliseconds,
        'citationDuration': citationDuration.inMilliseconds,
        'documentsUsed': enrichedDocuments.length,
        'documentsScraped': scrapedContents.where((s) => s.success).length,
        'searchTypes': searchTypes,
        'hasAttachments': attachmentContext != null,
        'queryComplexity': queryAnalysis.complexity['level'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('✨ Completed in ${stopwatch.elapsedMilliseconds}ms');
      return citedMessageData;
    } catch (e, stackTrace) {
      print('❌ RAG Pipeline Failed: $e');
      print('Stack trace: $stackTrace');
      
      stopwatch.stop();
      return await _generateFallbackResponse(query);
    }
  }

  /// Process attachments and extract content
  Future<List<AttachmentProcessResult>> _processAttachments(
    List<dynamic> attachments,
  ) async {
    final results = <AttachmentProcessResult>[];
    
    for (final attachment in attachments) {
      try {
        final result = await _attachmentProcessor.processAttachment(
          attachment.path,
          attachment.name,
        );
        results.add(result);
      } catch (e) {
        print('⚠️ Failed to process ${attachment.name}: $e');
        results.add(AttachmentProcessResult(
          success: false,
          errorMessage: e.toString(),
        ));
      }
    }
    
    return results;
  }

  /// Generate response with conversation history - FIXED VERSION
  Future<MessageData> generateRAGResponseWithHistory(
    String query,
    List<MessageData> previousMessages, {
    int maxSearchResults = 20,
    int maxRelevantDocuments = 10,
    int maxContextLength = 8000,
    int maxHistoryMessages = 3,
    List<dynamic>? attachments,
    Function(MessageData)? onSearchComplete,
  }) async {
    try {
      print('🔄 Multi-turn RAG Started');
      print('📜 History: ${previousMessages.length} messages');
      print('🔍 Original query: "$query"');

      // Step 1: Analyze query context dependency using QueryAnalyzer
      final queryAnalysis = _queryAnalyzer.analyzeQuery(query);
      print('📊 Context Analysis:');
      print('   Level: ${queryAnalysis.contextLevel}');
      print('   Confidence: ${queryAnalysis.contextConfidence.toStringAsFixed(2)}');
      print('   Requires context: ${queryAnalysis.requiresContext}');

      // Step 2: Intelligently resolve contextual references if needed
      String searchQuery = query;
      bool queryWasResolved = false;
      
      if (queryAnalysis.requiresContext && previousMessages.isNotEmpty) {
        // Use intelligent query resolution (like Perplexity AI)
        searchQuery = _promptEngineer.resolveContextualQuery(
          query,
          previousMessages,
          maxHistoryMessages: maxHistoryMessages,
        );
        queryWasResolved = searchQuery != query;
        
        if (queryWasResolved) {
          print('✨ Resolved contextual query for search: "$searchQuery"');
        } else {
          print('ℹ️  Query already self-contained, no resolution needed');
        }
      } else if (queryAnalysis.contextLevel == 'partial' && previousMessages.isNotEmpty) {
        // For partial dependency, try light enhancement
        final enhanced = _promptEngineer.resolveContextualQuery(
          query,
          previousMessages,
          maxHistoryMessages: 1, // Only use most recent message
        );
        if (enhanced != query && enhanced.length < query.length * 1.5) {
          searchQuery = enhanced;
          queryWasResolved = true;
          print('🔧 Lightly enhanced query for search: "$searchQuery"');
        }
      } else {
        print('✅ Query is independent, no context resolution needed');
      }

      // Step 3: Process attachments if provided
      String? attachmentContext;
      final List<AttachmentMetadata> attachmentMetadata = [];
      
      if (attachments != null && attachments.isNotEmpty) {
        final attachmentResults = await _processAttachments(attachments);
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
        
        print('✅ Processed ${attachmentResults.where((r) => r.success).length} attachments');
      }

      // Step 4: Perform search with resolved query
      final searchStart = DateTime.now();

      if (!_searxngService.isConfigured) {
        throw Exception('SearXNG is not configured');
      }

      // Perform general search
      final response = await _searxngService.search(
        searchQuery,
        resultsPerPage: maxSearchResults,
      );

      final rawDocuments = response.results.map((result) {
        return Document.fromSearchResult(result);
      }).toList();
      
      // ALSO search for images and videos for follow-ups
      final List<String> imageUrls = [];
      final List<VideoItem> videoItems = [];
      
      // Search for images
      try {
        if (_searxngService.supportsSearchType(SearchType.images)) {
          final imageResponse = await _searxngService.search(
            searchQuery,
            resultsPerPage: 12,
            searchType: SearchType.images,
          );
          
          for (final result in imageResponse.results) {
            if (result.url.isNotEmpty && imageUrls.length < 12) {
              imageUrls.add(result.url);
            }
          }
          print('   ✓ Images: ${imageUrls.length} found');
        }
      } catch (e) {
        print('   ✗ Image search failed: $e');
      }
      
      // Search for videos
      try {
        if (_searxngService.supportsSearchType(SearchType.videos)) {
          final videoResponse = await _searxngService.search(
            searchQuery,
            resultsPerPage: 12,
            searchType: SearchType.videos,
          );
          
          for (final result in videoResponse.results) {
            if (videoItems.length < 12) {
              final domain = _extractDomain(result.url);
              videoItems.add(VideoItem(
                thumbnail: result.thumbnail ?? '',
                url: result.url,
                title: result.title,
                description: result.snippet,
                domain: domain,
                duration: null,
                publishedDate: result.publishedDate,
                views: null,
              ));
            }
          }
          print('   ✓ Videos: ${videoItems.length} found');
        }
      } catch (e) {
        print('   ✗ Video search failed: $e');
      }
      
      final searchDuration = DateTime.now().difference(searchStart);
      print('🔎 Found ${rawDocuments.length} documents in ${searchDuration.inMilliseconds}ms');

      // Call callback with search results if provided
      if (onSearchComplete != null) {
        final partialMessageData = MessageData(
          query: query,
          answer: '',
          images: imageUrls,
          videos: videoItems,
          generationState: MessageGenerationState.generating,
        );
        onSearchComplete(partialMessageData);
      }

      // Check if we have any content
      if (rawDocuments.isEmpty && attachmentMetadata.isEmpty) {
        return await _generateFallbackResponse(query);
      }

      // Rank and filter documents
      final rankedDocuments = _documentRanker.rankDocuments(
        searchQuery,
        rawDocuments,
      );
      
      final filteredDocuments = _documentRanker.filterDocuments(
        rankedDocuments,
        maxDocuments: maxRelevantDocuments,
      );

      // Create context chunks
      final contextChunks = _contextFusion.fuseContext(
        filteredDocuments,
        maxTotalLength: attachmentContext != null ? maxContextLength ~/ 2 : maxContextLength,
        maxChunksPerDocument: 2, // Limit chunks per document for source diversity
        optimizeForQuality: true,
      );

      // Build conversation context for LLM prompt if needed
      final conversationContext = queryAnalysis.requiresContext || queryAnalysis.contextLevel == 'partial'
          ? _buildConversationContext(previousMessages, maxMessages: maxHistoryMessages)
          : null;

      // Generate prompt with conversation history (internally)
      final systemPrompt = _promptEngineer.createSystemPrompt();
      final userPrompt = _promptEngineer.createUserPromptWithHistory(
        query,  // Use ORIGINAL query for LLM, not resolved one
        contextChunks,
        conversationContext: conversationContext,
        attachmentContext: attachmentContext,
      );

      final fullPrompt = '$systemPrompt\n\n$userPrompt';

      // Generate response
      final llmResponse = await _llmManager.generateResponse(fullPrompt);

      // Generate context-aware related questions (FIX HERE)
      print('💡 Generating follow-up questions with history from ${contextChunks.length} chunks');
      final relatedQuestions = _promptEngineer.generateFollowUpQuestionsWithHistory(
        query,
        contextChunks,  // Pass the actual context chunks
        previousMessages,
        hasAttachments: attachmentContext != null,
      );
      print('✅ Generated ${relatedQuestions.length} follow-up questions');

      // Create final message with ORIGINAL query (not enhanced)
      final citedMessageData = _citationManager.createCitedMessageData(
        query: query,  // Use original query here
        answer: llmResponse,
        contextChunks: contextChunks,
        customRelatedQuestions: relatedQuestions,
        attachments: attachmentMetadata,
        images: imageUrls.isNotEmpty ? imageUrls : null,
        videos: videoItems.isNotEmpty ? videoItems : null,
      );

      return citedMessageData;
    } catch (e) {
      print('❌ Multi-turn RAG failed: $e');
      return await generateRAGResponse(query, attachments: attachments);
    }
  }

  /// Build conversation context from history
  String _buildConversationContext(
    List<MessageData> messages,
    {int maxMessages = 3}
  ) {
    if (messages.isEmpty) return '';

    final buffer = StringBuffer();
    final recentMessages = messages.length > maxMessages 
        ? messages.skip(messages.length - maxMessages).toList()
        : messages;

    buffer.writeln('CONVERSATION HISTORY:\n');
    
    for (int i = 0; i < recentMessages.length; i++) {
      final message = recentMessages[i];
      buffer.writeln('Turn ${i + 1}:');
      buffer.writeln('User: ${message.query}');
      
      final answerPreview = message.answer.length > 300
          ? '${message.answer.substring(0, 300)}...'
          : message.answer;
      buffer.writeln('Assistant: $answerPreview');
      
      if (message.hasAttachments) {
        buffer.writeln('(Had ${message.attachments.length} file attachments)');
      }
      if (message.sources.isNotEmpty) {
        buffer.writeln('(Referenced ${message.sources.length} sources)');
      }
      
      buffer.writeln();
    }
    
    buffer.writeln('---\n');

    return buffer.toString();
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

  bool get isReady => _llmManager.hasConfiguredProvider && _searxngService.isConfigured;

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
      'search': _searxngService.isConfigured 
          ? 'healthy' 
          : 'not_configured',
      'overall': isReady ? 'healthy' : 'degraded',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Extract domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      String domain = uri.host;
      
      // Remove www. prefix
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      
      return domain;
    } catch (e) {
      return 'unknown';
    }
  }

  /// Clean URL by removing query parameters and fragments
  String _cleanUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // Reconstruct URL without query params and fragments
      return '${uri.scheme}://${uri.host}${uri.path}';
    } catch (e) {
      // If parsing fails, try simple string manipulation
      final questionMarkIndex = url.indexOf('?');
      final hashIndex = url.indexOf('#');
      
      int endIndex = url.length;
      if (questionMarkIndex != -1 && hashIndex != -1) {
        endIndex = questionMarkIndex < hashIndex ? questionMarkIndex : hashIndex;
      } else if (questionMarkIndex != -1) {
        endIndex = questionMarkIndex;
      } else if (hashIndex != -1) {
        endIndex = hashIndex;
      }
      
      return url.substring(0, endIndex);
    }
  }

  /// Validate if URL is a valid image URL
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    // Clean the URL first - remove query params and fragments
    final cleanedUrl = _cleanUrl(url).toLowerCase();
    
    // Define all supported image format extensions
    final imageExtensions = [
      '.jpg', 
      '.jpeg', 
      '.png', 
      '.gif', 
      '.webp', 
      '.bmp', 
      '.svg', 
      '.ico', 
      '.tiff', 
      '.tif', 
      '.jfif', 
      '.pjpeg', 
      '.pjp', 
      '.avif',
      '.heic',
      '.heif',
    ];
    
    // Check if cleaned URL ends with any image extension
    for (final ext in imageExtensions) {
      if (cleanedUrl.endsWith(ext)) {
        return true;
      }
    }
    
    // Additional check: Check for image hosting domains
    // These are trusted to serve actual images even without explicit extensions
    final imageHosts = [
      'imgur.com',
      'i.imgur.com',
      'flickr.com',
      'staticflickr.com',
      'instagram.com',
      'cdninstagram.com',
      'pinterest.com',
      'pinimg.com',
      'unsplash.com',
      'images.unsplash.com',
      'pexels.com',
      'images.pexels.com',
      'pixabay.com',
      'i.redd.it', // Reddit images
      'media.giphy.com',
      'tenor.com',
    ];
    
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      // Only accept from known image hosting domains
      if (imageHosts.any((h) => host.contains(h))) {
        return true;
      }
      
      // For CDN domains, require image extension in cleaned path
      if (host.contains('cdn') || host.contains('cloudfront') || host.contains('cloudinary')) {
        final cleanedPath = uri.path.toLowerCase();
        if (imageExtensions.any((ext) => cleanedPath.endsWith(ext))) {
          return true;
        }
      }
    } catch (e) {
      return false;
    }
    
    return false;
  }

  /// Validate if search result is a valid video result
  bool _isValidVideoResult(dynamic result) {
    if (result == null) return false;
    
    final url = result.url?.toLowerCase() ?? '';
    
    // Must have a URL
    if (url.isEmpty) {
      return false;
    }
    
    // If SearxNG provided iframe_src, it's definitely a video
    if (result.iframeSrc != null && result.iframeSrc!.isNotEmpty) {
      return true;
    }
    
    // Clean the URL first
    final cleanedUrl = _cleanUrl(url).toLowerCase();
    
    // Check for video hosting platforms in URL - most reliable
    final videoHosts = [
      'youtube.com',
      'youtu.be',
      'vimeo.com',
      'dailymotion.com',
      'twitch.tv',
      'tiktok.com',
      'facebook.com/watch',
      'twitter.com/i/broadcasts',
      'video.', // Common subdomain for video content
      'videos.', // Common subdomain for video content
    ];
    
    if (videoHosts.any((host) => url.contains(host))) {
      return true;
    }
    
    // Check if cleaned URL ends with video file extension
    final videoExtensions = ['.mp4', '.webm', '.mov', '.avi', '.mkv', '.flv', '.m4v', '.ogv', '.wmv', '.mpg', '.mpeg'];
    
    for (final ext in videoExtensions) {
      if (cleanedUrl.endsWith(ext)) {
        return true;
      }
    }
    
    return false; // Default to false for safety - only allow explicitly video URLs
  }
}