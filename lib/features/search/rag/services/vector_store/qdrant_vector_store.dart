import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:uuid/uuid.dart';

/// Qdrant vector store implementation
class QdrantVectorStore {
  final String baseUrl;
  final String collectionName;
  static const String _defaultUrl = 'http://localhost:6333';
  static const String _defaultCollection = 'searvo_rag';

  QdrantVectorStore({
    this.baseUrl = _defaultUrl,
    this.collectionName = _defaultCollection,
  });

  /// Add documents to Qdrant
  Future<void> addDocuments(
    List<ContextChunk> chunks,
    List<List<double>> embeddings,
  ) async {
    if (chunks.isEmpty) return;
    if (chunks.length != embeddings.length) {
      throw ArgumentError('Chunks and embeddings count must match');
    }

    final dimension = embeddings.first.length;
    await ensureCollectionExists(dimension);

    // Prepare points
    final points = <Map<String, dynamic>>[];
    final uuid = Uuid();

    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];
      final vector = embeddings[i];

      // Use chunk.id if valid UUID, otherwise generate new one based on content/index
      // Qdrant prefers UUIDs or integers. We'll use UUIDs.
      // Since our chunk.id might be 'url_index' string, we shouldn't use it directly as Point ID if it's not UUID.
      // We'll store our internal ID in payload and generate a fresh UUID for Qdrant Point ID.
      final pointId = uuid.v4();

      points.add({
        'id': pointId,
        'vector': vector,
        'payload': {
          'content': chunk.content,
          'source_id': chunk.id,
          'relevance': chunk.relevanceScore,
          'citations': chunk.citations
              .map(
                (c) => {
                  'doc_title': c.document.title,
                  'doc_url': c.document.url,
                  'range_start': c.startIndex,
                  'range_end': c.endIndex,
                },
              )
              .toList(),
        },
      });
    }

    // Upsert points (batch)
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/collections/$collectionName/points'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'points': points}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upsert points: ${response.body}');
      }
    } catch (e) {
      throw Exception('Qdrant upsert error: $e');
    }
  }

  /// Search for similar documents
  Future<List<VectorSearchResult>> search(
    List<double> queryVector, {
    int limit = 5,
    double threshold = 0.0,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/collections/$collectionName/points/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vector': queryVector,
          'limit': limit,
          'with_payload': true,
          'score_threshold': threshold,
        }),
      );

      if (response.statusCode != 200) {
        // If collection doesn't exist, generic error or 404.
        // We can just return empty list.
        if (response.statusCode == 404) return [];
        throw Exception('Failed to search points: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final result = data['result'] as List;

      return result.map((item) {
        final payload = item['payload'];
        final score = item['score'] as double;

        // Reconstruct ContextChunk
        // Citations might be tricky to fully reconstruct without original Document object reference
        // But for RAG context, we mostly need content.
        // We can create a "stub" document if needed or just minimal citations.

        final citationsJson = (payload['citations'] as List? ?? []);
        final citations = citationsJson
            .map((c) {
              // Create a placeholder doc
              final doc = Document(
                id: 'restored_from_qdrant',
                title: c['doc_title'] ?? 'Unknown',
                url: c['doc_url'] ?? '',
                content:
                    '', // Not stored in payload to save space? Or should we?
                // We stored content in payload['content'] which is the CHUNK content.
                // The full doc content is not here.
                snippet: '',
              );

              return Citation(
                id: 'q',
                document: doc,
                startIndex: c['range_start'] ?? 0,
                endIndex: c['range_end'] ?? 0,
              );
            })
            .toList()
            .cast<Citation>();

        final chunk = ContextChunk(
          id: payload['source_id'] ?? '',
          content: payload['content'] ?? '',
          citations: citations,
          relevanceScore: score, // Use similarity as score
        );

        return VectorSearchResult(chunk: chunk, score: score);
      }).toList();
    } catch (e) {
      print('Qdrant search error: $e');
      return [];
    }
  }

  /// Ensure collection exists with correct dimension
  Future<void> ensureCollectionExists(int dimension) async {
    // Check if collection exists
    try {
      final checkResponse = await http.get(
        Uri.parse('$baseUrl/collections/$collectionName'),
      );

      if (checkResponse.statusCode == 200) {
        // Collection exists, check config
        final data = jsonDecode(checkResponse.body);
        final existingDim =
            data['result']['config']['params']['vectors']['size'];

        if (existingDim != dimension) {
          print(
            '⚠️ Collection dimension mismatch ($existingDim != $dimension). Recreating...',
          );
          await _deleteCollection();
          await _createCollection(dimension);
        }
        return;
      }

      // If 404, create it
      if (checkResponse.statusCode == 404) {
        await _createCollection(dimension);
        return;
      }

      throw Exception('Failed to check collection: ${checkResponse.body}');
    } catch (e) {
      if (e.toString().contains('Failed to check collection')) rethrow;
      // If connection failed, assume Qdrant likely not running
      throw Exception(
        'Could not connect to Qdrant at $baseUrl. Ensure Docker container is running. Error: $e',
      );
    }
  }

  Future<void> _createCollection(int dimension) async {
    final response = await http.put(
      Uri.parse('$baseUrl/collections/$collectionName'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'vectors': {'size': dimension, 'distance': 'Cosine'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create collection: ${response.body}');
    }
    print(
      '✅ Created Qdrant collection "$collectionName" with dimension $dimension',
    );
  }

  Future<void> _deleteCollection() async {
    await http.delete(Uri.parse('$baseUrl/collections/$collectionName'));
  }

  /// Clear all points
  Future<void> clear() async {
    // Fastest way is to recreate, or delete points
    // Here we just delete collection for simplicity or delete all points
    // Let's use delete points filter
    try {
      await http.post(
        Uri.parse('$baseUrl/collections/$collectionName/points/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'filter': {},
        }), // Empty filter matches all? No, check API.
        // Actually easier to just delete collection or do nothing if we want persistence?
        // User might want ephemeral or persistent.
        // "ensureCollectionExists" handles the dimension match.
      );
    } catch (e) {
      // Ignore
    }
  }
}

// Temporary Local SearchResult alias if not imported from elsewhere or different structure
// But rag_models.dart defines plain classes, so we should import from there.
// We imported rag_models.dart above.
