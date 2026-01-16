/// Base models for the scraper system
/// Common data structures used across all scrapers

/// Base class for all scraped content
abstract class ScraperResult {
  final String url;
  final bool success;
  final String? errorMessage;
  final DateTime scrapedAt;
  final Map<String, dynamic>? metadata;

  ScraperResult({
    required this.url,
    required this.success,
    this.errorMessage,
    DateTime? scrapedAt,
    this.metadata,
  }) : scrapedAt = scrapedAt ?? DateTime.now();

  /// Convert to JSON
  Map<String, dynamic> toJson();

  /// Get a summary of the scraped content
  String getSummary();
}

/// YouTube video scraper result
class YouTubeScraperResult extends ScraperResult {
  final String? videoId;
  final String? title;
  final String? description;
  final String? channelName;
  final String? channelId;
  final int? viewCount;
  final int? likeCount;
  final String? duration;
  final DateTime? publishedAt;
  final List<String>? tags;
  final String? thumbnailUrl;
  final String? transcript;
  final List<YouTubeComment>? comments;

  YouTubeScraperResult({
    required super.url,
    required super.success,
    super.errorMessage,
    super.scrapedAt,
    super.metadata,
    this.videoId,
    this.title,
    this.description,
    this.channelName,
    this.channelId,
    this.viewCount,
    this.likeCount,
    this.duration,
    this.publishedAt,
    this.tags,
    this.thumbnailUrl,
    this.transcript,
    this.comments,
  });

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'success': success,
        'errorMessage': errorMessage,
        'scrapedAt': scrapedAt.toIso8601String(),
        'videoId': videoId,
        'title': title,
        'description': description,
        'channelName': channelName,
        'channelId': channelId,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'duration': duration,
        'publishedAt': publishedAt?.toIso8601String(),
        'tags': tags,
        'thumbnailUrl': thumbnailUrl,
        'transcript': transcript,
        'comments': comments?.map((c) => c.toJson()).toList(),
        'metadata': metadata,
      };

  @override
  String getSummary() {
    if (!success) return 'Failed to scrape: ${errorMessage ?? "Unknown error"}';
    return 'Video: $title by $channelName ($viewCount views)';
  }
}

class YouTubeComment {
  final String author;
  final String text;
  final int likeCount;
  final DateTime publishedAt;

  YouTubeComment({
    required this.author,
    required this.text,
    required this.likeCount,
    required this.publishedAt,
  });

  Map<String, dynamic> toJson() => {
        'author': author,
        'text': text,
        'likeCount': likeCount,
        'publishedAt': publishedAt.toIso8601String(),
      };
}

/// Scholar/Academic paper scraper result
class ScholarScraperResult extends ScraperResult {
  final String? title;
  final List<String>? authors;
  final String? abstract;
  final DateTime? publishedDate;
  final String? journal;
  final String? doi;
  final int? citationCount;
  final List<String>? keywords;
  final String? pdfUrl;
  final List<ScholarReference>? references;
  final String? venue;
  final int? year;

  ScholarScraperResult({
    required super.url,
    required super.success,
    super.errorMessage,
    super.scrapedAt,
    super.metadata,
    this.title,
    this.authors,
    this.abstract,
    this.publishedDate,
    this.journal,
    this.doi,
    this.citationCount,
    this.keywords,
    this.pdfUrl,
    this.references,
    this.venue,
    this.year,
  });

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'success': success,
        'errorMessage': errorMessage,
        'scrapedAt': scrapedAt.toIso8601String(),
        'title': title,
        'authors': authors,
        'abstract': abstract,
        'publishedDate': publishedDate?.toIso8601String(),
        'journal': journal,
        'doi': doi,
        'citationCount': citationCount,
        'keywords': keywords,
        'pdfUrl': pdfUrl,
        'references': references?.map((r) => r.toJson()).toList(),
        'venue': venue,
        'year': year,
        'metadata': metadata,
      };

  @override
  String getSummary() {
    if (!success) return 'Failed to scrape: ${errorMessage ?? "Unknown error"}';
    final authorsStr = authors?.take(3).join(', ') ?? 'Unknown';
    return 'Paper: $title by $authorsStr (${citationCount ?? 0} citations)';
  }
}

class ScholarReference {
  final String title;
  final String? doi;
  final List<String>? authors;

  ScholarReference({
    required this.title,
    this.doi,
    this.authors,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'doi': doi,
        'authors': authors,
      };
}

/// TikTok video scraper result
class TikTokScraperResult extends ScraperResult {
  final String? videoId;
  final String? description;
  final String? username;
  final String? userDisplayName;
  final int? likeCount;
  final int? commentCount;
  final int? shareCount;
  final int? viewCount;
  final String? musicName;
  final String? musicAuthor;
  final List<String>? hashtags;
  final String? videoUrl;
  final String? thumbnailUrl;
  final DateTime? createTime;

  TikTokScraperResult({
    required super.url,
    required super.success,
    super.errorMessage,
    super.scrapedAt,
    super.metadata,
    this.videoId,
    this.description,
    this.username,
    this.userDisplayName,
    this.likeCount,
    this.commentCount,
    this.shareCount,
    this.viewCount,
    this.musicName,
    this.musicAuthor,
    this.hashtags,
    this.videoUrl,
    this.thumbnailUrl,
    this.createTime,
  });

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'success': success,
        'errorMessage': errorMessage,
        'scrapedAt': scrapedAt.toIso8601String(),
        'videoId': videoId,
        'description': description,
        'username': username,
        'userDisplayName': userDisplayName,
        'likeCount': likeCount,
        'commentCount': commentCount,
        'shareCount': shareCount,
        'viewCount': viewCount,
        'musicName': musicName,
        'musicAuthor': musicAuthor,
        'hashtags': hashtags,
        'videoUrl': videoUrl,
        'thumbnailUrl': thumbnailUrl,
        'createTime': createTime?.toIso8601String(),
        'metadata': metadata,
      };

