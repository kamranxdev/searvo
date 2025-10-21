import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../../base/base_scraper.dart';
import '../../base/scraper_models.dart';

/// YouTube video scraper
/// Extracts video metadata, description, transcript, and comments
class YouTubeScraper extends BaseScraper<YouTubeScraperResult> {
  YouTubeScraper({
    super.dio,
    super.config,
  });

  @override
  String get name => 'YouTube';

  @override
  List<String> get supportedDomains => [
        'youtube.com',
        'www.youtube.com',
        'm.youtube.com',
        'youtu.be',
      ];

  @override
  Future<YouTubeScraperResult> scrape(String url) async {
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

  Future<YouTubeScraperResult> _performScrape(String url) async {
    try {
      // Extract video ID from URL
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        return createFailedResult(url, 'Invalid YouTube URL');
      }

      // Fetch the page
      final response = await fetchWithTimeout(url);
      if (response.statusCode != 200) {
        return createFailedResult(
          url,
          'HTTP ${response.statusCode}',
        );
      }

      // Parse HTML - Dio handles encoding automatically
      String htmlContent = response.data.toString();
      
      final document = html_parser.parse(htmlContent);

      // Extract metadata
      final title = _extractTitle(document);
      final description = _extractDescription(document);
      final channelInfo = _extractChannelInfo(document);
      final stats = _extractStats(document, htmlContent);
      final publishedDate = _extractPublishDate(document, htmlContent);
      final tags = _extractTags(document, htmlContent);
      final duration = _extractDuration(document, htmlContent);
      final thumbnailUrl = _extractThumbnail(videoId);

      // Optionally extract transcript
      String? transcript;
      if (config.includeComments) {
        // In a real implementation, you'd need YouTube API or transcript extraction
        // For now, we'll leave it as a placeholder
        transcript = await _extractTranscript(videoId);
      }

      return YouTubeScraperResult(
        url: url,
        success: true,
        videoId: videoId,
        title: title,
        description: description,
        channelName: channelInfo['name'],
        channelId: channelInfo['id'],
        viewCount: stats['views'],
        likeCount: stats['likes'],
        duration: duration,
        publishedAt: publishedDate,
        tags: tags,
        thumbnailUrl: thumbnailUrl,
        transcript: transcript,
        metadata: {
          'scraper': name,
          'scrapedFrom': 'html',
        },
      );
    } catch (e, stackTrace) {
      print('❌ [$name] Error scraping $url: $e\n$stackTrace');
      return createFailedResult(url, e.toString());
    }
  }

  String? _extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Handle youtu.be format
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    // Handle youtube.com format
    if (uri.queryParameters.containsKey('v')) {
      return uri.queryParameters['v'];
    }

    // Handle /embed/ or /v/ format
    if (uri.pathSegments.length >= 2) {
      if (uri.pathSegments[0] == 'embed' || uri.pathSegments[0] == 'v') {
        return uri.pathSegments[1];
      }
    }

    return null;
  }

  String? _extractTitle(dom.Document document) {
    // Try meta tags first
    final ogTitle = document.querySelector('meta[property="og:title"]');
    if (ogTitle != null) {
      return ogTitle.attributes['content']?.trim();
    }

    final titleTag = document.querySelector('title');
    if (titleTag != null) {
      return titleTag.text.replaceAll(' - YouTube', '').trim();
    }

    return null;
  }

  String? _extractDescription(dom.Document document) {
    final ogDescription =
        document.querySelector('meta[property="og:description"]');
    if (ogDescription != null) {
      return ogDescription.attributes['content']?.trim();
    }

    final metaDescription = document.querySelector('meta[name="description"]');
    if (metaDescription != null) {
      return metaDescription.attributes['content']?.trim();
    }

    return null;
  }

  Map<String, String?> _extractChannelInfo(dom.Document document) {
    final channelName = document
        .querySelector('link[itemprop="name"]')
        ?.attributes['content'];
    final channelUrl = document
        .querySelector('link[itemprop="url"]')
        ?.attributes['href'];

    String? channelId;
    if (channelUrl != null) {
      final uri = Uri.parse(channelUrl);
      channelId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    }

    return {
      'name': channelName,
      'id': channelId,
    };
  }

  Map<String, int?> _extractStats(dom.Document document, String html) {
    // YouTube stores data in JSON-LD and in the page source
    // This is a simplified version - in production, you'd parse the ytInitialData object

    int? views;
    int? likes;

    // Try to extract from meta tags
    final viewCountMeta =
        document.querySelector('meta[itemprop="interactionCount"]');
    if (viewCountMeta != null) {
      final content = viewCountMeta.attributes['content'];
      if (content != null) {
        views = int.tryParse(content);
      }
    }

    // In a real implementation, you'd parse ytInitialData from the page source
    // This is a placeholder for demonstration
    final viewRegex = RegExp(r'"viewCount":"(\d+)"');
    final viewMatch = viewRegex.firstMatch(html);
    if (viewMatch != null) {
      views = int.tryParse(viewMatch.group(1) ?? '');
    }

    final likeRegex = RegExp(r'"likeCount":"(\d+)"');
    final likeMatch = likeRegex.firstMatch(html);
    if (likeMatch != null) {
      likes = int.tryParse(likeMatch.group(1) ?? '');
    }

    return {
      'views': views,
      'likes': likes,
    };
  }

  DateTime? _extractPublishDate(dom.Document document, String html) {
    final datePublished =
        document.querySelector('meta[itemprop="datePublished"]');
    if (datePublished != null) {
      final content = datePublished.attributes['content'];
      if (content != null) {
        return DateTime.tryParse(content);
      }
    }

    final uploadDate = document.querySelector('meta[itemprop="uploadDate"]');
    if (uploadDate != null) {
      final content = uploadDate.attributes['content'];
      if (content != null) {
        return DateTime.tryParse(content);
      }
    }

    return null;
  }

  List<String>? _extractTags(dom.Document document, String html) {
    final keywords = document.querySelector('meta[name="keywords"]');
    if (keywords != null) {
      final content = keywords.attributes['content'];
      if (content != null && content.isNotEmpty) {
        return content.split(',').map((tag) => tag.trim()).toList();
      }
    }
    return null;
  }

  String? _extractDuration(dom.Document document, String html) {
    final durationMeta = document.querySelector('meta[itemprop="duration"]');
    if (durationMeta != null) {
      return durationMeta.attributes['content'];
    }
    return null;
  }

  String _extractThumbnail(String videoId) {
    // YouTube thumbnail URLs follow a consistent pattern
    return 'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg';
  }

  Future<String?> _extractTranscript(String videoId) async {
    // Transcript extraction requires additional API calls or parsing
    // This is a placeholder for the actual implementation
    // You would need to use YouTube's API or parse the transcript from the page
    return null;
  }

  @override
  YouTubeScraperResult createFailedResult(String url, String error) {
    return YouTubeScraperResult(
      url: url,
      success: false,
      errorMessage: error,
    );
  }
}
