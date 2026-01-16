import 'dart:async';

import '../../domain/repositories/search_repository.dart';
import '../../domain/entities/source_item.dart';
import '../../domain/entities/search_mode.dart';
import '../../domain/entities/search_enums.dart';
import '../datasources/searxng_remote_data_source.dart';
import '../datasources/search_local_data_source.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearXNGRemoteDataSource remoteDataSource;
  final SearchLocalDataSource localDataSource;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Stream<dynamic> performSearch(
    String query, {
    SearchMode searchMode = SearchMode.search,
    required Map<String, dynamic> options,
  }) async* {
    try {
      final results = await searchDirect(query);
      yield results;
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  @override
  Future<List<SourceItem>> searchDirect(
    String query, {
    int page = 1,
    String? category,
  }) async {
    final searchType = _mapCategoryToSearchType(category);
    final response = await remoteDataSource.search(
      query,
      page: page,
      searchType: searchType,
    );
    return response.results;
  }

  @override
  Future<List<String>> getSuggestions(String query) {
    return remoteDataSource.getSuggestions(query);
  }

  SearchType _mapCategoryToSearchType(String? category) {
    if (category == null) return SearchType.general;
    switch (category.toLowerCase()) {
      case 'news':
        return SearchType.news;
      case 'images':
        return SearchType.images;
      case 'videos':
        return SearchType.videos;
      case 'scholar':
        return SearchType.scholar;
      case 'shopping':
        return SearchType.shopping;
      default:
        return SearchType.general;
    }
  }
}
