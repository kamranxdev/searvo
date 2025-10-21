import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../../base/base_scraper.dart';
import '../../base/scraper_models.dart';

/// TikTok video scraper
/// Extracts video metadata, statistics, and engagement data
class TikTokScraper extends BaseScraper<TikTokScraperResult> {
  TikTokScraper({
    super.dio,
    super.config,
  });

  @override
  String get name => 'TikTok';

  @override
  List<String> get supportedDomains => [
        'tiktok.com',
        'www.tiktok.com',
        'vm.tiktok.com',
      ];

  @override
  Future<TikTokScraperResult> scrape(String url) async {
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

  Future<TikTokScraperResult> _performScrape(String url) async {
    try {
      // TikTok has anti-scraping measures, so we need to be careful
      // In production, you might want to use their API or a proxy service

      final response = await fetchWithTimeout(
        url,
        additionalHeaders: {
          'Referer': 'https://www.tiktok.com/',
          'sec-fetch-dest': 'document',
          'sec-fetch-mode': 'navigate',
          'sec-fetch-site': 'none',
        },
      );

      if (response.statusCode != 200) {
        return createFailedResult(url, 'HTTP ${response.statusCode}');
      }

      final document = html_parser.parse(response.data.toString());
      final html = response.data.toString();

      // Extract video ID from URL
      final videoId = _extractVideoId(url);

      // TikTok stores data in __UNIVERSAL_DATA_FOR_REHYDRATION__ script tag
      final videoData = _extractVideoData(html);

      if (videoData == null) {
        // Fallback to meta tags
        return _extractFromMetaTags(url, document, videoId);
      }

      return _extractFromJsonData(url, videoData, videoId);
    } catch (e, stackTrace) {
      print('❌ [$name] Error scraping $url: $e\n$stackTrace');
      return createFailedResult(url, e.toString());
    }
  }

  String? _extractVideoId(String url) {
    final uri = Uri.parse(url);
    
    // Handle short URLs (vm.tiktok.com)
    if (uri.host.contains('vm.tiktok.com')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }

    // Handle full URLs (www.tiktok.com/@user/video/123456789)
    final videoSegmentIndex = uri.pathSegments.indexOf('video');
    if (videoSegmentIndex != -1 && videoSegmentIndex + 1 < uri.pathSegments.length) {
      return uri.pathSegments[videoSegmentIndex + 1];
    }

    return null;
  }

  Map<String, dynamic>? _extractVideoData(String html) {
    try {
      // Look for the __UNIVERSAL_DATA_FOR_REHYDRATION__ script
      final scriptRegex = RegExp(
        r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">(.+?)</script>',
        dotAll: true,
      );
      final match = scriptRegex.firstMatch(html);

      if (match != null) {
        final jsonStr = match.group(1);
        if (jsonStr != null) {
          final data = json.decode(jsonStr);
          return data;
        }
      }

      // Alternative: Look for SIGI_STATE
      final sigiRegex = RegExp(
        r'<script id="SIGI_STATE" type="application/json">(.+?)</script>',
        dotAll: true,
      );
      final sigiMatch = sigiRegex.firstMatch(html);

      if (sigiMatch != null) {
        final jsonStr = sigiMatch.group(1);
        if (jsonStr != null) {
          return json.decode(jsonStr);
        }
      }
    } catch (e) {
      print('❌ Failed to parse TikTok JSON data: $e');
    }
    return null;
  }

  TikTokScraperResult _extractFromJsonData(
    String url,
    Map<String, dynamic> data,
    String? videoId,
  ) {
    try {
      // Navigate through the JSON structure
      // The actual structure may vary, this is a general approach
      Map<String, dynamic>? videoDetail;

      // Try different possible paths in the JSON
      if (data.containsKey('__DEFAULT_SCOPE__')) {
        final defaultScope = data['__DEFAULT_SCOPE__'];
        if (defaultScope is Map && defaultScope.containsKey('webapp.video-detail')) {
          videoDetail = defaultScope['webapp.video-detail'];
        }
      }

      if (data.containsKey('ItemModule') && videoId != null) {
        final itemModule = data['ItemModule'];
        if (itemModule is Map && itemModule.containsKey(videoId)) {
          videoDetail = itemModule[videoId];
        }
      }

      if (videoDetail == null) {
        return createFailedResult(url, 'Could not find video data in JSON');
      }

      final description = videoDetail['desc'] as String?;
      final stats = videoDetail['stats'] as Map<String, dynamic>?;
      final author = videoDetail['author'] as Map<String, dynamic>?;
      final music = videoDetail['music'] as Map<String, dynamic>?;
      final video = videoDetail['video'] as Map<String, dynamic>?;

      // Extract hashtags from description
      final hashtags = _extractHashtags(description);

      // Parse create time
      DateTime? createTime;
      if (videoDetail.containsKey('createTime')) {
        final timestamp = videoDetail['createTime'];
        if (timestamp is int) {
          createTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else if (timestamp is String) {
          createTime = DateTime.tryParse(timestamp);
        }
      }

      return TikTokScraperResult(
        url: url,
        success: true,
        videoId: videoId,
        description: description,
        username: author?['uniqueId'] as String?,
        userDisplayName: author?['nickname'] as String?,
        likeCount: stats?['diggCount'] as int?,
        commentCount: stats?['commentCount'] as int?,
        shareCount: stats?['shareCount'] as int?,
        viewCount: stats?['playCount'] as int?,
        musicName: music?['title'] as String?,
        musicAuthor: music?['authorName'] as String?,
        hashtags: hashtags,
        videoUrl: video?['downloadAddr'] as String?,
        thumbnailUrl: video?['cover'] as String?,
        createTime: createTime,
        metadata: {
          'scraper': name,
          'dataSource': 'json',
        },
      );
    } catch (e) {
      print('❌ Error parsing TikTok JSON: $e');
      return createFailedResult(url, 'Failed to parse video data: $e');
    }
  }

  TikTokScraperResult _extractFromMetaTags(
    String url,
    dom.Document document,
    String? videoId,
  ) {
    final title = document
        .querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    final description = document
        .querySelector('meta[property="og:description"]')
        ?.attributes['content'];
    final imageUrl = document
        .querySelector('meta[property="og:image"]')
        ?.attributes['content'];
    final videoUrl = document
        .querySelector('meta[property="og:video"]')
        ?.attributes['content'];

    // Extract username from title or description
    String? username;
    if (title != null) {
      final match = RegExp(r'@(\w+)').firstMatch(title);
      username = match?.group(1);
    }

    final hashtags = _extractHashtags(description);

    return TikTokScraperResult(
      url: url,
      success: true,
      videoId: videoId,
      description: description,
      username: username,
      hashtags: hashtags,
      videoUrl: videoUrl,
      thumbnailUrl: imageUrl,
      metadata: {
        'scraper': name,
        'dataSource': 'meta-tags',
        'note': 'Limited data available from meta tags',
      },
    );
  }

  List<String>? _extractHashtags(String? text) {
    if (text == null || text.isEmpty) return null;

    final hashtags = <String>[];
    final regex = RegExp(r'#(\w+)');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final hashtag = match.group(1);
      if (hashtag != null) {
        hashtags.add(hashtag);
      }
    }

    return hashtags.isNotEmpty ? hashtags : null;
  }

  @override
  TikTokScraperResult createFailedResult(String url, String error) {
    return TikTokScraperResult(
      url: url,
      success: false,
      errorMessage: error,
    );
  }
}
