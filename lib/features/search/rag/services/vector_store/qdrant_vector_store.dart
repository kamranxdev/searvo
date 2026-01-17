import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:langchain_core/vector_stores.dart';
import 'package:langchain_core/documents.dart' as lc;
import 'package:uuid/uuid.dart';

/// Qdrant vector store implementation compatible with LangChain
class QdrantVectorStore extends VectorStore {
  final String baseUrl;
  final String? apiKey;
  final String collectionName;

  QdrantVectorStore({
    required super.embeddings,
    this.baseUrl = 'http://localhost:6333',
    this.apiKey,
    this.collectionName = 'searvo_knowledge_base',
  });

  @override
  Future<List<String>> addDocuments({
    required List<lc.Document> documents,
  }) async {
    if (documents.isEmpty) return [];

    // Generate embeddings
    final vectors = await embeddings.embedDocuments(documents);

    return addVectors(vectors: vectors, documents: documents);
  }

  @override
  Future<List<String>> addVectors({
    required List<List<double>> vectors,
    required List<lc.Document> documents,
  }) async {
    if (vectors.length != documents.length) {
      throw ArgumentError('Vectors and documents must have the same length');
    }

    if (vectors.isEmpty) return [];

    // Ensure collection exists (lazy check or assume exists/create if 404 handled in logic)
    // For simplicity, we assume collection exists or we try to create it if we had a setup method.
    // Here we just push points.

    final ids = <String>[];
    final points = <Map<String, dynamic>>[];

    for (var i = 0; i < vectors.length; i++) {
      final id = documents[i].id ?? const Uuid().v4();
      ids.add(id);

      points.add({
        'id': id,
        'vector': vectors[i],
        'payload': {
          'pageContent': documents[i].pageContent,
          ...documents[i].metadata,
        },
      });
    }

    final response = await http.put(
      Uri.parse('$baseUrl/collections/$collectionName/points'),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey != null) 'api-key': apiKey!,
      },
      body: jsonEncode({'points': points}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add vectors to Qdrant: ${response.body}');
    }

    return ids;
  }

  @override
  Future<List<(lc.Document, double)>> similaritySearchByVectorWithScores({
    required List<double> embedding,
    VectorStoreSimilaritySearch config = const VectorStoreSimilaritySearch(),
  }) async {
    final k = config.k;
    final response = await http.post(
      Uri.parse('$baseUrl/collections/$collectionName/points/search'),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey != null) 'api-key': apiKey!,
      },
      body: jsonEncode({'vector': embedding, 'limit': k, 'with_payload': true}),
    );

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body);
    final result = data['result'] as List;

    return result.map<(lc.Document, double)>((item) {
      final payload = item['payload'];
      final doc = lc.Document(
        pageContent: payload['pageContent'] as String? ?? '',
        metadata: (payload as Map<String, dynamic>)..remove('pageContent'),
      );
      final score = (item['score'] as num?)?.toDouble() ?? 0.0;
      return (doc, score);
    }).toList();
  }

  /// Ensure collection exists with correct dimension (Helper method)
  Future<void> ensureCollectionExists(int dimension) async {
    // Implementation omitted for brevity/focus on interface conformance
  }

  @override
  Future<bool> delete({required List<String> ids}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/collections/$collectionName/points/delete'),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey != null) 'api-key': apiKey!,
      },
      body: jsonEncode({'points': ids}),
    );
    return response.statusCode == 200;
  }

  @override
  Future<List<lc.Document>> similaritySearch({
    required String query,
    VectorStoreSimilaritySearch config = const VectorStoreSimilaritySearch(),
  }) async {
    final docsWithScores = await similaritySearchWithScores(
      query: query,
      config: config,
    );
    return docsWithScores.map((e) => e.$1).toList();
  }

  @override
  Future<List<(lc.Document, double)>> similaritySearchWithScores({
    required String query,
    VectorStoreSimilaritySearch config = const VectorStoreSimilaritySearch(),
  }) async {
    final vectors = await embeddings.embedQuery(query);
    return await similaritySearchByVectorWithScores(
      embedding: vectors,
      config: config,
    );
  }
}
