import 'dart:async';

import '../../domain/repositories/search_repository.dart';
import '../../domain/entities/source_item.dart';

import '../../domain/entities/search_enums.dart';
import '../datasources/searxng_remote_data_source.dart';
import '../datasources/search_local_data_source.dart';
import '../../../settings/services/search_provider_settings_service.dart';

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

    // Get settings
    final settingsService = SearchProviderSettingsService();
    final safeSearch = settingsService.getSafeSearch();
    final region = settingsService.getRegion();
    final timeout = settingsService.getMaxSearchTime();

    final response = await remoteDataSource.search(
      query,
      page: page,
      searchType: searchType,
      safeSearch: safeSearch,
      region: region,
      timeoutLimit: timeout,
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
