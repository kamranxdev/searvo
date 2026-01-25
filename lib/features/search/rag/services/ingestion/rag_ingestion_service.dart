import 'package:langchain_core/documents.dart';
import 'package:uuid/uuid.dart';
import '../vector_store/qdrant_vector_store.dart';
import 'package:langchain/langchain.dart';

/// Service responsible for ingesting content into the RAG system
class RAGIngestionService {
  final QdrantVectorStore _vectorStore;

  RAGIngestionService({required QdrantVectorStore vectorStore})
    : _vectorStore = vectorStore;

  /// Ingest raw text content
  Future<List<String>> ingestText({
    required String text,
    required Map<String, dynamic> metadata,
    int chunkSize = 1000,
    int chunkOverlap = 200,
  }) async {
    if (text.isEmpty) return [];

    // 1. Create a base document
    // We add a unique ID to the metadata to track source
    final sourceId = metadata['sourceId'] ?? const Uuid().v4();
    final enrichedMetadata = {
      ...metadata,
      'sourceId': sourceId,
      'ingestedAt': DateTime.now().toIso8601String(),
    };

    final baseDoc = Document(
      id: sourceId,
      pageContent: text,
      metadata: enrichedMetadata,
    );

    // 1b. Clear existing vectors for this file if re-ingesting
    if (metadata.containsKey('filename')) {
      final filename = metadata['filename'] as String;
      print('Clearing existing vectors for file: $filename');
      await _vectorStore.deleteByMetadata('filename', filename);
    }

    // 2. Split text into chunks
    final splitter = RecursiveCharacterTextSplitter(
      chunkSize: chunkSize,
      chunkOverlap: chunkOverlap,
    );

    // We split the single document into chunked documents
    final chunks = splitter.splitDocuments([baseDoc]);

    // 3. Store in Vector Store
    // The QdrantVectorStore implementation handles embedding generation internally
    // via its 'embeddings' property passed in constructor
    final ids = await _vectorStore.addDocuments(documents: chunks);

    return ids;
  }

  /// Remove content by source ID (if supported by vector store schema)
  Future<void> removeContent(String sourceId) async {
    // This would require Qdrant to support delete by filter
    // For now, we assume direct ID deletion or implement filter deletion later
    // dependent on QdrantVectorStore capabilities
    // _vectorStore.delete(ids: [sourceId]); // This usually expects point IDs, not source payload IDs
  }
}
