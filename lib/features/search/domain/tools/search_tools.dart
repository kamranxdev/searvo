import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/domain/entities/search_enums.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:searvo/features/search/domain/entities/agent/agent_tool.dart';
export 'read_page_tool.dart';
export 'web_search/web_search_tool.dart';

// Helper to convert legacy ToolResult to what AgentTool expects or vice versa
// Actually AgentTool returns dynamic, so we can return a Map or similar.

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

class CalculatorTool extends AgentTool {
  CalculatorTool()
    : super(
        id: 'calculator',
        name: 'Calculator',
        description:
            'Perform mathematical calculations (usage: "5 + 5", "sqrt(144)").',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'expression': {
        'type': 'string',
        'description': 'The math expression to evaluate',
      },
    },
    'required': ['expression'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final expressionStr = input['expression'] as String;
    try {
      final cm = ContextModel();
      final parser = GrammarParser();
      final expression = parser.parse(expressionStr);
      final result = expression.evaluate(EvaluationType.REAL, cm);

      return {'success': true, 'result': result.toString()};
    } catch (e) {
      return {'success': false, 'error': "Math error: $e"};
    }
  }
}
