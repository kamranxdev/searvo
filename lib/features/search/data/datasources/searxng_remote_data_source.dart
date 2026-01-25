import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/search_response_model.dart';

import '../../domain/entities/search_enums.dart';

/// Direct SearXNG search service without provider abstraction
class SearXNGRemoteDataSource {
  http.Client? _httpClient;
  String _baseUrl = 'http://localhost:4000';
  int _timeout = 30;
  bool _isInitialized = false;

  static final SearXNGRemoteDataSource _instance =
      SearXNGRemoteDataSource._internal();
  factory SearXNGRemoteDataSource() => _instance;
  SearXNGRemoteDataSource._internal();

  /// Initialize the service with configuration
  Future<void> initialize({String? baseUrl, int timeout = 30}) async {
    if (_isInitialized && baseUrl == _baseUrl) return;

    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
    }
    _timeout = timeout;
    _httpClient = http.Client();
    _isInitialized = true;

    print('✅ SearXNG service initialized at $_baseUrl');
  }

  /// Check if the service is configured and ready
  bool get isConfigured => _isInitialized && _baseUrl.isNotEmpty;

  /// Get the current endpoint URL
  String get endpoint => _baseUrl;

  /// Perform a search with enhanced parameters
  Future<SearchResponseModel> search(
    String query, {
    int page = 1,
    String category = 'general',
    String language = 'auto',
    int resultsPerPage = 10,
    SearchType searchType = SearchType.general,
    SearchRecency recency = SearchRecency.any,
    String? region,
    int? safeSearch,
    double? timeoutLimit,
  }) async {
    if (!isConfigured || _httpClient == null) {
      throw Exception(
        'SearXNG service is not configured. Please ensure SearXNG is running at $_baseUrl',
      );
    }

    try {
      // Map search type to SearXNG category
      String searxngCategory = category;
      switch (searchType) {
        case SearchType.news:
          searxngCategory = 'news';
          break;
        case SearchType.images:
          searxngCategory = 'images';
          break;
        case SearchType.videos:
          searxngCategory = 'videos';
          break;
        case SearchType.scholar:
          searxngCategory = 'science';
          break;
        case SearchType.shopping:
          // SearXNG doesn't have a standard shopping category
          // Use general with expanded reach
          searxngCategory = 'general';
          query = '$query shop buy';
          break;
        case SearchType.general:
          searxngCategory = 'general';
          break;
      }

      // Map recency to SearXNG time_range
      String timeRange = '';
      switch (recency) {
        case SearchRecency.day:
          timeRange = 'day';
          break;
        case SearchRecency.week:
          timeRange = 'week';
          break;
        case SearchRecency.month:
          timeRange = 'month';
          break;
        case SearchRecency.year:
          timeRange = 'year';
          break;
        case SearchRecency.any:
          timeRange = '';
          break;
      }

      // Build the search URL
      final uri = Uri.parse('${_baseUrl.trimEnd('/')}/search');

      final queryParams = {
        'q': query,
        'format': 'json',
        'pageno': page.toString(),
        'categories': searxngCategory,
        'language': language,
        if (timeRange.isNotEmpty) 'time_range': timeRange,
        'safesearch': (safeSearch ?? 0).toString(),
      };

      // Add region if specified
      if (region != null && region.isNotEmpty) {
        queryParams['region'] = region;
      } else {
        // Explicitly set 'all' or empty string if not provided to avoid sticky session issues
        // queryParams['region'] = '';
      }

      // Add timeout_limit if provided (SearXNG API parameter)
      if (timeoutLimit != null) {
        queryParams['timeout_limit'] = timeoutLimit.toString();
      }

      // NO HARDCODED ENGINES - Let SearXNG configuration decide!
      // This allows fallback to other engines (DDG, Qwant) if Google/Bing fail.

      final searchUri = uri.replace(queryParameters: queryParams);

      // Make the request
      final response = await _httpClient!
          .get(
            searchUri,
            headers: {'Accept': 'application/json', 'User-Agent': 'Searvo/1.0'},
          )
          .timeout(Duration(seconds: _timeout));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SearchResponseModel.fromSearXNG(
          jsonData,
          query,
          searchType: searchType,
        );
      } else {
        throw HttpException(
          'Search request failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception(
          'Failed to connect to SearXNG at $_baseUrl. Please check the endpoint URL and ensure SearXNG is running.',
        );
      } else if (e is HttpException) {
        throw Exception('Search request failed: ${e.message}');
      } else {
        throw Exception('Search failed: ${e.toString()}');
      }
    }
  }

  /// Test connection to SearXNG
  Future<bool> testConnection({String? customUrl}) async {
    final testUrl = customUrl ?? _baseUrl;

    try {
      // Try to access the SearXNG stats endpoint or make a simple search
      final uri = Uri.parse('${testUrl.trimEnd('/')}/stats');

      final response = await http.Client()
          .get(uri, headers: {'User-Agent': 'Searvo/1.0'})
          .timeout(Duration(seconds: 10));

      // If stats endpoint is not available, try a simple search
      if (response.statusCode == 404) {
        final searchUri = Uri.parse('${testUrl.trimEnd('/')}/search');
        final testResponse = await http.Client()
            .get(
              searchUri.replace(
                queryParameters: {'q': 'test', 'format': 'json', 'pageno': '1'},
              ),
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'Searvo/1.0',
              },
            )
            .timeout(Duration(seconds: 10));

        return testResponse.statusCode == 200;
      }

      return response.statusCode == 200;
    } catch (e) {
      print('❌ SearXNG connection test failed: $e');
      return false;
    }
  }

  /// Get search suggestions
  Future<List<String>> getSuggestions(String query) async {
    if (!isConfigured) return [];

    try {
      final uri = Uri.parse('${_baseUrl.trimEnd('/')}/autocompleter');
      final suggestionUri = uri.replace(
        queryParameters: {'q': query, 'format': 'json'},
      );

      final response = await http.Client()
          .get(suggestionUri, headers: {'User-Agent': 'Searvo/1.0'})
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Handle OpenSearch format: ["query", ["suggestion1", "suggestion2", ...]]
        if (decoded is List && decoded.length >= 2 && decoded[1] is List) {
          final suggestionsList = decoded[1] as List;
          return suggestionsList.map((e) => e.toString()).toList();
        }
        // Handle flat list format (fallback): ["suggestion1", "suggestion2"]
        else if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  /// Check if a specific search type is supported
  bool supportsSearchType(SearchType type) {
    // SearXNG supports all search types
    return true;
  }

  /// Dispose resources
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    _isInitialized = false;
  }
}

/// Extension to trim trailing characters from strings
extension StringExtension on String {
  String trimEnd(String pattern) {
    String result = this;
    while (result.endsWith(pattern)) {
      result = result.substring(0, result.length - pattern.length);
    }
    return result;
  }
}
