/// Image item for search results
class ImageItem {
  final String title;
  final String url;
  final String thumbnail;
  final String source;
  final String domain;
  final String? originalUrl; // High-res access
  final int? width;
  final int? height;

  ImageItem({
    required this.title,
    required this.url,
    required this.thumbnail,
    required this.source,
    required this.domain,
    this.originalUrl,
    this.width,
    this.height,
  });

  factory ImageItem.fromMap(Map<String, dynamic> map) {
    return ImageItem(
      title: map['title'] ?? '',
      url: map['url'] ?? '',
      thumbnail: map['thumbnail'] ?? '',
      source: map['source'] ?? '',
      domain: map['domain'] ?? '',
      originalUrl: map['originalUrl'],
      width: map['width'] != null
          ? int.tryParse(map['width'].toString())
          : null,
      height: map['height'] != null
          ? int.tryParse(map['height'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'url': url,
      'thumbnail': thumbnail,
      'source': source,
      'domain': domain,
      'originalUrl': originalUrl,
      'width': width,
      'height': height,
    };
  }
}
