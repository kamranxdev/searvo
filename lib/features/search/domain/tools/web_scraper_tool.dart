import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';
import 'package:searvo/features/search/data/datasources/scrapers/scraper_manager.dart';

class WebScraperTool extends AgentTool {
  final ScraperManager _scraperManager;

  WebScraperTool({ScraperManager? scraperManager})
    : _scraperManager = scraperManager ?? ScraperManager(),
      super(
        id: 'web_scraper',
        name: 'Web Scraper',
        description:
            'Scrapes content from a specific URL. Use this to read the content of a webpage.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'url': {
        'type': 'string',
        'description': 'The URL of the webpage to scrape',
      },
    },
    'required': ['url'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final url = input['url'] as String;

    try {
      final result = await _scraperManager.scrape(url);
      return result.toJson();
    } catch (e) {
      return {'error': 'Failed to scrape URL: $e'};
    }
  }
}
