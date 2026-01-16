/// Source item for search results
class SourceItem {
  final String thumbnail;
  final String? favicon;
  final String url;
  final String title;
  final String description;
  final String domain;
  final DateTime? publishedDate;
  final String? source;

  SourceItem({
    required this.thumbnail,
    this.favicon,
    required this.url,
    required this.title,
    required this.description,
    required this.domain,
    this.publishedDate,
    this.source,
  });

  /// Create from map for serialization
  factory SourceItem.fromMap(Map<String, dynamic> map) {
    return SourceItem(
      thumbnail: map['thumbnail'] ?? '',
      favicon: map['favicon'],
      url: map['url'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      domain: map['domain'] ?? '',
      publishedDate: map['publishedDate'] != null
          ? DateTime.parse(map['publishedDate'])
          : null,
      source: map['source'],
    );
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'thumbnail': thumbnail,
      'favicon': favicon,
      'url': url,
      'title': title,
      'description': description,
      'domain': domain,
      'publishedDate': publishedDate?.toIso8601String(),
      'source': source,
    };
  }
}
