import 'package:searvo/features/search/models/search_provider_config.dart';
import 'package:searvo/features/search/services/searxng_service.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

abstract class SearchTool {
  String get name;
  String get id;
  String get icon;

  Future<ToolResult> execute(String query, {Map<String, dynamic>? params});
}

class ToolResult {
  final bool success;
  final dynamic data;
  final String? errorMessage;
  final List<Document> documents;

  ToolResult({
    required this.success,
    this.data,
    this.errorMessage,
    this.documents = const [],
  });

  factory ToolResult.success(
    dynamic data, {
    List<Document> documents = const [],
  }) {
    return ToolResult(success: true, data: data, documents: documents);
  }

  factory ToolResult.failure(String error) {
    return ToolResult(success: false, errorMessage: error);
  }
}

class WebSearchTool extends SearchTool {
  final SearXNGService _service;

  WebSearchTool(this._service);

  @override
  String get name => 'Web Search';
  @override
  String get id => 'web_search';
  @override
  String get icon => 'search';

  @override
  Future<ToolResult> execute(
    String query, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _service.search(
        query,
        searchType: SearchType.general,
        resultsPerPage: 10,
      );

      final documents = response.results
          .map((r) => Document.fromSearchResult(r))
          .toList();
      return ToolResult.success(response, documents: documents);
    } catch (e) {
      return ToolResult.failure(e.toString());
    }
  }
}

class ImageSearchTool extends SearchTool {
  final SearXNGService _service;

  ImageSearchTool(this._service);

  @override
  String get name => 'Image Search';
  @override
  String get id => 'image_search';
  @override
  String get icon => 'image';

  @override
  Future<ToolResult> execute(
    String query, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final response = await _service.search(
        query,
        searchType: SearchType.images,
        resultsPerPage: 20,
      );

      // Convert to documents but specialized for images
      final documents = response.results.map((r) {
        return Document.fromSearchResult(
          r,
        ).withRelevanceScore(1.0); // Assume high relevance for raw search
      }).toList();

      return ToolResult.success(response, documents: documents);
    } catch (e) {
      return ToolResult.failure(e.toString());
    }
  }
}

// TODO: Add VideoSearchTool, CodeSearchTool, etc.
