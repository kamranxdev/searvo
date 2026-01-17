import '../../entities/agent/agent_tool.dart';
import '../../../data/datasources/searxng_remote_data_source.dart';
import '../../entities/search_mode.dart';

class WebSearchTool extends AgentTool {
  final SearXNGRemoteDataSource _searxngService;

  WebSearchTool({required SearXNGRemoteDataSource searxngService})
    : _searxngService = searxngService,
      super(
        id: 'web_search',
        name: 'Web Search',
        description:
            'Search the web for information, news, and answers using SearXNG.',
      );

  @override
  Future<bool> get isAvailable async => _searxngService.isConfigured;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'description': 'The search query to execute'},
      'mode': {
        'type': 'string',
        'enum': ['search', 'research', 'study'],
        'description': 'The search mode to use',
      },
      'maxResults': {
        'type': 'integer',
        'description': 'Maximum results to return',
        'default': 10,
      },
    },
    'required': ['query'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final maxResults = input['maxResults'] as int? ?? 10;
    // Map mode if needed, but primarily we just want search results

    // Execute search
    final response = await _searxngService.search(
      query,
      resultsPerPage: maxResults,
    );

    // Return raw documents for the agent/orchestrator to process
    return {
      'success': true,
      'documents': response.results
          .map(
            (r) => {
              'title': r.title,
              'url': r.url,
              'snippet': r.snippet,
              'source': r.source,
              'publishedDate': r.publishedDate?.toIso8601String(),
              'thumbnail': r.thumbnail,
            },
          )
          .toList(),
      'images': <String>[],
      'videos': <Map<String, String>>[],
    };
  }
}
