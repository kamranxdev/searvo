import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../entities/agent/agent_tool.dart';

class WikipediaTool extends AgentTool {
  WikipediaTool()
    : super(
        id: 'wikipedia',
        name: 'Wikipedia',
        description:
            'Search for and retrieve summaries from Wikipedia articles.',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The topic or article title to search for.',
      },
    },
    'required': ['query'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;

    try {
      // 1. Search for the most relevant page title
      final searchUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=opensearch&search=$query&limit=1&namespace=0&format=json',
      );
      final searchResponse = await http.get(searchUrl);

      if (searchResponse.statusCode != 200) {
        return {'error': 'Failed to search Wikipedia'};
      }

      final searchData = json.decode(searchResponse.body) as List;
      if (searchData.length < 2 || (searchData[1] as List).isEmpty) {
        return {'error': 'No Wikipedia article found for "$query"'};
      }

      final title = searchData[1][0] as String;
      final url = searchData[3][0] as String;

      // 2. Get the content summary
      final contentUrl = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&exintro&explaintext&redirects=1&titles=$title',
      );
      final contentResponse = await http.get(contentUrl);

      if (contentResponse.statusCode != 200) {
        return {
          'title': title,
          'url': url,
          'error': 'Failed to fetch article content',
        };
      }

      final contentData = json.decode(contentResponse.body);
      final pages = contentData['query']['pages'] as Map<String, dynamic>;
      final pageId = pages.keys.first;

      if (pageId == '-1') {
        return {'error': 'Article content not found'};
      }

      final extract = pages[pageId]['extract'] as String;

      return {
        'title': title,
        'summary': extract,
        'url': url,
        'source': 'Wikipedia',
      };
    } catch (e) {
      return {'error': 'Wikipedia error: $e'};
    }
  }
}
