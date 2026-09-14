import '../../data/models/search_stream_update.dart';

abstract class SearchRepository {
  /// Stream real-time search execution updates from backend
  Stream<SearchStreamUpdate> streamSearch(
    String query, {
    List<dynamic>? attachments,
    String? conversationId,
    List<Map<String, dynamic>>? previousMessages,
    String searchType = 'general',
  });

  /// Get autocomplete suggestions from backend
  Future<List<String>> getSuggestions(String query);
}
