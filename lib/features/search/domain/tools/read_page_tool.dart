// import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/rag/services/data_ingestion/rag_scraper_adapter.dart';
import 'package:searvo/features/search/domain/tools/search_tools.dart';

class ReadPageTool extends SearchTool {
  final RAGScraperAdapter _scraperAdapter;

  ReadPageTool(this._scraperAdapter);

  @override
  String get name => 'Read Page';

  @override
  String get id => 'read_page';

  @override
  String get icon => 'article';

  @override
  String get description =>
      'Read the full content of a specific web page. Input should be a URL.';

  @override
  Future<ToolResult> execute(
    String query, {
    Map<String, dynamic>? params,
  }) async {
    try {
      // The query for this tool is the URL itself
      final url = query.trim();
      if (!url.startsWith('http')) {
        return ToolResult.failure('Invalid URL provided: $url');
      }

      final document = await _scraperAdapter.scrape(
        url,
        relevanceScore: 1.0, // Assumption
        useCache: true,
      );

      if (document.content.isEmpty) {
        return ToolResult.failure(
          'Failed to extract content from $url. The page might be empty or protected.',
        );
      }

      // Check if it was a failed scrape based on metadata
      if (document.metadata['scraped'] == false) {
        return ToolResult.failure(document.snippet ?? 'Failed to scrape page.');
      }

      return ToolResult.success(
        "Content from $url:\n\n${document.content}",
        documents: [document],
      );
    } catch (e) {
      return ToolResult.failure('Error reading page: $e');
    }
  }
}
