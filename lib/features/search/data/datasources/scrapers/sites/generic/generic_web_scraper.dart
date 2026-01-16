import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../base/base_scraper.dart';
import '../../base/scraper_models.dart';

/// Generic web scraper for any website
/// Provides clean, structured content extraction similar to Perplexity AI
/// Used as fallback when no specialized scraper is available
class GenericWebScraper extends BaseScraper<GenericScraperResult> {
  GenericWebScraper({
    super.dio,
    super.config,
  });

  @override
  String get name => 'Generic Web';

  @override
  List<String> get supportedDomains => [];

  @override
  bool canHandle(String url) {
    // Generic scraper can handle any HTTP(S) URL
    final uri = Uri.tryParse(url);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Future<GenericScraperResult> scrape(String url) async {
    // Check cache
    final cached = getFromCache(url);
    if (cached != null) return cached;

    for (int attempt = 0; attempt < config.maxRetries; attempt++) {
      try {
        print('🌐 [$name] Scraping: $url (attempt ${attempt + 1}/${config.maxRetries})');

        final response = await fetchWithTimeout(url);

        if (response.statusCode == 200) {
          final result = await _extractContent(response, url);
          storeInCache(url, result);
          
          print('✅ [$name] Scraped ${result.text.length} chars (${result.wordCount} words) from $url');
          return result;
        } else if ((response.statusCode ?? 0) >= 500 && attempt < config.maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        } else {
          throw HttpException(response.statusCode ?? 0, 'HTTP ${response.statusCode ?? 0}');
        }
      } catch (e) {
        if (attempt == config.maxRetries - 1) {
          print('❌ [$name] Failed to scrape $url after ${config.maxRetries} attempts: $e');
          return GenericScraperResult.failed(url, e.toString());
        }
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }

    return GenericScraperResult.failed(url, 'Max retries exceeded');
  }

  @override
  GenericScraperResult createFailedResult(String url, String error) {
    return GenericScraperResult.failed(url, error);
  }

  /// Extract and clean content from HTML
  Future<GenericScraperResult> _extractContent(
    Response response,
    String url,
  ) async {
    try {
      // Get response body as string
      final String responseBody = response.data.toString();
      
      // Detect and handle charset (for debugging/logging purposes)
      final contentType = response.headers['content-type']?.toString();
      _detectCharset(contentType, responseBody);
      String decodedHtml = responseBody;
      
      // Dio automatically handles encoding, so we can use the response directly
      // If you need specific encoding handling, use ResponseType.bytes in the request

      // Parse HTML
      final document = html_parser.parse(decodedHtml);

      // Extract metadata first
      final title = _extractTitle(document);
      final description = _extractMetaDescription(document);
      final author = _extractMetaAuthor(document);
      final publishedDate = _extractPublishedDate(document);
      final lang = _extractLanguage(document);

      // Remove unwanted elements
      _removeUnwantedElements(document);

      // Find main content
      final mainContent = _findMainContent(document);

      // Extract images
      final images = config.includeImages ? _extractImages(mainContent, url) : <String>[];

      // Extract links
      final links = config.includeLinks ? _extractLinks(mainContent, url) : <String>[];

      // Extract clean text
      final text = _extractCleanText(mainContent);

      // Calculate readability metrics
      final readabilityScore = _calculateReadability(text);

      return GenericScraperResult(
        url: url,
        text: text,
        title: title,
        description: description,
        author: author,
        publishedDate: publishedDate,
        language: lang,
        images: images,
        links: links,
        success: true,
        wordCount: _countWords(text),
        characterCount: text.length,
        readabilityScore: readabilityScore,
      );
    } catch (e, stackTrace) {
      print('❌ [$name] Content extraction error: $e\n$stackTrace');
      return GenericScraperResult.failed(url, e.toString());
    }
  }

  /// Detect charset from content-type header or meta tag
  String? _detectCharset(String? contentType, String html) {
    if (contentType != null) {
      final charsetMatch = RegExp(r'charset=([^;]+)').firstMatch(contentType);
      if (charsetMatch != null) return charsetMatch.group(1);
    }

    final metaCharset = RegExp(
            r'<meta[^>]+charset=["' r"']?([^" r"'\s>]+)",
            caseSensitive: false)
        .firstMatch(html);
    if (metaCharset != null) return metaCharset.group(1);

    return null;
  }

  /// Extract title with fallbacks
  String _extractTitle(dom.Document document) {
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null) {
      final content = ogTitle.attributes['content'];
      if (content != null && content.isNotEmpty) return content.trim();
    }

    final titleElement = document.querySelector('title');
    if (titleElement != null && titleElement.text.isNotEmpty) {
      return titleElement.text.trim();
    }

    final h1 = document.querySelector('h1');
    if (h1 != null && h1.text.isNotEmpty) {
      return h1.text.trim();
    }

    return '';
  }

  /// Extract meta description
  String? _extractMetaDescription(dom.Document document) {
    final selectors = [
      'meta[name="description"]',
      'meta[property="og:description"]',
      'meta[name="twitter:description"]',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'];
        if (content != null && content.isNotEmpty) return content.trim();
      }
    }
    return null;
  }

