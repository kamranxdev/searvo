import 'context_chunk.dart';

/// Result from vector search
class VectorSearchResult {
  final ContextChunk chunk;
  final double score;

  const VectorSearchResult({required this.chunk, required this.score});
}
