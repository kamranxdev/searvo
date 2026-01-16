import '../../../domain/entities/video_item.dart';

/// Advanced media ranking service for images and videos using multiple relevance signals
/// Implements sophisticated scoring algorithms for Perplexity AI-quality results
/// Similar to DocumentRanker but optimized for visual media content
class MediaRanker {
  // Configurable ranking weights for images
  static const double _imageUrlWeight = 2.5;
  static const double _imageDomainAuthorityWeight = 2.0;
  static const double _imageFormatWeight = 1.0;
  static const double _imageExactMatchBonus = 3.0;
  static const double _imagePhraseMatchBonus = 2.0;

  // Configurable ranking weights for videos
  static const double _videoTitleWeight = 4.5;
  static const double _videoUrlWeight = 2.0;
  static const double _videoDescriptionWeight = 3.0;
  static const double _videoDomainAuthorityWeight = 2.5;
  static const double _videoViewsWeight = 1.8;
  static const double _videoFreshnessWeight = 2.0;
  static const double _videoExactMatchBonus = 3.5;
  static const double _videoPhraseMatchBonus = 2.5;

  /// Rank image URLs using advanced multi-signal relevance scoring
  List<String> rankImages(String query, List<String> imageUrls) {
    if (imageUrls.isEmpty) {
      print('⚠️  No images to rank');
      return [];
    }

    print('📸 Ranking ${imageUrls.length} images for query: "$query"');

    // Extract query features
    final keywords = _extractKeywords(query);
    final queryPhrases = _extractPhrases(query);

    print(
      '🔑 Extracted ${keywords.length} keywords and ${queryPhrases.length} phrases',
    );

    // Create scored image items
    final scoredImages = imageUrls.map((url) {
      final score = _calculateImageRelevanceScore(
        url,
        query,
        keywords,
        queryPhrases,
      );
      return _ScoredMediaItem(url: url, score: score, type: MediaType.image);
    }).toList();

    // Sort by relevance score (descending)
    scoredImages.sort((a, b) => b.score.compareTo(a.score));

    // Log top results
    print('✅ Image ranking complete. Top 3 results:');
    for (int i = 0; i < scoredImages.take(3).length; i++) {
      final item = scoredImages[i];
      print(
        '   ${i + 1}. ${item.url} (score: ${item.score.toStringAsFixed(2)})',
      );
    }

    return scoredImages.map((item) => item.url).toList();
  }

  /// Rank video items using advanced multi-signal relevance scoring
  List<VideoItem> rankVideos(String query, List<VideoItem> videos) {
    if (videos.isEmpty) {
      print('⚠️  No videos to rank');
      return [];
    }

    print('🎥 Ranking ${videos.length} videos for query: "$query"');

    // Extract query features
    final keywords = _extractKeywords(query);
    final queryPhrases = _extractPhrases(query);

    print(
      '🔑 Extracted ${keywords.length} keywords and ${queryPhrases.length} phrases',
    );

    // Create scored video items
    final scoredVideos = videos.map((video) {
      final score = _calculateVideoRelevanceScore(
        video,
        query,
        keywords,
        queryPhrases,
      );
      return _ScoredVideoItem(video: video, score: score);
    }).toList();

    // Sort by relevance score (descending)
    scoredVideos.sort((a, b) => b.score.compareTo(a.score));

    // Log top results
    print('✅ Video ranking complete. Top 3 results:');
    for (int i = 0; i < scoredVideos.take(3).length; i++) {
      final item = scoredVideos[i];
      print(
        '   ${i + 1}. ${item.video.title} (score: ${item.score.toStringAsFixed(2)})',
      );
    }

    return scoredVideos.map((item) => item.video).toList();
  }

