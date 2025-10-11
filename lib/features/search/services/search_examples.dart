import 'package:searvo/features/search/services/search_service.dart';

/// Examples demonstrating the enhanced search capabilities
/// Run with: flutter run lib/services/search/search_examples.dart
void main() async {
  final searchService = SearchService();
  await searchService.initialize();

  // Example 1: Multi-Type Search
  await example1MultiTypeSearch(searchService);

  // Example 2: Web Scraping
  await example2WebScraping(searchService);

  // Example 3: Query Analysis
  await example3QueryAnalysis(searchService);

  // Example 4: Complex Query with AI Answer
  await example4ComplexQuery(searchService);

  print('\n✅ All examples completed!');
}

/// Example 1: Search across different content types
Future<void> example1MultiTypeSearch(SearchService service) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Example 1: Multi-Type Search');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // News search with recency filter
  final news = await service.searchByType(
    query: "AI developments",
    searchType: SearchType.news,
    recency: SearchRecency.day,
    maxResults: 10,
  );
  print('📰 News (past day): ${news.results.length} articles');

  // Scholar search
  final scholar = await service.searchByType(
    query: "retrieval augmented generation",
    searchType: SearchType.scholar,
    maxResults: 10,
  );
  print('📚 Scholar: ${scholar.results.length} papers');

  // Shopping search
  final shopping = await service.searchByType(
    query: "best laptops 2024",
    searchType: SearchType.shopping,
    maxResults: 10,
  );
  print('🛍️  Shopping: ${shopping.results.length} products');

  // Images
  final images = await service.searchByType(
    query: "aurora borealis",
    searchType: SearchType.images,
    maxResults: 20,
  );
  print('🖼️  Images: ${images.results.length} images');

  // Videos
  final videos = await service.searchByType(
    query: "machine learning tutorial",
    searchType: SearchType.videos,
    maxResults: 10,
  );
  print('🎥 Videos: ${videos.results.length} videos\n');
}

/// Example 2: Web scraping for full content
Future<void> example2WebScraping(SearchService service) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Example 2: Web Scraping');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  // Search first to get URLs
  final results = await service.searchByType(
    query: "artificial intelligence overview",
    maxResults: 3,
  );

  print('🔍 Found ${results.results.length} results, scraping top 3...\n');

  // Scrape the top results
  final urls = results.results.take(3).map((r) => r.url).toList();
  final scrapedContents = await service.scrapeMultipleUrls(urls);

  for (int i = 0; i < scrapedContents.length; i++) {
    final content = scrapedContents[i];
    if (content.success) {
      print('✅ ${content.title}');
      print('   Words: ${content.wordCount}');
      print('   URL: ${content.url}\n');
    } else {
      print('❌ Failed: ${content.url}');
      print('   Error: ${content.error}\n');
    }
  }
}

/// Example 3: Query analysis
Future<void> example3QueryAnalysis(SearchService service) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Example 3: Query Analysis');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final query = "Compare Python vs JavaScript for web development in 2024";
  final analysis = service.analyzeQuery(query);

  print('Query: "$query"\n');
  print('Intent: ${analysis.intentType}');
  print('Complexity: ${analysis.complexity['level']}');
  print('Temporal Context: ${analysis.hasTemporalContext}');
  print('Keywords: ${analysis.keywords.join(", ")}');
  print('Entities: ${analysis.entities.join(", ")}');
  print('Suggested Search Types: ${analysis.suggestedSearchTypes.join(", ")}');

  if (analysis.subQueries.isNotEmpty) {
    print('\nSub-queries:');
    for (int i = 0; i < analysis.subQueries.length; i++) {
      print('  ${i + 1}. ${analysis.subQueries[i]}');
    }
  }
  print('');
}

/// Example 4: Complex query with full RAG pipeline
Future<void> example4ComplexQuery(SearchService service) async {
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  print('Example 4: AI-Powered Answer Generation');
  print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  final query = "What are the key differences between transformer and LSTM architectures?";
  
  print('Generating comprehensive answer for:');
  print('"$query"\n');

  final answer = await service.generateSearchResponse(
    query,
    maxSearchResults: 25,
    maxRelevantDocuments: 12,
    enableQueryEnhancement: true,
  );

  print('✅ Answer generated successfully!');
  print('   Sources used: ${answer.sources.length}');
  print('   Related questions: ${answer.relatedQuestions.length}');
  print('   Answer length: ${answer.answer.length} characters\n');

  // Show first 300 characters of answer
  final preview = answer.answer.length > 300 
      ? answer.answer.substring(0, 300) + '...'
      : answer.answer;
  print('Answer preview:');
  print(preview);
  print('');
}

/// Advanced example: Multi-source research
class AdvancedExamples {
  final SearchService service;

  AdvancedExamples(this.service);

  /// Research a topic using multiple search types
  Future<void> comprehensiveResearch(String topic) async {
    print('🔬 Comprehensive Research: $topic\n');

    // 1. General web search
    final general = await service.searchByType(
      query: topic,
      maxResults: 10,
    );
    print('📄 General results: ${general.results.length}');

    // 2. Recent news
    final news = await service.searchByType(
      query: topic,
      searchType: SearchType.news,
      recency: SearchRecency.week,
      maxResults: 5,
    );
    print('📰 News (past week): ${news.results.length}');

    // 3. Academic papers
    final scholar = await service.searchByType(
      query: topic,
      searchType: SearchType.scholar,
      maxResults: 5,
    );
    print('📚 Scholar papers: ${scholar.results.length}');

    // 4. Scrape top general results
    print('\n🌐 Scraping top 3 sources...');
    final topUrls = general.results.take(3).map((r) => r.url).toList();
    final scraped = await service.scrapeMultipleUrls(topUrls);
    
    final successful = scraped.where((s) => s.success).length;
    print('✅ Successfully scraped: $successful/${topUrls.length}');

    // 5. Generate AI answer
    print('\n🤖 Generating comprehensive answer...');
    final answer = await service.generateSearchResponse(
      topic,
      maxSearchResults: 20,
      maxRelevantDocuments: 15,
    );
    
    print('✅ Complete! Used ${answer.sources.length} sources');
  }

  /// Monitor news for multiple topics
  Future<void> newsMonitoring(List<String> topics) async {
    print('📡 News Monitoring\n');

    for (final topic in topics) {
      final news = await service.searchByType(
        query: topic,
        searchType: SearchType.news,
        recency: SearchRecency.day,
        maxResults: 5,
      );

      print('$topic: ${news.results.length} updates');
      for (final article in news.results.take(3)) {
        print('  • ${article.title}');
      }
      print('');
    }
  }

  /// Academic paper discovery and extraction
  Future<void> academicResearch(String topic) async {
    print('🎓 Academic Research: $topic\n');

    // Find papers
    final papers = await service.searchByType(
      query: topic,
      searchType: SearchType.scholar,
      maxResults: 10,
    );

    print('Found ${papers.results.length} papers\n');

    // Try to extract PDF content
    for (final paper in papers.results.take(3)) {
      if (paper.url.toLowerCase().endsWith('.pdf')) {
        print('📄 Extracting: ${paper.title}');
        try {
          final pdf = await service.extractPdfContent(paper.url);
          if (pdf.success) {
            print('   ✅ ${pdf.pageCount} pages, ${pdf.text.length} chars\n');
          } else {
            print('   ❌ ${pdf.error}\n');
          }
        } catch (e) {
          print('   ❌ Error: $e\n');
        }
      }
    }
  }
}
