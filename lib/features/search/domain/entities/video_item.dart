/// Video item for search results
class VideoItem {
  final String thumbnail;
  final String url;
  final String title;
  final String description;
  final String domain;
  final String? duration;
  final DateTime? publishedDate;
  final int? views;

  VideoItem({
    required this.thumbnail,
    required this.url,
    required this.title,
    required this.description,
    required this.domain,
    this.duration,
    this.publishedDate,
    this.views,
  });

  /// Create from map for serialization
  factory VideoItem.fromMap(Map<String, dynamic> map) {
    return VideoItem(
      thumbnail: map['thumbnail'] ?? '',
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domain: map['domain'] ?? '',
      duration: map['duration'],
      publishedDate: map['publishedDate'] != null
          ? DateTime.parse(map['publishedDate'])
          : null,
      views: map['views'],
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'thumbnail': thumbnail,
      'url': url,
      'title': title,
      'description': description,
      'domain': domain,
      'duration': duration,
      'publishedDate': publishedDate?.toIso8601String(),
      'views': views,
    };
  }

  /// Get formatted duration (e.g., "5:30")
  String get formattedDuration {
    if (duration == null) return '';
    return duration!;
  }

  /// Get formatted view count (e.g., "1.2M views")
  String get formattedViews {
    if (views == null) return '';
    if (views! < 1000) return '$views views';
    if (views! < 1000000) return '${(views! / 1000).toStringAsFixed(1)}K views';
    return '${(views! / 1000000).toStringAsFixed(1)}M views';
  }

  /// Check if this is a valid embeddable video (has YouTube, Vimeo, etc.)
  bool get isEmbeddable {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('dailymotion.com');
  }

  /// Get embeddable URL for iframe
  String get embeddableUrl {
    if (url.contains('youtube.com/watch?v=')) {
      final videoId = Uri.parse(url).queryParameters['v'];
      return 'https://www.youtube.com/embed/$videoId';
    } else if (url.contains('youtu.be/')) {
      final videoId = url.split('youtu.be/').last.split('?').first;
      return 'https://www.youtube.com/embed/$videoId';
    } else if (url.contains('vimeo.com/')) {
      final videoId = url.split('vimeo.com/').last.split('?').first;
      return 'https://player.vimeo.com/video/$videoId';
    }
    return url;
  }
}
