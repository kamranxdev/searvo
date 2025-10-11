import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:searvo/features/search/rag/models/rag_models.dart';

/// Web scraping service for extracting full content from URLs
/// Provides clean, structured content extraction similar to Perplexity AI
class WebScraperService {
  final http.Client _client;
  final int _timeout;
  final int _maxRetries;
  final Map<String, ScrapedContent> _cache = {};
  final Duration _cacheDuration;
  
  WebScraperService({
    http.Client? client,
    int timeout = 30,
    int maxRetries = 3,
    Duration cacheDuration = const Duration(hours: 1),
  })  : _client = client ?? http.Client(),
        _timeout = timeout,
        _maxRetries = maxRetries,
        _cacheDuration = cacheDuration;

  /// Scrape full content from a URL
  Future<ScrapedContent> scrape(
    String url, {
    bool includeImages = false,
    bool includeLinks = false,
    bool cleanHtml = true,
    bool useCache = true,
    Map<String, String>? customHeaders,
  }) async {
    // Check cache
    if (useCache && _cache.containsKey(url)) {
      final cached = _cache[url]!;
      if (DateTime.now().difference(cached.scrapedAt!) < _cacheDuration) {
        print('📦 Using cached content for $url');
        return cached;
      }
    }

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        print('🌐 Scraping: $url (attempt ${attempt + 1}/$_maxRetries)');
        
        final response = await _fetchWithTimeout(url, customHeaders);
        
        if (response.statusCode == 200) {
          final content = await _extractContent(
            response.body,
            url,
            response.headers['content-type'],
            includeImages: includeImages,
            includeLinks: includeLinks,
            cleanHtml: cleanHtml,
          );
          
          if (useCache) _cache[url] = content;
          
          print('✅ Scraped ${content.text.length} chars (${content.wordCount} words) from $url');
          return content;
        } else if (response.statusCode >= 500 && attempt < _maxRetries - 1) {
          await Future.delayed(Duration(seconds: attempt + 1));
          continue;
        } else {
          throw HttpException(response.statusCode, 'HTTP ${response.statusCode}');
        }
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          print('❌ Failed to scrape $url after $_maxRetries attempts: $e');
          return ScrapedContent.failed(url, e.toString());
        }
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    
    return ScrapedContent.failed(url, 'Max retries exceeded');
  }

  /// Scrape multiple URLs in parallel with rate limiting
  Future<List<ScrapedContent>> scrapeMultiple(
    List<String> urls, {
    bool includeImages = false,
    bool includeLinks = false,
    int maxConcurrent = 5,
    void Function(int completed, int total)? onProgress,
  }) async {
    print('🌐 Scraping ${urls.length} URLs (max concurrent: $maxConcurrent)');
    
    final results = <ScrapedContent>[];
    int completed = 0;
    
    for (int i = 0; i < urls.length; i += maxConcurrent) {
      final batch = urls.skip(i).take(maxConcurrent).toList();
      final batchResults = await Future.wait(
        batch.map((url) => scrape(
          url,
          includeImages: includeImages,
          includeLinks: includeLinks,
        )),
      );
      results.addAll(batchResults);
      completed += batch.length;
      onProgress?.call(completed, urls.length);
      
      if (i + maxConcurrent < urls.length) {
        await Future.delayed(Duration(milliseconds: 200));
      }
    }
    
    final successful = results.where((r) => r.success).length;
    print('✅ Successfully scraped $successful/${urls.length} URLs');
    
    return results;
  }

  /// Fetch URL with proper timeout and headers
  Future<http.Response> _fetchWithTimeout(
    String url,
    Map<String, String>? customHeaders,
  ) async {
    final uri = Uri.parse(url);
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      'Cache-Control': 'max-age=0',
      ...?customHeaders,
    };

    return await _client
        .get(uri, headers: headers)
        .timeout(Duration(seconds: _timeout));
  }

  /// Extract and clean content from HTML
  Future<ScrapedContent> _extractContent(
    String html,
    String url,
    String? contentType, {
    bool includeImages = false,
    bool includeLinks = false,
    bool cleanHtml = true,
  }) async {
    try {
      // Detect and handle charset
      final charset = _detectCharset(contentType, html);
      String decodedHtml = html;
      if (charset != null && charset.toLowerCase() != 'utf-8') {
        try {
          decodedHtml = utf8.decode(html.codeUnits);
        } catch (e) {
          // Fallback to original
        }
      }

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
      final images = includeImages ? _extractImages(mainContent, url) : <String>[];
      
      // Extract links
      final links = includeLinks ? _extractLinks(mainContent, url) : <String>[];
      
      // Extract clean text
      final text = _extractCleanText(mainContent);
      
      // Calculate readability metrics
      final readabilityScore = _calculateReadability(text);
      
      return ScrapedContent(
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
        scrapedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      print('❌ Content extraction error: $e\n$stackTrace');
      return ScrapedContent.failed(url, e.toString());
    }
  }

  /// Detect charset from content-type header or meta tag
  String? _detectCharset(String? contentType, String html) {
    if (contentType != null) {
      final charsetMatch = RegExp(r'charset=([^;]+)').firstMatch(contentType);
      if (charsetMatch != null) return charsetMatch.group(1);
    }
    
    final metaCharset = RegExp(r'<meta[^>]+charset=["' r"']?([^" r"'\s>]+)", caseSensitive: false)
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
        final dateStr = element.attributes['content'] ?? element.attributes['datetime'];
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
      'script', 'style', 'noscript', 'iframe', 'svg',
      'nav', 'header', 'footer', 'aside',
      '.advertisement', '.ad', '.social-share',
      '#comments', '.comments', '.related-posts',
      '[role="banner"]', '[role="navigation"]', '[role="complementary"]',
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
    if (className.contains('article') || className.contains('post') || 
        className.contains('content') || className.contains('entry')) {
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
        if (['p', 'div', 'br', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'li'].contains(tag)) {
          buffer.write('${_extractCleanText(node)} ');
        } else {
          buffer.write(_extractCleanText(node));
        }
      }
    }
    
    return buffer.toString()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Count words in text
  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  /// Calculate readability score (Flesch Reading Ease)
  double _calculateReadability(String text) {
    if (text.isEmpty) return 0.0;
    
    final words = _countWords(text);
    final sentences = text.split(RegExp(r'[.!?]+')).where((s) => s.trim().isNotEmpty).length;
    final syllables = _estimateSyllables(text);
    
    if (sentences == 0 || words == 0) return 0.0;
    
    final avgWordsPerSentence = words / sentences;
    final avgSyllablesPerWord = syllables / words;
    
    final score = 206.835 - 1.015 * avgWordsPerSentence - 84.6 * avgSyllablesPerWord;
    
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

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _client.close();
    _cache.clear();
  }
}

