import '../../agent/models/agent_tool.dart';
import '../../rag/services/orchestration/rag_orchestrator.dart';
import '../../../search/models/search_mode.dart';

class WebSearchTool extends AgentTool {
  final RAGOrchestrator _ragOrchestrator;

  WebSearchTool({required RAGOrchestrator ragOrchestrator})
    : _ragOrchestrator = ragOrchestrator,
      super(
        id: 'web_search',
        name: 'Web Search',
        description:
            'Search the web for information, news, and answers using RAG.',
      );

  @override
  Future<bool> get isAvailable async => _ragOrchestrator.isReady;

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
    },
    'required': ['query'],
  };

  @override
  Future<dynamic> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final modeStr = input['mode'] as String? ?? 'search';

    SearchMode mode;
    switch (modeStr) {
      case 'research':
        mode = SearchMode.research;
        break;
      case 'study':
        mode = SearchMode.study;
        break;
      default:
        mode = SearchMode.search;
    }

    final response = await _ragOrchestrator.generateRAGResponse(
      query,
      searchMode: mode,
    );

    return {
      'answer': response.answer,
      'sources': response.sources
          .map(
            (s) => {
              'title': s.title,
              'url': s.url,
              'description': s.description,
              'thumbnail': s.thumbnail,
              'domain': s.domain,
              'source': s.source,
              'publishedDate': s.publishedDate?.toIso8601String(),
            },
          )
          .toList(),
      'images': response.images,
      'videos': response.videos.map((v) => v.toMap()).toList(),
    };
  }
}
