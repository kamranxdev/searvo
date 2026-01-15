import 'package:searvo/features/discover/domain/entities/article.dart';

/// Data Transfer Object for Article
/// Extends the domain entity and adds serialization capabilities
class ArticleModel extends Article {
  const ArticleModel({
    required super.title,
    required super.content,
    required super.url,
    required super.thumbnail,
  });

  /// Convert domain entity to model
  factory ArticleModel.fromEntity(Article article) {
    return ArticleModel(
      title: article.title,
      content: article.content,
      url: article.url,
      thumbnail: article.thumbnail,
    );
  }

  /// Convert model to domain entity
  Article toEntity() {
    return Article(
      title: title,
      content: content,
      url: url,
      thumbnail: thumbnail,
    );
  }

  /// Create from JSON
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? json['img_src'] ?? '',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'url': url,
      'thumbnail': thumbnail,
    };
  }
}
