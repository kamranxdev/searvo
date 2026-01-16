import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../../base/base_scraper.dart';
import '../../base/scraper_models.dart';

/// Play Store app scraper
/// Extracts app metadata, ratings, reviews, and statistics
class PlayStoreScraper extends BaseScraper<PlayStoreScraperResult> {
  PlayStoreScraper({
    super.dio,
    super.config,
  });

  @override
  String get name => 'PlayStore';

  @override
  List<String> get supportedDomains => [
        'play.google.com',
      ];

  @override
  Future<PlayStoreScraperResult> scrape(String url) async {
    // Check cache first
    final cached = getFromCache(url);
    if (cached != null) return cached;

    // Scrape with retry logic
    final result = await retryOnFailure(url, () async {
      return await _performScrape(url);
    });

    // Cache the result
    storeInCache(url, result);
    return result;
  }

  Future<PlayStoreScraperResult> _performScrape(String url) async {
    try {
      // Extract app ID from URL
      final appId = _extractAppId(url);
      if (appId == null) {
        return createFailedResult(url, 'Invalid Play Store URL');
      }

      final response = await fetchWithTimeout(
        url,
        additionalHeaders: {
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response.statusCode != 200) {
        return createFailedResult(url, 'HTTP ${response.statusCode}');
      }

      final document = html_parser.parse(response.data.toString());

      // Try to extract from structured data first
      final structuredData = _extractStructuredData(document);
      
      if (structuredData != null) {
        return _extractFromStructuredData(url, appId, structuredData, document);
      }

      // Fallback to HTML parsing
      return _extractFromHtml(url, appId, document);
    } catch (e, stackTrace) {
      print('❌ [$name] Error scraping $url: $e\n$stackTrace');
      return createFailedResult(url, e.toString());
    }
  }

  String? _extractAppId(String url) {
    final uri = Uri.parse(url);
    
    // Play Store URLs: play.google.com/store/apps/details?id=com.example.app
    if (uri.queryParameters.containsKey('id')) {
      return uri.queryParameters['id'];
    }

    return null;
  }

  Map<String, dynamic>? _extractStructuredData(dom.Document document) {
    try {
      final scripts = document.querySelectorAll('script[type="application/ld+json"]');
      
      for (final script in scripts) {
        final text = script.text;
        if (text.isNotEmpty) {
          try {
            final data = json.decode(text);
            if (data is Map && data['@type'] == 'SoftwareApplication') {
              return data as Map<String, dynamic>;
            }
          } catch (e) {
            // Try next script
            continue;
          }
        }
      }
    } catch (e) {
      print('❌ Failed to parse structured data: $e');
    }
    return null;
  }

  PlayStoreScraperResult _extractFromStructuredData(
    String url,
    String appId,
    Map<String, dynamic> data,
    dom.Document document,
  ) {
    try {
      final appName = data['name'] as String?;
      final description = data['description'] as String?;
      
      // Safely extract rating data
      final aggregateRating = data['aggregateRating'];
      double? rating;
      int? ratingsCount;
      
      if (aggregateRating != null && aggregateRating is Map) {
        rating = _parseRating(aggregateRating['ratingValue']);
        ratingsCount = _parseInt(aggregateRating['ratingCount']);
      }
      
      // Safely extract price
      String price = 'Free';
      final offers = data['offers'];
      if (offers != null && offers is Map) {
        price = offers['price']?.toString() ?? 'Free';
      }
      
      final category = data['applicationCategory'] as String?;
      
      // Safely extract developer/author
      String? developer;
      final author = data['author'];
      if (author != null && author is Map) {
        developer = author['name'] as String?;
      }
      
      final contentRating = data['contentRating'] as String?;

      // Extract additional data from HTML
      final iconUrl = _extractIconUrl(document);
      final screenshots = _extractScreenshots(document);
      final version = _extractVersion(document);
      final size = _extractSize(document);
      final downloadCount = _extractDownloadCount(document);
      final releaseDate = _extractReleaseDate(document);
      final containsAds = _extractContainsAds(document);

      return PlayStoreScraperResult(
        url: url,
        success: true,
        appId: appId,
        appName: appName,
        developer: developer,
        description: description,
        rating: rating,
        ratingsCount: ratingsCount,
        downloadCount: downloadCount,
        category: category,
        price: price,
        iconUrl: iconUrl,
        screenshotUrls: screenshots,
        version: version,
        releaseDate: releaseDate,
        size: size,
        containsAds: containsAds,
        contentRating: contentRating,
        metadata: {
          'scraper': name,
          'dataSource': 'structured-data',
        },
      );
    } catch (e) {
      print('❌ Error parsing structured data: $e');
      return createFailedResult(url, 'Failed to parse app data: $e');
    }
  }

  PlayStoreScraperResult _extractFromHtml(
    String url,
    String appId,
    dom.Document document,
  ) {
    // Extract from meta tags and HTML structure
    final appName = _extractMetaContent(document, 'og:title');
    final description = _extractMetaContent(document, 'og:description');
    final iconUrl = _extractMetaContent(document, 'og:image');
    
    final developer = _extractDeveloper(document);
    final rating = _extractRatingFromHtml(document);
    final ratingsCount = _extractRatingsCountFromHtml(document);
    final category = _extractCategory(document);
    final screenshots = _extractScreenshots(document);
    final version = _extractVersion(document);
    final size = _extractSize(document);
    final downloadCount = _extractDownloadCount(document);
    final releaseDate = _extractReleaseDate(document);
    final containsAds = _extractContainsAds(document);
    final contentRating = _extractContentRating(document);
    final price = _extractPrice(document);

    return PlayStoreScraperResult(
      url: url,
      success: true,
      appId: appId,
      appName: appName,
      developer: developer,
      description: description,
      rating: rating,
      ratingsCount: ratingsCount,
      downloadCount: downloadCount,
      category: category,
      price: price,
      iconUrl: iconUrl,
      screenshotUrls: screenshots,
      version: version,
      releaseDate: releaseDate,
      size: size,
      containsAds: containsAds,
      contentRating: contentRating,
      metadata: {
        'scraper': name,
        'dataSource': 'html',
      },
    );
  }

  // Helper methods
  String? _extractMetaContent(dom.Document document, String property) {
    return document
        .querySelector('meta[property="$property"]')
        ?.attributes['content'];
  }

  String? _extractDeveloper(dom.Document document) {
    final developerLink = document.querySelector('a[href*="/store/apps/dev"]');
    return developerLink?.text.trim();
  }

  double? _extractRatingFromHtml(dom.Document document) {
    final ratingElement = document.querySelector('[itemprop="starRating"] [aria-label]');
    if (ratingElement != null) {
      final ariaLabel = ratingElement.attributes['aria-label'];
      if (ariaLabel != null) {
        final match = RegExp(r'(\d+\.?\d*)').firstMatch(ariaLabel);
        if (match != null) {
          return double.tryParse(match.group(1)!);
        }
      }
    }
    return null;
  }

  int? _extractRatingsCountFromHtml(dom.Document document) {
    final countElement = document.querySelector('[aria-label*="ratings"]');
    if (countElement != null) {
      final ariaLabel = countElement.attributes['aria-label'];
      if (ariaLabel != null) {
        final match = RegExp(r'([\d,]+)').firstMatch(ariaLabel);
        if (match != null) {
          return int.tryParse(match.group(1)!.replaceAll(',', ''));
        }
      }
    }
    return null;
  }

  String? _extractCategory(dom.Document document) {
    final categoryLink = document.querySelector('a[href*="/store/apps/category/"]');
    return categoryLink?.text.trim();
  }

  String? _extractIconUrl(dom.Document document) {
    final iconImg = document.querySelector('img[itemprop="image"]');
    return iconImg?.attributes['src'];
  }

  List<String>? _extractScreenshots(dom.Document document) {
    final screenshots = document
        .querySelectorAll('img[data-screenshot]')
        .map((img) => img.attributes['src'] ?? '')
        .where((src) => src.isNotEmpty)
        .toList();

    return screenshots.isNotEmpty ? screenshots : null;
  }

  String? _extractVersion(dom.Document document) {
    // Look for version in various places
    final versionElements = document.querySelectorAll('div');
    for (final element in versionElements) {
      final text = element.text;
      if (text.contains('Version')) {
        final match = RegExp(r'Version\s+([\d.]+)').firstMatch(text);
        if (match != null) {
          return match.group(1);
        }
      }
    }
    return null;
  }

  String? _extractSize(dom.Document document) {
    final divs = document.querySelectorAll('div');
    for (final div in divs) {
      final text = div.text;
      if (RegExp(r'\d+\.?\d*\s*(MB|GB|KB)').hasMatch(text)) {
        final match = RegExp(r'(\d+\.?\d*\s*(?:MB|GB|KB))').firstMatch(text);
        return match?.group(1);
      }
    }
    return null;
  }

  int? _extractDownloadCount(dom.Document document) {
    final divs = document.querySelectorAll('div');
    for (final div in divs) {
      final text = div.text;
      if (text.contains('downloads') || text.contains('installs')) {
        // Parse formats like "1M+", "100K+", "10,000+"
        final match = RegExp(r'([\d,]+\.?\d*[KMB]?)\+?').firstMatch(text);
        if (match != null) {
          return _parseDownloadCount(match.group(1)!);
        }
      }
    }
    return null;
  }

  int? _parseDownloadCount(String countStr) {
    countStr = countStr.replaceAll(',', '').toUpperCase();
    
    if (countStr.endsWith('B')) {
      return (double.parse(countStr.substring(0, countStr.length - 1)) * 1000000000).toInt();
    } else if (countStr.endsWith('M')) {
      return (double.parse(countStr.substring(0, countStr.length - 1)) * 1000000).toInt();
    } else if (countStr.endsWith('K')) {
      return (double.parse(countStr.substring(0, countStr.length - 1)) * 1000).toInt();
    }
    
    return int.tryParse(countStr);
  }

  DateTime? _extractReleaseDate(dom.Document document) {
    final divs = document.querySelectorAll('div');
    for (final div in divs) {
      final text = div.text;
      if (text.contains('Updated on') || text.contains('Released on')) {
        final match = RegExp(r'(\w+ \d+,? \d{4})').firstMatch(text);
        if (match != null) {
          return DateTime.tryParse(match.group(1)!);
        }
      }
    }
    return null;
  }

  bool? _extractContainsAds(dom.Document document) {
    final text = document.body?.text ?? '';
    return text.contains('Contains ads');
  }

  String? _extractContentRating(dom.Document document) {
    final divs = document.querySelectorAll('div');
    for (final div in divs) {
      final text = div.text;
      final match = RegExp(r'Rated for ([\w+\s]+)').firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  String? _extractPrice(dom.Document document) {
    final priceButton = document.querySelector('button[aria-label*="Install"]');
    if (priceButton != null) {
      return 'Free';
    }

    final buyButton = document.querySelector('button[aria-label*="Buy"]');
    if (buyButton != null) {
      final ariaLabel = buyButton.attributes['aria-label'];
      if (ariaLabel != null) {
        final match = RegExp(r'[\$€£¥]\d+\.?\d*').firstMatch(ariaLabel);
        return match?.group(0);
      }
    }

    return null;
  }

  double? _parseRating(dynamic rating) {
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating);
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Remove commas and parse
      return int.tryParse(value.replaceAll(',', ''));
    }
    return null;
  }

  @override
  PlayStoreScraperResult createFailedResult(String url, String error) {
    return PlayStoreScraperResult(
      url: url,
      success: false,
      errorMessage: error,
    );
  }
}
