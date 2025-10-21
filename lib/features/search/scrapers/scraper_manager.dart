import 'dart:async';
import 'package:searvo/features/search/scrapers/base/base_scraper.dart';
import 'package:searvo/features/search/scrapers/base/scraper_models.dart';
import 'package:searvo/features/search/scrapers/sites/playstore/playstore_scraper.dart';
import 'package:searvo/features/search/scrapers/sites/tiktok/tiktok_scraper.dart';
import 'package:searvo/features/search/scrapers/sites/youtube/youtube_scraper.dart';
import 'package:searvo/features/search/scrapers/sites/scholar/scholar_scraper.dart';
import 'package:searvo/features/search/scrapers/sites/generic/generic_web_scraper.dart';

/// Central manager for all site-specific scrapers
/// Routes URLs to appropriate scrapers and manages scraping operations
class ScraperManager {
  final List<BaseScraper> _scrapers = [];
  final GenericWebScraper _genericScraper;
  final ScraperConfig _defaultConfig;

  static final ScraperManager _instance = ScraperManager._internal();
  factory ScraperManager({ScraperConfig? defaultConfig}) {
    if (defaultConfig != null) {
      return ScraperManager._withConfig(defaultConfig);
    }
    return _instance;
  }

  ScraperManager._internal({ScraperConfig? config})
      : _defaultConfig = config ?? const ScraperConfig(),
        _genericScraper = GenericWebScraper(config: config ?? const ScraperConfig()) {
    _initializeScrapers();
  }

  ScraperManager._withConfig(this._defaultConfig)
      : _genericScraper = GenericWebScraper(config: _defaultConfig) {
    _initializeScrapers();
  }

  void _initializeScrapers() {
    // Initialize all available scrapers
    _scrapers.addAll([
      YouTubeScraper(config: _defaultConfig),
      TikTokScraper(config: _defaultConfig),
      PlayStoreScraper(config: _defaultConfig),
      ScholarScraper(config: _defaultConfig),
    ]);

    print('✅ ScraperManager initialized with ${_scrapers.length} specialized scrapers + generic fallback');
  }

  /// Get appropriate scraper for a URL
  /// Returns specialized scraper if available, otherwise returns generic scraper
  BaseScraper getScraperForUrl(String url) {
    for (final scraper in _scrapers) {
      if (scraper.canHandle(url)) {
        return scraper;
      }
    }
    // Fallback to generic scraper for all HTTP(S) URLs
    return _genericScraper;
  }

  /// Scrape a single URL with the appropriate scraper
  Future<ScraperResult> scrape(String url) async {
    final scraper = getScraperForUrl(url);
    
    print('🔧 Using ${scraper.name} scraper for: $url');
    return await scraper.scrape(url);
  }

  /// Scrape multiple URLs with appropriate scrapers
  /// Groups URLs by scraper for efficient batch processing
  Future<List<ScraperResult>> scrapeMultiple(
    List<String> urls, {
    void Function(int completed, int total)? onProgress,
  }) async {
    print('🌐 Scraping ${urls.length} URLs...');

    // Group URLs by scraper
    final urlsByScraper = <BaseScraper, List<String>>{};

    for (final url in urls) {
      final scraper = getScraperForUrl(url);
      urlsByScraper.putIfAbsent(scraper, () => []).add(url);
    }

    // Scrape each group
    final results = <ScraperResult>[];
    int completedUrls = 0;

    for (final entry in urlsByScraper.entries) {
      final scraper = entry.key;
      final scraperUrls = entry.value;

      print('🔧 Processing ${scraperUrls.length} URLs with ${scraper.name} scraper');

      final scraperResults = await scraper.scrapeMultiple(
        scraperUrls,
        onProgress: (completed, total) {
          completedUrls += completed;
          onProgress?.call(completedUrls, urls.length);
        },
      );

      results.addAll(scraperResults);
    }

    print('✅ Completed scraping: ${results.length}/${urls.length} URLs');
    return results;
  }

  /// Scrape with type safety - for YouTube URLs
  Future<YouTubeScraperResult?> scrapeYouTube(String url) async {
    final result = await scrape(url);
    return result is YouTubeScraperResult ? result : null;
  }

  /// Scrape with type safety - for Scholar URLs
  Future<ScholarScraperResult?> scrapeScholar(String url) async {
    final result = await scrape(url);
    return result is ScholarScraperResult ? result : null;
  }

  /// Scrape with type safety - for TikTok URLs
  Future<TikTokScraperResult?> scrapeTikTok(String url) async {
    final result = await scrape(url);
    return result is TikTokScraperResult ? result : null;
  }

  /// Scrape with type safety - for Play Store URLs
  Future<PlayStoreScraperResult?> scrapePlayStore(String url) async {
    final result = await scrape(url);
    return result is PlayStoreScraperResult ? result : null;
  }

  /// Get list of all available scrapers
  List<String> getAvailableScrapers() {
    return [..._scrapers.map((s) => s.name), _genericScraper.name];
  }

  /// Get list of all supported domains
  List<String> getSupportedDomains() {
    final domains = <String>{};
    for (final scraper in _scrapers) {
      domains.addAll(scraper.supportedDomains);
    }
    return domains.toList()..sort();
  }

  /// Check if a URL is supported (always true now with generic fallback)
  bool isUrlSupported(String url) {
    return _genericScraper.canHandle(url); // Check if it's a valid HTTP(S) URL
  }

  /// Get scraper info for a URL
  Map<String, dynamic> getScraperInfo(String url) {
    final scraper = getScraperForUrl(url);

    return {
      'name': scraper.name,
      'supportedDomains': scraper.supportedDomains,
      'isGeneric': scraper == _genericScraper,
    };
  }

  /// Clear all caches
  void clearAllCaches() {
    for (final scraper in _scrapers) {
      scraper.clearCache();
    }
    _genericScraper.clearCache();
    print('🧹 All scraper caches cleared');
  }

  /// Dispose all scrapers
  void dispose() {
    for (final scraper in _scrapers) {
      scraper.dispose();
    }
    _genericScraper.dispose();
    _scrapers.clear();
  }
}

/// Extension methods for ScraperResult
extension ScraperResultExtensions on ScraperResult {
  /// Check if this is a specific type of result
  bool isYouTube() => this is YouTubeScraperResult;
  bool isScholar() => this is ScholarScraperResult;
  bool isTikTok() => this is TikTokScraperResult;
  bool isPlayStore() => this is PlayStoreScraperResult;
  bool isGeneric() => this is GenericScraperResult;

  /// Get type-safe cast helpers
  YouTubeScraperResult? asYouTube() =>
      this is YouTubeScraperResult ? this as YouTubeScraperResult : null;
  ScholarScraperResult? asScholar() =>
      this is ScholarScraperResult ? this as ScholarScraperResult : null;
  TikTokScraperResult? asTikTok() =>
      this is TikTokScraperResult ? this as TikTokScraperResult : null;
  PlayStoreScraperResult? asPlayStore() =>
      this is PlayStoreScraperResult ? this as PlayStoreScraperResult : null;
  GenericScraperResult? asGeneric() =>
      this is GenericScraperResult ? this as GenericScraperResult : null;
}
