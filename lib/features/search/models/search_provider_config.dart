import 'package:searvo/features/search/services/searxng_service.dart' show SearchType;

/// Configuration model for SearXNG
class SearchProviderConfig {
  final String name;
  final String baseUrl;
  final Map<String, String> headers;
  final int timeout;
  final bool enabled;
  
  const SearchProviderConfig({
    required this.name,
    required this.baseUrl,
    this.headers = const {},
    this.timeout = 30,
    this.enabled = true,
  });
  
  factory SearchProviderConfig.searxng({
    required String baseUrl,
    int timeout = 30,
    bool enabled = true,
  }) {
    return SearchProviderConfig(
      name: 'SearXNG',
      baseUrl: baseUrl,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'Searvo/1.0',
      },
      timeout: timeout,
      enabled: enabled,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'baseUrl': baseUrl,
      'headers': headers,
      'timeout': timeout,
      'enabled': enabled,
    };
  }
  
  factory SearchProviderConfig.fromMap(Map<String, dynamic> map) {
    return SearchProviderConfig(
      name: map['name'] ?? '',
      baseUrl: map['baseUrl'] ?? '',
      headers: Map<String, String>.from(map['headers'] ?? {}),
      timeout: map['timeout'] ?? 30,
      enabled: map['enabled'] ?? true,
    );
  }
  
  SearchProviderConfig copyWith({
    String? name,
    String? baseUrl,
    Map<String, String>? headers,
    int? timeout,
    bool? enabled,
  }) {
    return SearchProviderConfig(
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
      enabled: enabled ?? this.enabled,
    );
  }
  
  @override
  String toString() {
    return 'SearchProviderConfig(name: $name, baseUrl: $baseUrl, timeout: $timeout, enabled: $enabled)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SearchProviderConfig &&
      other.name == name &&
      other.baseUrl == baseUrl &&
      other.timeout == timeout &&
      other.enabled == enabled;
  }
  
  @override
  int get hashCode {
    return name.hashCode ^
      baseUrl.hashCode ^
      timeout.hashCode ^
      enabled.hashCode;
  }
}

/// Search result model for search providers
class SearchResult {
  final String title;
  final String url;
  final String snippet;
  final String? thumbnail;
  final DateTime? publishedDate;
  final String? source;
  
  // Image-specific fields
  final String? imgSrc;
  final String? thumbnailSrc;
  final String? resolution;
  final String? imgFormat;
  final int? filesize;
  
  // Video-specific fields
  final String? iframeSrc;
  final String? length;
  final String? author;
  final String? views;
  
  const SearchResult({
    required this.title,
    required this.url,
    required this.snippet,
    this.thumbnail,
    this.publishedDate,
    this.source,
    this.imgSrc,
    this.thumbnailSrc,
    this.resolution,
    this.imgFormat,
    this.filesize,
    this.iframeSrc,
    this.length,
    this.author,
    this.views,
  });
  
  factory SearchResult.fromSearXNG(Map<String, dynamic> json, {String category = 'general'}) {
    final url = json['url'] ?? '';
    final domain = _extractDomain(url);
    
    // For images, use img_src as the primary URL
    final String? imgSrc = json['img_src'];
    final String? thumbnailSrc = json['thumbnail_src'] ?? json['thumbnail'];
    
    // For videos, extract video-specific fields
    final String? iframeSrc = json['iframe_src'];
    final String? length = json['length']?.toString(); // Can be string or int
    final String? author = json['author']?.toString(); // Can be string or object
    // Handle views as both int and string
    final dynamic viewsRaw = json['views'];
    final String? views = viewsRaw != null ? viewsRaw.toString() : null;
    
    return SearchResult(
      title: json['title'] ?? '',
      url: url,
      snippet: json['content'] ?? '',
      thumbnail: thumbnailSrc ?? json['thumbnail'] ?? 'https://favicon.im/$domain?size=32',
      publishedDate: json['publishedDate'] != null 
          ? DateTime.tryParse(json['publishedDate']) 
          : null,
      source: json['engine'],
      imgSrc: imgSrc,
      thumbnailSrc: thumbnailSrc,
      resolution: json['resolution']?.toString(), // Can be string or object
      imgFormat: json['img_format']?.toString(),
      filesize: json['filesize'] is int ? json['filesize'] : null, // Ensure int
      iframeSrc: iframeSrc,
      length: length,
      author: author,
      views: views,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'snippet': snippet,
      'thumbnail': thumbnail,
      'publishedDate': publishedDate?.toIso8601String(),
      'source': source,
      'imgSrc': imgSrc,
      'thumbnailSrc': thumbnailSrc,
      'resolution': resolution,
      'imgFormat': imgFormat,
      'filesize': filesize,
      'iframeSrc': iframeSrc,
      'length': length,
      'author': author,
      'views': views,
    };
  }
  
  @override
  String toString() {
    return 'SearchResult(title: $title, url: $url, source: $source)';
  }
  
  /// Extract domain from URL for favicon generation
  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      // Fallback: try to extract domain manually
      final match = RegExp(r'https?://([^/]+)').firstMatch(url);
      return match?.group(1) ?? url;
    }
  }
}

/// Search response model containing results and metadata
class SearchResponse {
  final List<SearchResult> results;
  final int totalResults;
  final double searchTime;
  final String query;
  final Map<String, dynamic>? metadata;
  
  const SearchResponse({
    required this.results,
    required this.totalResults,
    required this.searchTime,
    required this.query,
    this.metadata,
  });
  
  factory SearchResponse.fromSearXNG(Map<String, dynamic> json, String query, {SearchType? searchType}) {
    final category = searchType?.toString().split('.').last ?? 'general';
    final results = (json['results'] as List? ?? [])
        .map((result) => SearchResult.fromSearXNG(result, category: category))
        .toList();
    
    return SearchResponse(
      results: results,
      totalResults: json['number_of_results'] ?? results.length,
      searchTime: (json['search_time'] ?? 0.0).toDouble(),
      query: query,
      metadata: {
        'suggestions': json['suggestions'] ?? [],
        'infobox': json['infobox'],
        'engines': json['engines'] ?? [],
        'unresponsive_engines': json['unresponsive_engines'] ?? [],
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'results': results.map((r) => r.toMap()).toList(),
      'totalResults': totalResults,
      'searchTime': searchTime,
      'query': query,
      'metadata': metadata,
    };
  }
  
  @override
  String toString() {
    return 'SearchResponse(query: $query, results: ${results.length}, time: ${searchTime}s)';
  }
}