/// Result of web scraping operation
class ScrapedContent {
  final String url;
  final String text;
  final String title;
  final String? description;
  final String? author;
  final DateTime? publishedDate;
  final String? language;
  final List<String> images;
  final List<String> links;
  final bool success;
  final String? error;
  final int wordCount;
  final int characterCount;
  final double readabilityScore;
  final DateTime? scrapedAt;

  const ScrapedContent({
    required this.url,
    required this.text,
    required this.title,
    this.description,
    this.author,
    this.publishedDate,
    this.language,
    this.images = const [],
    this.links = const [],
    required this.success,
    this.error,
    this.wordCount = 0,
    this.characterCount = 0,
    this.readabilityScore = 0.0,
    this.scrapedAt,
  });

  factory ScrapedContent.failed(String url, String error) {
    return ScrapedContent(
      url: url,
      text: '',
      title: '',
      success: false,
      error: error,
      scrapedAt: DateTime.now(),
    );
  }

  /// Convert to Document with full scraped content
  Document toDocument(double relevanceScore) {
    return Document(
      id: url.hashCode.toString(),
      title: title,
      url: url,
      content: text,
      snippet: description ?? (text.length > 300 ? '${text.substring(0, 300)}...' : text),
      publishedDate: publishedDate,
      source: Uri.parse(url).host,
      relevanceScore: relevanceScore,
      // Rich metadata fields
      images: images,
      relatedLinks: links,
      author: author,
      language: language,
      readabilityScore: readabilityScore,
      metadata: {
        'scraped': true,
        'wordCount': wordCount,
        'characterCount': characterCount,
        'author': author,
        'language': language,
        'imageCount': images.length,
        'linkCount': links.length,
        'readabilityScore': readabilityScore.toStringAsFixed(1),
        'scrapedAt': scrapedAt?.toIso8601String(),
        'publishedDate': publishedDate?.toIso8601String(),
      },
    );
  }

  @override
  String toString() {
    return 'ScrapedContent(url: $url, success: $success, words: $wordCount, readability: ${readabilityScore.toStringAsFixed(1)})';
  }
}

class HttpException implements Exception {
  final int statusCode;
  final String message;
  
  HttpException(this.statusCode, this.message);
  
  @override
  String toString() => message;
}