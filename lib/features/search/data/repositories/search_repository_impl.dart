import 'dart:async';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_data_source.dart';
import '../models/search_stream_update.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<SearchStreamUpdate> streamSearch(
    String query, {
    List<dynamic>? attachments,
    String? conversationId,
    List<Map<String, dynamic>>? previousMessages,
    String searchType = 'general',
  }) {
    return remoteDataSource.streamSearch(
      query,
      attachments: attachments,
      conversationId: conversationId,
      previousMessages: previousMessages,
      searchType: searchType,
    );
  }

  @override
  Future<List<String>> getSuggestions(String query) {
    return remoteDataSource.getSuggestions(query);
  }
}
