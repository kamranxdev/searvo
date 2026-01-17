// import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/search/rag/services/data_ingestion/rag_scraper_adapter.dart';
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class ReadPageTool extends AgentTool {
  final RAGScraperAdapter _scraperAdapter;

  ReadPageTool(this._scraperAdapter)
    : super(
        id: 'read_page',
        name: 'Read Page',
        description:
            'Read the full content of a specific web page. Input should be a URL.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'url': {'type': 'string', 'description': 'The URL of the page to read'},
    },
    'required': ['url'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final url = (input['url'] as String).trim();
    try {
      if (!url.startsWith('http')) {
        return {'success': false, 'error': 'Invalid URL provided: $url'};
      }

      final document = await _scraperAdapter.scrape(
        url,
        relevanceScore: 1.0, // Assumption
        useCache: true,
      );

      if (document.content.isEmpty) {
        return {
          'success': false,
          'error':
              'Failed to extract content from $url. The page might be empty or protected.',
        };
      }

      // Check if it was a failed scrape based on metadata
      if (document.metadata['scraped'] == false) {
        return {
          'success': false,
          'error': document.snippet ?? 'Failed to scrape page.',
        };
      }

      return {
        'success': true,
        'content': "Content from $url:\n\n${document.content}",
        'documents': [document],
      };
    } catch (e) {
      return {'success': false, 'error': 'Error reading page: $e'};
    }
  }
}