  @override
  String getSummary() {
    if (!success) return 'Failed to scrape: ${errorMessage ?? "Unknown error"}';
    return 'TikTok: @$username - ${description?.substring(0, 50) ?? "No description"} ($likeCount likes)';
  }
}

/// Play Store app scraper result
class PlayStoreScraperResult extends ScraperResult {
  final String? appId;
  final String? appName;
  final String? developer;
  final String? description;
  final String? shortDescription;
  final double? rating;
  final int? ratingsCount;
  final int? downloadCount;
  final String? category;
  final String? price;
  final String? iconUrl;
  final List<String>? screenshotUrls;
  final String? version;
  final DateTime? releaseDate;
  final String? size;
  final List<PlayStoreReview>? reviews;
  final bool? containsAds;
  final String? contentRating;

  PlayStoreScraperResult({
    required super.url,
    required super.success,
    super.errorMessage,
    super.scrapedAt,
    super.metadata,
    this.appId,
    this.appName,
    this.developer,
    this.description,
    this.shortDescription,
    this.rating,
    this.ratingsCount,
    this.downloadCount,
    this.category,
    this.price,
    this.iconUrl,
    this.screenshotUrls,
    this.version,
    this.releaseDate,
    this.size,
    this.reviews,
    this.containsAds,
    this.contentRating,
  });

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'success': success,
        'errorMessage': errorMessage,
        'scrapedAt': scrapedAt.toIso8601String(),
        'appId': appId,
        'appName': appName,
        'developer': developer,
        'description': description,
        'shortDescription': shortDescription,
        'rating': rating,
        'ratingsCount': ratingsCount,
        'downloadCount': downloadCount,
        'category': category,
        'price': price,
        'iconUrl': iconUrl,
        'screenshotUrls': screenshotUrls,
        'version': version,
        'releaseDate': releaseDate?.toIso8601String(),
        'size': size,
        'reviews': reviews?.map((r) => r.toJson()).toList(),
        'containsAds': containsAds,
        'contentRating': contentRating,
        'metadata': metadata,
      };

  @override
  String getSummary() {
    if (!success) return 'Failed to scrape: ${errorMessage ?? "Unknown error"}';
    return 'App: $appName by $developer (${rating ?? 0}⭐, $downloadCount downloads)';
  }
}

class PlayStoreReview {
  final String userName;
  final double rating;
  final String text;
  final DateTime date;
  final int? thumbsUpCount;

  PlayStoreReview({
    required this.userName,
    required this.rating,
    required this.text,
    required this.date,
    this.thumbsUpCount,
  });

  Map<String, dynamic> toJson() => {
        'userName': userName,
        'rating': rating,
        'text': text,
        'date': date.toIso8601String(),
        'thumbsUpCount': thumbsUpCount,
      };
}

/// Generic web scraper result for fallback scraping
class GenericScraperResult extends ScraperResult {
  final String text;
  final String title;
  final String? description;
  final String? author;
  final DateTime? publishedDate;
  final String? language;
  final List<String> images;
  final List<String> links;
  final int wordCount;
  final int characterCount;
  final double readabilityScore;

  GenericScraperResult({
    required super.url,
    required super.success,
    super.errorMessage,
    super.scrapedAt,
    super.metadata,
    required this.text,
    required this.title,
    this.description,
    this.author,
    this.publishedDate,
    this.language,
    this.images = const [],
    this.links = const [],
    this.wordCount = 0,
    this.characterCount = 0,
    this.readabilityScore = 0.0,
  });

  factory GenericScraperResult.failed(String url, String error) {
    return GenericScraperResult(
      url: url,
      text: '',
      title: '',
      success: false,
      errorMessage: error,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'url': url,
        'success': success,
        'errorMessage': errorMessage,
        'scrapedAt': scrapedAt.toIso8601String(),
        'text': text,
        'title': title,
        'description': description,
        'author': author,
        'publishedDate': publishedDate?.toIso8601String(),
        'language': language,
        'images': images,
        'links': links,
        'wordCount': wordCount,
        'characterCount': characterCount,
        'readabilityScore': readabilityScore,
        'metadata': metadata,
      };

  @override
  String getSummary() {
    if (!success) return 'Failed to scrape: ${errorMessage ?? "Unknown error"}';
    return 'Generic: $title ($wordCount words, ${images.length} images)';
  }
}

/// Scraper configuration
class ScraperConfig {
  final int timeout;
  final int maxRetries;
  final bool useCache;
  final Duration cacheDuration;
  final int maxConcurrent;
  final Map<String, String>? headers;
  final bool includeComments;
  final int maxComments;
  final bool includeImages;
  final bool includeLinks;
  
  // CORS proxy configuration for web platform
  final List<String> corsProxies;
  final bool useCorsProxy;

  const ScraperConfig({
    this.timeout = 30,
    this.maxRetries = 3,
    this.useCache = true,
    this.cacheDuration = const Duration(hours: 1),
    this.maxConcurrent = 5,
    this.headers,
    this.includeComments = false,
    this.maxComments = 10,
    this.includeImages = false,
    this.includeLinks = false,
    this.useCorsProxy = true,
    this.corsProxies = const [
      'https://api.allorigins.win/raw?url=',  // Free, reliable
      'https://corsproxy.io/?',                 // Fast alternative
    ],
  });
}