  /// Extract author metadata
  String? _extractMetaAuthor(dom.Document document) {
    final selectors = [
      'meta[name="author"]',
      'meta[property="article:author"]',
      'meta[name="twitter:creator"]',
      'meta[property="author"]',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final content = element.attributes['content'];
        if (content != null && content.isNotEmpty) return content.trim();
      }
    }

    // Try structured data
    final jsonLd = document.querySelector('script[type="application/ld+json"]');
    if (jsonLd != null) {
      try {
        final data = json.decode(jsonLd.text);
        if (data is Map && data['author'] != null) {
          if (data['author'] is String) return data['author'];
          if (data['author'] is Map && data['author']['name'] != null) {
            return data['author']['name'];
          }
        }
      } catch (e) {
        // Invalid JSON
      }
    }

    return null;
  }

  /// Extract published date
  DateTime? _extractPublishedDate(dom.Document document) {
    final selectors = [
      'meta[property="article:published_time"]',
      'meta[name="publishdate"]',
      'meta[name="date"]',
      'time[datetime]',
      'time[pubdate]',
    ];

    for (final selector in selectors) {
      final element = document.querySelector(selector);
      if (element != null) {
        final dateStr =
            element.attributes['content'] ?? element.attributes['datetime'];
        if (dateStr != null) {
          try {
            return DateTime.parse(dateStr);
          } catch (e) {
            continue;
          }
        }
      }
    }
    return null;
  }

  /// Extract language
  String? _extractLanguage(dom.Document document) {
    final html = document.querySelector('html');
    return html?.attributes['lang'];
  }

  /// Remove unwanted elements
  void _removeUnwantedElements(dom.Document document) {
    final unwantedSelectors = [
      'script',
      'style',
      'noscript',
      'iframe',
      'svg',
      'nav',
      'header',
      'footer',
      'aside',
      '.advertisement',
      '.ad',
      '.social-share',
      '#comments',
      '.comments',
      '.related-posts',
      '[role="banner"]',
      '[role="navigation"]',
      '[role="complementary"]',
    ];

    for (final selector in unwantedSelectors) {
      document.querySelectorAll(selector).forEach((e) => e.remove());
    }
  }

  /// Find main content using readability algorithm
  dom.Element _findMainContent(dom.Document document) {
    final contentSelectors = [
      'article',
      'main',
      '[role="main"]',
      '.post-content',
      '.article-content',
      '.entry-content',
      '#content',
      '.content',
    ];

    for (final selector in contentSelectors) {
      final element = document.querySelector(selector);
      if (element != null && _getTextLength(element) > 200) {
        return element;
      }
    }

    // Fallback: find element with most text
    dom.Element? bestElement;
    int maxScore = 0;

    for (final element in document.querySelectorAll('div, section')) {
      final score = _calculateContentScore(element);
      if (score > maxScore) {
        maxScore = score;
        bestElement = element;
      }
    }

    return bestElement ?? document.body!;
  }

  /// Calculate content score
  int _calculateContentScore(dom.Element element) {
    int score = 0;

    final textLength = _getTextLength(element);
    score += textLength ~/ 10;

    score += element.querySelectorAll('p').length * 25;

    final links = element.querySelectorAll('a').length;
    final linkDensity = textLength > 0 ? links / (textLength / 100) : 0;
    if (linkDensity > 0.5) score -= 100;

    final className = element.className;
    if (className.contains('article') ||
        className.contains('post') ||
        className.contains('content') ||
        className.contains('entry')) {
      score += 50;
    }

    return score;
  }

  /// Get total text length of element
  int _getTextLength(dom.Element element) {
    return element.text.trim().length;
  }

  /// Extract images with proper URL resolution
  List<String> _extractImages(dom.Element element, String baseUrl) {
    final images = <String>[];

    for (final img in element.querySelectorAll('img')) {
      final src = img.attributes['src'] ?? img.attributes['data-src'];
      if (src != null && !src.startsWith('data:')) {
        final resolvedUrl = _resolveUrl(src, baseUrl);
        if (!images.contains(resolvedUrl)) {
          images.add(resolvedUrl);
        }
      }
    }

    return images;
  }

  /// Extract links with proper URL resolution
  List<String> _extractLinks(dom.Element element, String baseUrl) {
    final links = <String>[];

    for (final anchor in element.querySelectorAll('a')) {
      final href = anchor.attributes['href'];
      if (href != null && href.startsWith('http')) {
        if (!links.contains(href)) {
          links.add(href);
        }
      } else if (href != null) {
        final resolvedUrl = _resolveUrl(href, baseUrl);
        if (resolvedUrl.startsWith('http') && !links.contains(resolvedUrl)) {
          links.add(resolvedUrl);
        }
      }
    }

    return links;
  }

  /// Extract clean text from element
  String _extractCleanText(dom.Element element) {
    final buffer = StringBuffer();

    for (final node in element.nodes) {
      if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          buffer.write('$text ');
        }
      } else if (node is dom.Element) {
        final tag = node.localName;
        if (['p', 'div', 'br', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li']
            .contains(tag)) {
          buffer.write('${_extractCleanText(node)} ');
        } else {
          buffer.write(_extractCleanText(node));
        }
      }
    }

    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Count words in text
  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Calculate readability score (Flesch Reading Ease)
  double _calculateReadability(String text) {
    if (text.isEmpty) return 0.0;

    final words = _countWords(text);
    final sentences = text
        .split(RegExp(r'[.!?]+'))
        .where((s) => s.trim().isNotEmpty)
        .length;
    final syllables = _estimateSyllables(text);

    if (sentences == 0 || words == 0) return 0.0;

    final avgWordsPerSentence = words / sentences;
    final avgSyllablesPerWord = syllables / words;

    final score =
        206.835 - 1.015 * avgWordsPerSentence - 84.6 * avgSyllablesPerWord;

    return score.clamp(0.0, 100.0);
  }

  /// Estimate syllables in text
  int _estimateSyllables(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    int totalSyllables = 0;

    for (final word in words) {
      if (word.isEmpty) continue;

      int syllables = word
          .replaceAll(RegExp(r'[^aeiouy]'), '')
          .replaceAll(RegExp(r'([aeiouy])\1+'), r'$1')
          .length;

      if (word.endsWith('e')) syllables--;

      totalSyllables += syllables > 0 ? syllables : 1;
    }

    return totalSyllables;
  }

  /// Resolve relative URLs to absolute
  String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    try {
      final base = Uri.parse(baseUrl);

      if (url.startsWith('//')) {
        return '${base.scheme}:$url';
      } else if (url.startsWith('/')) {
        return '${base.scheme}://${base.host}$url';
      } else {
        final basePath = base.path.endsWith('/')
            ? base.path
            : base.path.substring(0, base.path.lastIndexOf('/') + 1);
        return '${base.scheme}://${base.host}$basePath$url';
      }
    } catch (e) {
      return url;
    }
  }
}

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException(this.statusCode, this.message);

  @override
  String toString() => message;
}
