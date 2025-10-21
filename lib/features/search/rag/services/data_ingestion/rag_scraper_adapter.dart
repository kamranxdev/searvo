import 'dart:async';
import 'package:searvo/features/search/scrapers/scraper_manager.dart';
import 'package:searvo/features/search/scrapers/base/scraper_models.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';

/// Adapter service that bridges ScraperManager with RAG system
/// Converts ScraperResult to RAG Document format
class RAGScraperAdapter {
  final ScraperManager _scraperManager;
  final Map<String, Document> _cache = {};
  final Duration _cacheDuration;

  RAGScraperAdapter({
    ScraperManager? scraperManager,
    Duration cacheDuration = const Duration(hours: 1),
  })  : _scraperManager = scraperManager ?? ScraperManager(),
        _cacheDuration = cacheDuration;

  /// Scrape a single URL and convert to RAG Document
  Future<Document> scrape(
    String url, {
    double relevanceScore = 1.0,
    bool useCache = true,
  }) async {
    // Check cache
    if (useCache && _cache.containsKey(url)) {
      final cached = _cache[url]!;
      final age = DateTime.now().difference(cached.publishedDate ?? DateTime.now());
      if (age < _cacheDuration) {
        print('📦 Using cached RAG document for $url');
        return cached;
      }
    }

    final result = await _scraperManager.scrape(url);
    final document = _convertToDocument(result, relevanceScore);

    if (useCache) _cache[url] = document;

    return document;
  }

  /// Scrape multiple URLs and convert to RAG Documents
  Future<List<Document>> scrapeMultiple(
    List<String> urls, {
    double relevanceScore = 1.0,
    void Function(int completed, int total)? onProgress,
  }) async {
    print('🌐 RAG Scraping ${urls.length} URLs...');

    final results = await _scraperManager.scrapeMultiple(
      urls,
      onProgress: onProgress,
    );

    final documents = results.map((result) {
      return _convertToDocument(result, relevanceScore);
    }).toList();

    // Cache successful results
    for (int i = 0; i < urls.length; i++) {
      if (results[i].success) {
        _cache[urls[i]] = documents[i];
      }
    }

    final successful = documents.where((d) => d.metadata['scraped'] == true).length;
    print('✅ Successfully converted $successful/${urls.length} URLs to RAG documents');

    return documents;
  }

  /// Convert ScraperResult to RAG Document
  Document _convertToDocument(ScraperResult result, double relevanceScore) {
    if (!result.success) {
      // Return empty document for failed scrapes
      return Document(
        id: result.url.hashCode.toString(),
        title: 'Failed to scrape',
        url: result.url,
        content: '',
        snippet: result.errorMessage ?? 'Unknown error',
        source: Uri.parse(result.url).host,
        relevanceScore: 0.0,
        metadata: {
          'scraped': false,
          'error': result.errorMessage,
        },
      );
    }

    // Handle different scraper result types
    if (result is GenericScraperResult) {
      return _convertGenericResult(result, relevanceScore);
    } else if (result is YouTubeScraperResult) {
      return _convertYouTubeResult(result, relevanceScore);
    } else if (result is TikTokScraperResult) {
      return _convertTikTokResult(result, relevanceScore);
    } else if (result is PlayStoreScraperResult) {
      return _convertPlayStoreResult(result, relevanceScore);
    } else if (result is ScholarScraperResult) {
      return _convertScholarResult(result, relevanceScore);
    }

    // Fallback for unknown types
    return Document(
      id: result.url.hashCode.toString(),
      title: 'Scraped content',
      url: result.url,
      content: result.getSummary(),
      snippet: result.getSummary(),
      source: Uri.parse(result.url).host,
      relevanceScore: relevanceScore,
      metadata: {
        'scraped': true,
        'scrapedAt': result.scrapedAt.toIso8601String(),
      },
    );
  }

  /// Convert GenericScraperResult to Document
  Document _convertGenericResult(GenericScraperResult result, double relevanceScore) {
    return Document(
      id: result.url.hashCode.toString(),
      title: result.title,
      url: result.url,
      content: result.text,
      snippet: result.description ??
          (result.text.length > 300 ? '${result.text.substring(0, 300)}...' : result.text),
      publishedDate: result.publishedDate,
      source: Uri.parse(result.url).host,
      relevanceScore: relevanceScore,
      images: result.images,
      relatedLinks: result.links,
      author: result.author,
      language: result.language,
      readabilityScore: result.readabilityScore,
      metadata: {
        'scraped': true,
        'scraperType': 'generic',
        'wordCount': result.wordCount,
        'characterCount': result.characterCount,
        'author': result.author,
        'language': result.language,
        'imageCount': result.images.length,
        'linkCount': result.links.length,
        'readabilityScore': result.readabilityScore.toStringAsFixed(1),
        'scrapedAt': result.scrapedAt.toIso8601String(),
        'publishedDate': result.publishedDate?.toIso8601String(),
      },
    );
  }