  /// Filter and rank images by relevance - removes irrelevant images entirely
  List<String> filterRelevantImages(
    String query,
    List<String> imageUrls, {
    double minRelevanceScore = 0.25,
    int maxImages = 8,
    bool ensureDiversity = true,
  }) {
    if (imageUrls.isEmpty) {
      print('⚠️  No images to filter');
      return [];
    }

    print(
      '🔍 Filtering ${imageUrls.length} images for relevance (query: "$query")',
    );
    print('   Min score threshold: $minRelevanceScore, Max images: $maxImages');

    // Extract query features
    final keywords = _extractKeywords(query);
    final queryPhrases = _extractPhrases(query);

    // Calculate relevance scores for all images
    final scoredImages = imageUrls.map((url) {
      final score = _calculateImageRelevanceScore(
        url,
        query,
        keywords,
        queryPhrases,
      );
      return _ScoredMediaItem(url: url, score: score, type: MediaType.image);
    }).toList();

    // First pass: filter by minimum relevance score (remove irrelevant images)
    final relevantImages = scoredImages
        .where((item) => item.score >= minRelevanceScore)
        .toList();

    print(
      '   After relevance filter: ${relevantImages.length}/${scoredImages.length} images passed (removed ${scoredImages.length - relevantImages.length} irrelevant)',
    );

    if (relevantImages.isEmpty) {
      print('⚠️  No images met relevance threshold - returning empty list');
      return [];
    }

    // Sort by relevance score (descending)
    relevantImages.sort((a, b) => b.score.compareTo(a.score));

    // Second pass: ensure diversity if enabled and we have too many
    var finalImages = relevantImages;
    if (ensureDiversity && relevantImages.length > maxImages) {
      finalImages = _ensureImageDiversity(relevantImages, maxImages);
      print('   After diversity filter: ${finalImages.length} images');
    }

    // Take top N images
    final result = finalImages.take(maxImages).toList();

    print(
      '✅ Final relevant images: ${result.length} (scores: ${result.map((i) => i.score.toStringAsFixed(2)).join(', ')})',
    );

    return result.map((item) => item.url).toList();
  }

  /// Filter and rank videos by relevance - removes irrelevant videos entirely
  List<VideoItem> filterRelevantVideos(
    String query,
    List<VideoItem> videos, {
    double minRelevanceScore = 0.30,
    int maxVideos = 6,
    bool ensureDiversity = true,
  }) {
    if (videos.isEmpty) {
      print('⚠️  No videos to filter');
      return [];
    }

    print(
      '🔍 Filtering ${videos.length} videos for relevance (query: "$query")',
    );
    print('   Min score threshold: $minRelevanceScore, Max videos: $maxVideos');

    // Extract query features
    final keywords = _extractKeywords(query);
    final queryPhrases = _extractPhrases(query);

    // Calculate relevance scores for all videos
    final scoredVideos = videos.map((video) {
      final score = _calculateVideoRelevanceScore(
        video,
        query,
        keywords,
        queryPhrases,
      );
      return _ScoredVideoItem(video: video, score: score);
    }).toList();

    // First pass: filter by minimum relevance score (remove irrelevant videos)
    final relevantVideos = scoredVideos
        .where((item) => item.score >= minRelevanceScore)
        .toList();

    print(
      '   After relevance filter: ${relevantVideos.length}/${scoredVideos.length} videos passed (removed ${scoredVideos.length - relevantVideos.length} irrelevant)',
    );

    if (relevantVideos.isEmpty) {
      print('⚠️  No videos met relevance threshold - returning empty list');
      return [];
    }

    // Sort by relevance score (descending)
    relevantVideos.sort((a, b) => b.score.compareTo(a.score));

    // Second pass: ensure diversity if enabled and we have too many
    var finalVideos = relevantVideos;
    if (ensureDiversity && relevantVideos.length > maxVideos) {
      finalVideos = _ensureVideoDiversity(relevantVideos, maxVideos);
      print('   After diversity filter: ${finalVideos.length} videos');
    }

    // Take top N videos
    final result = finalVideos.take(maxVideos).toList();

    print(
      '✅ Final relevant videos: ${result.length} (scores: ${result.map((v) => v.score.toStringAsFixed(2)).join(', ')})',
    );

    return result.map((item) => item.video).toList();
  }

