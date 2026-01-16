import 'citation.dart';

/// Context chunk for LLM prompt
class ContextChunk {
  final String id;
  final String content;
  final List<Citation> citations;
  final double relevanceScore;

  const ContextChunk({
    this.id = '',
    required this.content,
    required this.citations,
    required this.relevanceScore,
  });

  @override
  String toString() {
    return 'ContextChunk(id: $id, length: ${content.length}, citations: ${citations.length}, score: $relevanceScore)';
  }
}
