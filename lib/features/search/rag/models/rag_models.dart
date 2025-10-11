

import 'package:searvo/features/search/models/search_provider_config.dart';

/// Enhanced document model for RAG system
class Document {
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

  const Document({
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
  factory Document.fromSearchResult(SearchResult result, {String? fullContent}) {
    return Document(
      id: result.url.hashCode.toString(),
      title: result.title,
      url: result.url,
      content: fullContent ?? result.snippet,
      snippet: result.snippet,
      thumbnail: result.thumbnail,
      publishedDate: result.publishedDate,
      source: result.source ?? 'unknown',
      images: const [],
      relatedLinks: const [],
    );
  }

  /// Create a copy with updated relevance score
  Document withRelevanceScore(double score) {
    return Document(
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
    return 'Document(id: $id, title: $title, source: $source, score: ${relevanceScore.toStringAsFixed(2)}, '
           'images: ${images.length}, links: ${relatedLinks.length}${author != null ? ", author: $author" : ""})';
  }
}

/// Citation reference for tracking sources in answers
class Citation {
  final String id;
  final Document document;
  final int startIndex;
  final int endIndex;

  const Citation({
    required this.id,
    required this.document,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  String toString() {
    return 'Citation(id: $id, doc: ${document.title}, range: $startIndex-$endIndex)';
  }
}

/// Context chunk for LLM prompt
class ContextChunk {
  final String content;
  final List<Citation> citations;
  final double relevanceScore;

  const ContextChunk({
    required this.content,
    required this.citations,
    required this.relevanceScore,
  });

  @override
  String toString() {
    return 'ContextChunk(length: ${content.length}, citations: ${citations.length}, score: $relevanceScore)';
  }
}