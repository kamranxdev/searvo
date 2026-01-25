import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/domain/entities/search_enums.dart';
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';

class ImageSearchTool extends AgentTool {
  final SearXNGRemoteDataSource _service;

  ImageSearchTool(this._service)
    : super(
        id: 'image_search',
        name: 'Image Search',
        description: 'Search for images and visual content.',
      );

  @override
  Future<bool> get isAvailable async => _service.isConfigured;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {'type': 'string', 'description': 'Search query for images'},
    },
    'required': ['query'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    try {
      final response = await _service.search(
        query,
        searchType: SearchType.images,
        resultsPerPage: 20,
      );

      return {
        'success': true,
        'documents': [],
        'images': response.results.map((r) => r.imgSrc ?? r.url).toList(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
