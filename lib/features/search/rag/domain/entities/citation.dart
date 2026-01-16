import 'rag_document.dart';

/// Citation reference for tracking sources in answers
class Citation {
  final String id;
  final RagDocument document;
  final int startIndex;
  final int endIndex;

  const Citation({
    required this.id,
    required this.document,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  String toString() {
    return 'Citation(id: $id, doc: ${document.title}, range: $startIndex-$endIndex)';
  }
}