  /// Convert YouTubeScraperResult to Document
  Document _convertYouTubeResult(YouTubeScraperResult result, double relevanceScore) {
    final content = StringBuffer();
    content.writeln('Title: ${result.title}');
    content.writeln('Channel: ${result.channelName}');
    if (result.description != null) content.writeln('\nDescription:\n${result.description}');
    if (result.transcript != null) content.writeln('\nTranscript:\n${result.transcript}');

    return Document(
      id: result.url.hashCode.toString(),
      title: result.title ?? 'YouTube Video',
      url: result.url,
      content: content.toString(),
      snippet: result.description ?? '',
      publishedDate: result.publishedAt,
      source: 'YouTube',
      relevanceScore: relevanceScore,
      images: result.thumbnailUrl != null ? [result.thumbnailUrl!] : [],
      metadata: {
        'scraped': true,
        'scraperType': 'youtube',
        'videoId': result.videoId,
        'channelName': result.channelName,
        'channelId': result.channelId,
        'viewCount': result.viewCount,
        'likeCount': result.likeCount,
        'duration': result.duration,
        'tags': result.tags,
        'hasTranscript': result.transcript != null,
        'commentCount': result.comments?.length ?? 0,
        'scrapedAt': result.scrapedAt.toIso8601String(),
      },
    );
  }

  /// Convert TikTokScraperResult to Document
  Document _convertTikTokResult(TikTokScraperResult result, double relevanceScore) {
    final content = StringBuffer();
    content.writeln('Creator: ${result.userDisplayName ?? result.username}');
    if (result.description != null) content.writeln('\nDescription:\n${result.description}');
    if (result.musicName != null) content.writeln('\nMusic: ${result.musicName} - ${result.musicAuthor}');
    if (result.hashtags != null && result.hashtags!.isNotEmpty) {
      content.writeln('\nHashtags: ${result.hashtags!.join(", ")}');
    }

    return Document(
      id: result.url.hashCode.toString(),
      title: result.description ?? 'TikTok Video',
      url: result.url,
      content: content.toString(),
      snippet: result.description ?? '',
      publishedDate: result.createTime,
      source: 'TikTok',
      relevanceScore: relevanceScore,
      images: result.thumbnailUrl != null ? [result.thumbnailUrl!] : [],
      metadata: {
        'scraped': true,
        'scraperType': 'tiktok',
        'videoId': result.videoId,
        'username': result.username,
        'likeCount': result.likeCount,
        'commentCount': result.commentCount,
        'shareCount': result.shareCount,
        'viewCount': result.viewCount,
        'hashtags': result.hashtags,
        'scrapedAt': result.scrapedAt.toIso8601String(),
      },
    );
  }

  /// Convert PlayStoreScraperResult to Document
  Document _convertPlayStoreResult(PlayStoreScraperResult result, double relevanceScore) {
    final content = StringBuffer();
    content.writeln('App: ${result.appName}');
    content.writeln('Developer: ${result.developer}');
    if (result.rating != null) content.writeln('Rating: ${result.rating}⭐ (${result.ratingsCount} ratings)');
    if (result.category != null) content.writeln('Category: ${result.category}');
    if (result.description != null) content.writeln('\nDescription:\n${result.description}');

    return Document(
      id: result.url.hashCode.toString(),
      title: result.appName ?? 'Play Store App',
      url: result.url,
      content: content.toString(),
      snippet: result.shortDescription ?? result.description ?? '',
      source: 'Google Play Store',
      relevanceScore: relevanceScore,
      images: [
        if (result.iconUrl != null) result.iconUrl!,
        ...?result.screenshotUrls,
      ],
      metadata: {
        'scraped': true,
        'scraperType': 'playstore',
        'appId': result.appId,
        'developer': result.developer,
        'rating': result.rating,
        'ratingsCount': result.ratingsCount,
        'downloadCount': result.downloadCount,
        'category': result.category,
        'price': result.price,
        'version': result.version,
        'size': result.size,
        'containsAds': result.containsAds,
        'contentRating': result.contentRating,
        'scrapedAt': result.scrapedAt.toIso8601String(),
      },
    );
  }

  /// Convert ScholarScraperResult to Document
  Document _convertScholarResult(ScholarScraperResult result, double relevanceScore) {
    final content = StringBuffer();
    content.writeln('Title: ${result.title}');
    if (result.authors != null && result.authors!.isNotEmpty) {
      content.writeln('Authors: ${result.authors!.join(", ")}');
    }
    if (result.journal != null) content.writeln('Journal: ${result.journal}');
    if (result.year != null) content.writeln('Year: ${result.year}');
    if (result.doi != null) content.writeln('DOI: ${result.doi}');
    if (result.citationCount != null) content.writeln('Citations: ${result.citationCount}');
    if (result.abstract != null) content.writeln('\nAbstract:\n${result.abstract}');
    if (result.keywords != null && result.keywords!.isNotEmpty) {
      content.writeln('\nKeywords: ${result.keywords!.join(", ")}');
    }

    return Document(
      id: result.url.hashCode.toString(),
      title: result.title ?? 'Academic Paper',
      url: result.url,
      content: content.toString(),
      snippet: result.abstract ?? '',
      publishedDate: result.publishedDate,
      source: result.journal ?? result.venue ?? 'Academic Source',
      relevanceScore: relevanceScore,
      author: result.authors?.join(', '),
      metadata: {
        'scraped': true,
        'scraperType': 'scholar',
        'authors': result.authors,
        'journal': result.journal,
        'doi': result.doi,
        'citationCount': result.citationCount,
        'keywords': result.keywords,
        'pdfUrl': result.pdfUrl,
        'venue': result.venue,
        'year': result.year,
        'scrapedAt': result.scrapedAt.toIso8601String(),
        ...?result.metadata,
      },
    );
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _scraperManager.clearAllCaches();
  }

  void dispose() {
    _cache.clear();
    _scraperManager.dispose();
  }
}
