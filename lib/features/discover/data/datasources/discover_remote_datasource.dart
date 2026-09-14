import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/features/discover/data/models/article_model.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/search/data/datasources/search_data_source.dart';

/// Remote data source for discover articles
abstract class DiscoverRemoteDataSource {
  /// Fetch articles for a specific topic
  Future<List<ArticleModel>> getArticles(DiscoverTopic topic);

  /// Fetch preview articles for a specific topic
  Future<List<ArticleModel>> getPreviewArticles(DiscoverTopic topic);
}

class DiscoverRemoteDataSourceImpl implements DiscoverRemoteDataSource {
  final SearchRemoteDataSource searchRemoteDataSource;

  DiscoverRemoteDataSourceImpl({
    required this.searchRemoteDataSource,
  });

  @override
  Future<List<ArticleModel>> getArticles(DiscoverTopic topic) async {
    try {
      final topicName = topic.name.toLowerCase();
      final rawArticles = await searchRemoteDataSource.getDiscoverArticles(
        topic: topicName,
        limit: 15,
      );
      return rawArticles.map((a) => ArticleModel(
        title: a['title']?.toString() ?? '',
        content: a['content']?.toString() ?? a['snippet']?.toString() ?? '',
        url: a['url']?.toString() ?? '',
        thumbnail: a['thumbnail']?.toString() ?? '',
      )).toList();
    } catch (e) {
      throw ServerException('Failed to fetch articles: $e');
    }
  }

  @override
  Future<List<ArticleModel>> getPreviewArticles(DiscoverTopic topic) async {
    try {
      final topicName = topic.name.toLowerCase();
      final rawArticles = await searchRemoteDataSource.getDiscoverArticles(
        topic: topicName,
        limit: 5,
      );
      return rawArticles.map((a) => ArticleModel(
        title: a['title']?.toString() ?? '',
        content: a['content']?.toString() ?? a['snippet']?.toString() ?? '',
        url: a['url']?.toString() ?? '',
        thumbnail: a['thumbnail']?.toString() ?? '',
      )).toList();
    } catch (e) {
      throw ServerException('Failed to fetch preview articles: $e');
    }
  }
}