  /// Extract meaningful keywords from query
  List<String> _extractKeywords(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+'));

    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
      'may',
      'might',
      'must',
      'can',
      'shall',
      'what',
      'how',
      'why',
      'when',
      'where',
      'who',
      'which',
      'whom',
      'whose',
      'that',
      'this',
      'these',
      'those',
      'there',
      'their',
      'them',
      'then',
      'than',
      'such',
      'some',
      'any',
      'many',
      'much',
      'more',
      'most',
      'very',
      'about',
      'into',
      'through',
      'during',
      'before',
      'after',
      'above',
      'below',
      'between',
      'under',
      'again',
      'further',
      'once',
      'here',
    };

    return words
        .where((word) {
          final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
          return cleaned.length > 2 && !stopWords.contains(cleaned);
        })
        .map((word) => word.replaceAll(RegExp(r'[^\w]'), ''))
        .toSet()
        .toList();
  }

  /// Extract meaningful phrases (2-3 word combinations)
  List<String> _extractPhrases(String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+'));
    final phrases = <String>[];

    // Extract 2-word phrases
    for (int i = 0; i < words.length - 1; i++) {
      final phrase = '${words[i]} ${words[i + 1]}';
      if (phrase.length > 6) {
        phrases.add(phrase);
      }
    }

    // Extract 3-word phrases
    for (int i = 0; i < words.length - 2; i++) {
      final phrase = '${words[i]} ${words[i + 1]} ${words[i + 2]}';
      if (phrase.length > 10) {
        phrases.add(phrase);
      }
    }

    return phrases;
  }

  /// Calculate advanced relevance score for images
  double _calculateImageRelevanceScore(
    String imageUrl,
    String originalQuery,
    List<String> keywords,
    List<String> queryPhrases,
  ) {
    if (keywords.isEmpty) return 0.0;

    final url = imageUrl.toLowerCase();
    final query = originalQuery.toLowerCase();

    double score = 0.0;

    // 1. Exact query match in URL (highest signal)
    if (url.contains(query)) {
      score += 10.0 * _imageExactMatchBonus;
    }

    // 2. Phrase matching in URL (strong signal)
    for (final phrase in queryPhrases) {
      if (url.contains(phrase)) {
        score += 5.0 * _imagePhraseMatchBonus;
      }
    }

    // 3. Individual keyword matching in URL with frequency
    for (final keyword in keywords) {
      final count = _countOccurrences(url, keyword);
      if (count > 0) {
        score += count * _imageUrlWeight;
      }
    }

    // 4. Domain authority score
    final domain = _extractDomain(imageUrl);
    final domainScore = _calculateDomainAuthority(domain);
    score += domainScore * _imageDomainAuthorityWeight;

    // 5. Image format quality (preferred formats score higher)
    final formatScore = _calculateImageFormatScore(imageUrl);
    score += formatScore * _imageFormatWeight;

    // 6. URL structure analysis (semantic clues)
    score += _calculateImageUrlSemantics(imageUrl, keywords) * 2.0;

    // 7. Keyword density in URL path
    final pathDensity = _calculateKeywordDensityInPath(imageUrl, keywords);
    score += pathDensity * 1.5;

    return score;
  }

  /// Calculate advanced relevance score for videos
  double _calculateVideoRelevanceScore(
    VideoItem video,
    String originalQuery,
    List<String> keywords,
    List<String> queryPhrases,
  ) {
    if (keywords.isEmpty) return 0.0;

    final title = video.title.toLowerCase();
    final description = video.description.toLowerCase();
    final url = video.url.toLowerCase();
    final query = originalQuery.toLowerCase();

    double score = 0.0;

    // 1. Exact query match (highest signal)
    if (title.contains(query)) {
      score += 12.0 * _videoExactMatchBonus;
    }
    if (description.contains(query)) {
      score += 8.0 * _videoExactMatchBonus;
    }
    if (url.contains(query)) {
      score += 6.0 * _videoExactMatchBonus;
    }

    // 2. Phrase matching (strong signal)
    for (final phrase in queryPhrases) {
      if (title.contains(phrase)) {
        score += 6.0 * _videoPhraseMatchBonus;
      }
      if (description.contains(phrase)) {
        score += 4.0 * _videoPhraseMatchBonus;
      }
      if (url.contains(phrase)) {
        score += 3.0 * _videoPhraseMatchBonus;
      }
    }

    // 3. Individual keyword matching with frequency
    int titleMatches = 0;
    int descriptionMatches = 0;
    int urlMatches = 0;

    for (final keyword in keywords) {
      // Title matches (highest weight)
      final titleCount = _countOccurrences(title, keyword);
      if (titleCount > 0) {
        titleMatches += titleCount;
        score += titleCount * _videoTitleWeight;
      }

      // Description matches (medium weight)
      final descCount = _countOccurrences(description, keyword);
      if (descCount > 0) {
        descriptionMatches += descCount;
        score += descCount * _videoDescriptionWeight;
      }

      // URL matches (lower weight)
      final urlCount = _countOccurrences(url, keyword);
      if (urlCount > 0) {
        urlMatches += urlCount;
        score += urlCount * _videoUrlWeight;
      }
    }

    // 4. Coverage score (what percentage of query is matched)
    final totalMatches = titleMatches + descriptionMatches + urlMatches;
    final coverageRatio = totalMatches / keywords.length;
    score *= (1.0 + coverageRatio * 0.5);

    // 5. Domain authority score
    final domainScore = _calculateDomainAuthority(video.domain);
    score += domainScore * _videoDomainAuthorityWeight;

    // 6. Video quality signals
    score += _calculateVideoQualityScore(video) * 2.0;

    // 7. Freshness score (recency matters for videos)
    score += _calculateVideoFreshnessScore(video) * _videoFreshnessWeight;

    // 8. Engagement score (views as popularity indicator)
    score += _calculateVideoEngagementScore(video) * _videoViewsWeight;

    // 9. Author credibility (known channels score higher)
    if (video.domain.contains('youtube.com') &&
        video.views != null &&
        video.views! > 10000) {
      score += 2.0; // Popular YouTube videos
    }

    return score;
  }

  /// Count occurrences of a keyword in text
  int _countOccurrences(String text, String keyword) {
    if (text.isEmpty || keyword.isEmpty) return 0;

    int count = 0;
    int index = 0;

    while ((index = text.indexOf(keyword, index)) != -1) {
      count++;
      index += keyword.length;
    }

    return count;
  }

  /// Extract domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      return url;
    }
  }

  /// Calculate domain authority score
  double _calculateDomainAuthority(String domain) {
    // High-authority domains for media
    final highAuthority = [
      'youtube.com',
      'vimeo.com',
      'dailymotion.com',
      'twitch.tv',
      'tiktok.com',
      'instagram.com',
      'facebook.com',
      'twitter.com',
      'reddit.com',
      'imgur.com',
      'flickr.com',
      'unsplash.com',
      'pexels.com',
      'pixabay.com',
      'wikipedia.org',
      'wikimedia.org',
    ];

    // Medium-authority domains
    final mediumAuthority = [
      'youtu.be',
      'i.imgur.com',
      'staticflickr.com',
      'cdninstagram.com',
      'pinimg.com',
      'images.unsplash.com',
      'images.pexels.com',
      'i.redd.it',
      'media.giphy.com',
      'tenor.com',
    ];

    final domainLower = domain.toLowerCase();

    // Check high authority
    for (final auth in highAuthority) {
      if (domainLower.contains(auth)) {
        return 3.0;
      }
    }

    // Check medium authority
    for (final auth in mediumAuthority) {
      if (domainLower.contains(auth)) {
        return 2.0;
      }
    }

    // Check for .edu or .gov TLD
    if (domainLower.endsWith('.edu') || domainLower.endsWith('.gov')) {
      return 2.5;
    }

    // Check for .org TLD
    if (domainLower.endsWith('.org')) {
      return 2.0;
    }

    return 1.0; // Default score
  }

  /// Calculate image format quality score
  double _calculateImageFormatScore(String url) {
    final urlLower = url.toLowerCase();

    // Preferred modern formats
    if (urlLower.contains('.webp')) return 3.0;
    if (urlLower.contains('.avif')) return 3.0;
    if (urlLower.contains('.heic')) return 2.5;

    // Standard formats
    if (urlLower.contains('.jpg') || urlLower.contains('.jpeg')) return 2.0;
    if (urlLower.contains('.png')) return 2.0;

    // Legacy formats
    if (urlLower.contains('.gif')) return 1.5;
    if (urlLower.contains('.bmp')) return 1.0;
    if (urlLower.contains('.tiff') || urlLower.contains('.tif')) return 1.0;

    return 1.0; // Default
  }

  /// Calculate semantic relevance from URL structure
  double _calculateImageUrlSemantics(String url, List<String> keywords) {
    double score = 0.0;

    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      final filename = path.split('/').last;

      // Check if filename contains keywords (good signal)
      for (final keyword in keywords) {
        if (filename.contains(keyword)) {
          score += 2.0;
        }
      }

      // Check for semantic path segments
      final pathSegments = path.split('/').where((s) => s.isNotEmpty);
      for (final segment in pathSegments) {
        for (final keyword in keywords) {
          if (segment.contains(keyword)) {
            score += 1.0;
          }
        }
      }

      // Bonus for descriptive filenames
      if (filename.length > 10 && filename.contains('-')) {
        score += 0.5;
      }
    } catch (e) {
      // Invalid URL, no semantic score
    }

    return score;
  }

  /// Calculate keyword density in URL path
  double _calculateKeywordDensityInPath(String url, List<String> keywords) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();

      if (path.isEmpty) return 0.0;

      int keywordOccurrences = 0;
      for (final keyword in keywords) {
        keywordOccurrences += _countOccurrences(path, keyword);
      }

      final pathWords = path
          .split(RegExp(r'[^a-zA-Z0-9]+'))
          .where((w) => w.isNotEmpty)
          .length;
      if (pathWords == 0) return 0.0;

      return keywordOccurrences / pathWords;
    } catch (e) {
      return 0.0;
    }
  }

  /// Calculate video quality score based on metadata
  double _calculateVideoQualityScore(VideoItem video) {
    double quality = 0.0;

    // Has substantial title
    if (video.title.isNotEmpty && video.title.length > 10) quality += 2.0;

    // Has meaningful description
    if (video.description.isNotEmpty && video.description.length > 50)
      quality += 1.5;

    // Has duration (indicates complete video)
    if (video.duration != null && video.duration!.isNotEmpty) quality += 1.0;

    // Has view count (indicates engagement)
    if (video.views != null && video.views! > 0) quality += 1.0;

    // Has thumbnail
    if (video.thumbnail.isNotEmpty) quality += 0.5;

    return quality;
  }

  /// Calculate video freshness score
  double _calculateVideoFreshnessScore(VideoItem video) {
    if (video.publishedDate == null) return 0.5; // Neutral for undated content

    final now = DateTime.now();
    final daysSincePublished = now.difference(video.publishedDate!).inDays;

    if (daysSincePublished < 0) return 0.5; // Future date, treat as undated

    // Recency scoring with decay
    if (daysSincePublished <= 1) return 5.0; // Last day
    if (daysSincePublished <= 7) return 4.0; // Last week
    if (daysSincePublished <= 30) return 3.0; // Last month
    if (daysSincePublished <= 90) return 2.0; // Last quarter
    if (daysSincePublished <= 180) return 1.5; // Last 6 months
    if (daysSincePublished <= 365) return 1.0; // Last year
    if (daysSincePublished <= 730) return 0.5; // Last 2 years

    return 0.2; // Older content
  }

  /// Calculate video engagement score based on views
  double _calculateVideoEngagementScore(VideoItem video) {
    if (video.views == null || video.views! <= 0) return 0.0;

    final views = video.views!;

    // Logarithmic scaling for views (popular videos score higher but with diminishing returns)
    if (views >= 10000000) return 5.0; // 10M+ views
    if (views >= 1000000) return 4.0; // 1M+ views
    if (views >= 100000) return 3.0; // 100K+ views
    if (views >= 10000) return 2.0; // 10K+ views
    if (views >= 1000) return 1.0; // 1K+ views
    if (views >= 100) return 0.5; // 100+ views

    return 0.1; // Low engagement
  }

  /// Analyze ranking quality for debugging
  Map<String, dynamic> analyzeImageRankingQuality(List<String> images) {
    if (images.isEmpty) {
      return {'error': 'No images to analyze'};
    }

    final domains = images.map((url) => _extractDomain(url)).toSet();

    return {
      'totalImages': images.length,
      'uniqueDomains': domains.length,
      'domains': domains.toList(),
      'averageUrlLength':
          images.map((url) => url.length).reduce((a, b) => a + b) /
          images.length,
    };
  }

  /// Analyze ranking quality for videos
  Map<String, dynamic> analyzeVideoRankingQuality(List<VideoItem> videos) {
    if (videos.isEmpty) {
      return {'error': 'No videos to analyze'};
    }

    final domains = videos.map((v) => v.domain).toSet();
    final avgViews =
        videos.where((v) => v.views != null).map((v) => v.views!).isNotEmpty
        ? videos
                  .where((v) => v.views != null)
                  .map((v) => v.views!)
                  .reduce((a, b) => a + b) /
              videos.where((v) => v.views != null).length
        : 0.0;

    return {
      'totalVideos': videos.length,
      'uniqueDomains': domains.length,
      'domains': domains.toList(),
      'averageViews': avgViews,
      'videosWithDates': videos.where((v) => v.publishedDate != null).length,
      'videosWithViews': videos.where((v) => v.views != null).length,
    };
  }

  /// Ensure diversity in filtered image results
  List<_ScoredMediaItem> _ensureImageDiversity(
    List<_ScoredMediaItem> images,
    int maxImages,
  ) {
    if (images.length <= maxImages) return images;

    final selected = <_ScoredMediaItem>[];
    final selectedDomains = <String, int>{};

    for (final image in images) {
      final domain = _extractDomain(image.url);

      // Allow up to 2 images per domain to ensure diversity
      if (selectedDomains[domain] == null || selectedDomains[domain]! < 2) {
        selected.add(image);
        selectedDomains[domain] = (selectedDomains[domain] ?? 0) + 1;

        if (selected.length >= maxImages) break;
      }
    }

    return selected;
  }

  /// Ensure diversity in filtered video results
  List<_ScoredVideoItem> _ensureVideoDiversity(
    List<_ScoredVideoItem> videos,
    int maxVideos,
  ) {
    if (videos.length <= maxVideos) return videos;

    final selected = <_ScoredVideoItem>[];
    final selectedDomains = <String, int>{};

    for (final video in videos) {
      final domain = video.video.domain;

      // Allow up to 2 videos per domain to ensure diversity
      if (selectedDomains[domain] == null || selectedDomains[domain]! < 2) {
        selected.add(video);
        selectedDomains[domain] = (selectedDomains[domain] ?? 0) + 1;

        if (selected.length >= maxVideos) break;
      }
    }

    return selected;
  }
}

/// Internal helper classes for scoring
enum MediaType { image, video }

class _ScoredMediaItem {
  final String url;
  final double score;
  final MediaType type;

  _ScoredMediaItem({
    required this.url,
    required this.score,
    required this.type,
  });
}

class _ScoredVideoItem {
  final VideoItem video;
  final double score;

  _ScoredVideoItem({required this.video, required this.score});
}
