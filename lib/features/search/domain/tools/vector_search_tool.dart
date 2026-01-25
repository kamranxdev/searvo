import 'package:langchain_core/vector_stores.dart';
import '../../rag/services/vector_store/qdrant_vector_store.dart';
import '../entities/agent/agent_tool.dart';

class VectorSearchTool extends AgentTool {
  final QdrantVectorStore _vectorStore;

  VectorSearchTool(this._vectorStore)
    : super(
        id: 'vector_search',
        name: 'Vector Search',
        description:
            'Searching through uploaded documents and attachments. Use this tool when the user asks questions about specific files, contexts, or "my documents".',
      );

  @override
  Future<bool> get isAvailable async => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'query': {
        'type': 'string',
        'description': 'The search query to find relevant documents',
      },
      'k': {
        'type': 'integer',
        'description': 'Number of results to return (default: 5)',
      },
    },
    'required': ['query'],
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input) async {
    final query = input['query'] as String;
    final k = input['k'] as int? ?? 5;

    try {
      final results = await _vectorStore.similaritySearch(
        query: query,
        config: VectorStoreSimilaritySearch(k: k),
      );

      if (results.isEmpty) {
        return {
          'success': true,
          'documents': [],
          'message': 'No relevant documents found in the knowledge base.',
        };
      }

      final docs = results
          .map((d) => {'content': d.pageContent, 'metadata': d.metadata})
          .toList();

      return {'success': true, 'documents': docs, 'count': docs.length};
    } catch (e) {
      return {'success': false, 'error': 'Failed to search vector store: $e'};
    }
  }
}
