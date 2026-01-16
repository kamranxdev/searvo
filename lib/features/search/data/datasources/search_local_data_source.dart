import 'dart:collection';
import '../../rag/models/rag_models.dart';
import '../models/search_response_model.dart';
import '../../rag/domain/entities/rag_document.dart';
import '../../domain/entities/search_enums.dart';

/// Service to cache search results and scraped content to improve performance
class SearchLocalDataSource {
  static final SearchLocalDataSource _instance =
      SearchLocalDataSource._internal();
  factory SearchLocalDataSource() => _instance;
  SearchLocalDataSource._internal();

  // Cache configuration
  static const int _maxSearchResultsCache = 200;
  static const int _maxScrapedContentCache = 200;
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Search results cache: key -> {timestamp, response}
  final _searchResultsCache =
      LinkedHashMap<String, _CacheEntry<SearchResponseModel>>();

  // Scraped content cache: url -> {timestamp, document}
  final _scrapedContentCache =
      LinkedHashMap<String, _CacheEntry<RagDocument>>();

  /// Generate a cache key for search requests
  String _generateSearchKey(
    String query,
    SearchType type,
    SearchRecency recency,
  ) {
    return '${query.trim().toLowerCase()}|${type.name}|${recency.name}';
  }

  /// Get cached search response if available and valid
  SearchResponseModel? getCachedSearch(
    String query,
    SearchType type,
    SearchRecency recency,
  ) {
    final key = _generateSearchKey(query, type, recency);
    final entry = _searchResultsCache[key];

    if (entry != null) {
      if (DateTime.now().difference(entry.timestamp) < _cacheDuration) {
        print('⚡ Cache hit for search: "$query" (${type.name})');
        // Move to end (most recently used)
        _searchResultsCache.remove(key);
        _searchResultsCache[key] = entry;
        return entry.data;
      } else {
        // Expired
        _searchResultsCache.remove(key);
      }
    }
    return null;
  }

  /// Cache a search response
  void cacheSearch(
    String query,
    SearchType type,
    SearchRecency recency,
    SearchResponseModel response,
  ) {
    final key = _generateSearchKey(query, type, recency);

    // Evict oldest if full
    if (_searchResultsCache.length >= _maxSearchResultsCache) {
      _searchResultsCache.remove(_searchResultsCache.keys.first);
    }

    _searchResultsCache[key] = _CacheEntry(
      data: response,
      timestamp: DateTime.now(),
    );
  }

  /// Get cached scraped document if available and valid
  RagDocument? getCachedDocument(String url) {
    final entry = _scrapedContentCache[url];

    if (entry != null) {
      if (DateTime.now().difference(entry.timestamp) < _cacheDuration) {
        print('⚡ Cache hit for URL: $url');
        // Move to end (most recently used)
        _scrapedContentCache.remove(url);
        _scrapedContentCache[url] = entry;
        return entry.data;
      } else {
        // Expired
        _scrapedContentCache.remove(url);
      }
    }
    return null;
  }

  /// Cache a scraped document
  void cacheDocument(String url, RagDocument document) {
    // Evict oldest if full
    if (_scrapedContentCache.length >= _maxScrapedContentCache) {
      _scrapedContentCache.remove(_scrapedContentCache.keys.first);
    }

    _scrapedContentCache[url] = _CacheEntry(
      data: document,
      timestamp: DateTime.now(),
    );
  }

  /// Clear all caches
  void clear() {
    _searchResultsCache.clear();
    _scrapedContentCache.clear();
    print('🧹 Cache cleared');
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry({required this.data, required this.timestamp});
}
