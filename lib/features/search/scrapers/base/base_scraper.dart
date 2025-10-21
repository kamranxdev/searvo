import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'scraper_models.dart';

/// Base abstract class for all site-specific scrapers
/// Provides common functionality and enforces implementation of core methods
abstract class BaseScraper<T extends ScraperResult> {
  final Dio _dio;
  final ScraperConfig config;
  final Map<String, T> _cache = {};

  BaseScraper({
    Dio? dio,
    this.config = const ScraperConfig(),
  }) : _dio = dio ?? _createDefaultDio(config);

  /// Create default Dio instance with proper configuration
  static Dio _createDefaultDio(ScraperConfig config) {
    final dio = Dio(BaseOptions(
      connectTimeout: Duration(seconds: config.timeout),
      receiveTimeout: Duration(seconds: config.timeout),
      sendTimeout: Duration(seconds: config.timeout),
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 500,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        ...?config.headers,
      },
    ));

    // Add interceptor for better error handling and logging
    dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException error, handler) {
        print('❌ Dio Error: ${error.type} - ${error.message}');
        return handler.next(error);
      },
    ));

    return dio;
  }

  /// Get the name of the scraper (e.g., "YouTube", "Scholar")
  String get name;

  /// Get the site domain(s) this scraper handles
  List<String> get supportedDomains;

  /// Check if this scraper can handle the given URL
  bool canHandle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final host = uri.host.toLowerCase();
    return supportedDomains.any((domain) => 
      host == domain || host.endsWith('.$domain')
    );
  }

  /// Main scraping method - must be implemented by each scraper
  Future<T> scrape(String url);

  /// Scrape multiple URLs in parallel with rate limiting
  Future<List<T>> scrapeMultiple(
    List<String> urls, {
    void Function(int completed, int total)? onProgress,
  }) async {
    print('🌐 [$name] Scraping ${urls.length} URLs (max concurrent: ${config.maxConcurrent})');
    
    final results = <T>[];
    int completed = 0;
    
    for (int i = 0; i < urls.length; i += config.maxConcurrent) {
      final batch = urls.skip(i).take(config.maxConcurrent).toList();
      final batchResults = await Future.wait(
        batch.map((url) => scrape(url)),
      );
      results.addAll(batchResults);
      completed += batch.length;
      onProgress?.call(completed, urls.length);
      
      if (i + config.maxConcurrent < urls.length) {
        await Future.delayed(Duration(milliseconds: 200));
      }
    }
    
    final successful = results.where((r) => r.success).length;
    print('✅ [$name] Successfully scraped $successful/${urls.length} URLs');
    
    return results;
  }

  /// Fetch URL with proper timeout and headers using Dio
  Future<Response> fetchWithTimeout(
    String url, {
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      // For web platform, use CORS proxy to bypass browser restrictions
      String fetchUrl = url;
      if (kIsWeb && config.useCorsProxy) {
        // Try each CORS proxy in order until one works
        for (final proxy in config.corsProxies) {
          fetchUrl = '$proxy${Uri.encodeComponent(url)}';
          print('🌐 [CORS Proxy] Attempting: $fetchUrl');
          
          try {
            final response = await _dio.get(
              fetchUrl,
              options: Options(
                headers: additionalHeaders,
                responseType: ResponseType.plain,
              ),
            );
            
            if (response.statusCode == 200) {
              print('✅ [CORS Proxy] Success via: $proxy');
              return response;
            }
          } catch (e) {
            print('⚠️  [CORS Proxy] Failed with $proxy: $e');
            continue; // Try next proxy
          }
        }
        
        // If all proxies fail, throw error
        throw Exception('All CORS proxies failed for: $url');
      }
      
      // For non-web platforms, fetch directly
      final response = await _dio.get(
        fetchUrl,
        options: Options(
          headers: additionalHeaders,
          responseType: ResponseType.plain,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      throw Exception('Failed to fetch: ${e.message}');
    }
  }

  /// Check cache for existing result
  T? getFromCache(String url) {
    if (!config.useCache) return null;
    
    if (_cache.containsKey(url)) {
      final cached = _cache[url]!;
      if (DateTime.now().difference(cached.scrapedAt) < config.cacheDuration) {
        print('📦 [$name] Using cached content for $url');
        return cached;
      }
      _cache.remove(url);
    }
    return null;
  }

  /// Store result in cache
  void storeInCache(String url, T result) {
    if (config.useCache) {
      _cache[url] = result;
    }
  }

  /// Clear the cache
  void clearCache() {
    _cache.clear();
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }

  /// Create a failed result - must be implemented by each scraper
  T createFailedResult(String url, String error);

  /// Retry logic wrapper
  Future<T> retryOnFailure(
    String url,
    Future<T> Function() operation,
  ) async {
    for (int attempt = 0; attempt < config.maxRetries; attempt++) {
      try {
        print('🌐 [$name] Scraping: $url (attempt ${attempt + 1}/${config.maxRetries})');
        return await operation();
      } catch (e) {
        if (attempt == config.maxRetries - 1) {
          print('❌ [$name] Failed to scrape $url after ${config.maxRetries} attempts: $e');
          return createFailedResult(url, e.toString());
        }
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    return createFailedResult(url, 'Max retries exceeded');
  }
}

/// Exception class for scraper errors
class ScraperException implements Exception {
  final String message;
  final String? url;
  final dynamic originalError;

  ScraperException(this.message, {this.url, this.originalError});

  @override
  String toString() {
    final urlPart = url != null ? ' (URL: $url)' : '';
    return 'ScraperException: $message$urlPart';
  }
}
