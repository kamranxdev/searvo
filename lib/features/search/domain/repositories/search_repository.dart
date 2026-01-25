import '../entities/source_item.dart';

abstract class SearchRepository {
  /// Perform a search operation and return a stream of updates.
  Stream<dynamic> performSearch(
    String query, {
    required Map<String, dynamic> options,
  });

  /// Perform a direct search (non-streaming, simple)
  Future<List<SourceItem>> searchDirect(
    String query, {
    int page = 1,
    String? category,
  });

  /// Get autocomplete suggestions
  Future<List<String>> getSuggestions(String query);
}
