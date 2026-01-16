import '../../domain/entities/source_item.dart';
import '../../domain/entities/search_enums.dart';

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
      headers: {'Accept': 'application/json', 'User-Agent': 'Searvo/1.0'},
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
}

/// Search result model for search providers
class SearchResultModel extends SourceItem {
  final String snippet;

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

  SearchResultModel({
    required String title,
    required String url,
    required this.snippet,
    String? thumbnail,
    DateTime? publishedDate,
    String? source,
    this.imgSrc,
    this.thumbnailSrc,
    this.resolution,
    this.imgFormat,
    this.filesize,
    this.iframeSrc,
    this.length,
    this.author,
    this.views,
  }) : super(
         title: title,
         url: url,
         description: snippet,
         thumbnail: thumbnail ?? '',
         publishedDate: publishedDate,
         source: source,
         domain: Uri.parse(url).host, // Helper to get domain
       );

  factory SearchResultModel.fromSearXNG(
    Map<String, dynamic> json, {
    String category = 'general',
  }) {
    final url = json['url'] ?? '';
    final domain = _extractDomain(url);

    final String? imgSrc = json['img_src'];
    final String? thumbnailSrc = json['thumbnail_src'] ?? json['thumbnail'];

    final String? iframeSrc = json['iframe_src'];
    final String? length = json['length']?.toString();
    final String? author = json['author']?.toString();
    final dynamic viewsRaw = json['views'];
    final String? views = viewsRaw != null ? viewsRaw.toString() : null;

    return SearchResultModel(
      title: json['title'] ?? '',
      url: url,
      snippet: json['content'] ?? '',
      thumbnail:
          thumbnailSrc ??
          json['thumbnail'] ??
          'https://favicon.im/$domain?size=32',
      publishedDate: json['publishedDate'] != null
          ? DateTime.tryParse(json['publishedDate'])
          : null,
      source: json['engine'],
      imgSrc: imgSrc,
      thumbnailSrc: thumbnailSrc,
      resolution: json['resolution']?.toString(),
      imgFormat: json['img_format']?.toString(),
      filesize: json['filesize'] is int ? json['filesize'] : null,
      iframeSrc: iframeSrc,
      length: length,
      author: author,
      views: views,
    );
  }

  static String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      final match = RegExp(r'https?://([^/]+)').firstMatch(url);
      return match?.group(1) ?? url;
    }
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
    return 'SearchResultModel(title: $title, url: $url, source: $source)';
  }
}

/// Search response model containing results and metadata
class SearchResponseModel {
  final List<SearchResultModel> results;
  final int totalResults;
  final double searchTime;
  final String query;
  final Map<String, dynamic>? metadata;

  const SearchResponseModel({
    required this.results,
    required this.totalResults,
    required this.searchTime,
    required this.query,
    this.metadata,
  });

  factory SearchResponseModel.fromSearXNG(
    Map<String, dynamic> json,
    String query, {
    SearchType? searchType,
  }) {
    final category = searchType?.toString().split('.').last ?? 'general';
    final results = (json['results'] as List? ?? [])
        .map(
          (result) => SearchResultModel.fromSearXNG(result, category: category),
        )
        .toList();

    return SearchResponseModel(
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
}
