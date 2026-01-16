import '../../../domain/entities/source_item.dart';

/// Enhanced document model for RAG system
class RagDocument {
  final String id;
  final String title;
  final String url;
  final String content;
  final String snippet;
  final String? thumbnail;
  final DateTime? publishedDate;
  final String source;
  final double relevanceScore;
  final Map<String, dynamic> metadata;

  // Rich metadata fields
  final List<String> images;
  final List<String> relatedLinks;
  final String? author;
  final String? language;
  final double? readabilityScore;

  const RagDocument({
    required this.id,
    required this.title,
    required this.url,
    required this.content,
    required this.snippet,
    this.thumbnail,
    this.publishedDate,
    this.source = 'unknown',
    this.relevanceScore = 0.0,
    this.metadata = const {},
    this.images = const [],
    this.relatedLinks = const [],
    this.author,
    this.language,
    this.readabilityScore,
  });

  /// Create from SearchResult with enhanced content
  factory RagDocument.fromSearchResult(
    SourceItem result, {
    String? fullContent,
  }) {
    return RagDocument(
      id: result.url.hashCode.toString(),
      title: result.title,
      url: result.url,
      content: fullContent ?? result.description,
      snippet: result.description,
      thumbnail: result.thumbnail,
      publishedDate: result.publishedDate,
      source: result.source ?? 'unknown',
      images: const [],
      relatedLinks: const [],
    );
  }

  /// Create a copy with updated relevance score
  RagDocument withRelevanceScore(double score) {
    return RagDocument(
      id: id,
      title: title,
      url: url,
      content: content,
      snippet: snippet,
      thumbnail: thumbnail,
      publishedDate: publishedDate,
      source: source,
      relevanceScore: score,
      metadata: metadata,
      images: images,
      relatedLinks: relatedLinks,
      author: author,
      language: language,
      readabilityScore: readabilityScore,
    );
  }

  /// Check if document contains query keywords
  bool containsKeywords(List<String> keywords) {
    final text = '${title.toLowerCase()} ${content.toLowerCase()}';
    return keywords.every((keyword) => text.contains(keyword.toLowerCase()));
  }

  /// Get domain from URL
  String get domain {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'unknown';
    }
  }

  /// Check if document has rich content (images/links)
  bool get hasRichContent => images.isNotEmpty || relatedLinks.isNotEmpty;

  /// Get content quality indicator
  String get contentQuality {
    if (readabilityScore == null) return 'unknown';
    if (readabilityScore! >= 70) return 'easy';
    if (readabilityScore! >= 50) return 'moderate';
    return 'difficult';
  }

  @override
  String toString() {
    return 'RagDocument(id: $id, title: $title, source: $source, score: ${relevanceScore.toStringAsFixed(2)}, '
        'images: ${images.length}, links: ${relatedLinks.length}${author != null ? ", author: $author" : ""})';
  }
}
