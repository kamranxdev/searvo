import 'dart:math';
import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/features/discover/data/models/article_model.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/search/data/models/search_response_model.dart';
import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/domain/entities/search_enums.dart';

/// Remote data source for discover articles
abstract class DiscoverRemoteDataSource {
  /// Fetch articles for a specific topic
  Future<List<ArticleModel>> getArticles(DiscoverTopic topic);

  /// Fetch preview articles for a specific topic
  Future<List<ArticleModel>> getPreviewArticles(DiscoverTopic topic);
}

class DiscoverRemoteDataSourceImpl implements DiscoverRemoteDataSource {
  final SearXNGRemoteDataSource searxngService;

  DiscoverRemoteDataSourceImpl({required this.searxngService});

  @override
  Future<List<ArticleModel>> getArticles(DiscoverTopic topic) async {
    try {
      final topicConfig = _getTopicConfig(topic);
      final List<ArticleModel> articles = [];
      final Set<String> seenUrls = {};
      final List<Future<SearchResponseModel>> searchFutures = [];

      // Create all search combinations
      for (final link in topicConfig.links) {
        for (final query in topicConfig.queries) {
          searchFutures.add(
            searxngService.search(
              'site:$link $query',
              page: 1,
              searchType: SearchType.news,
              language: 'en',
            ),
          );
        }
      }

      // Execute all searches in parallel
      final responses = await Future.wait(searchFutures);

      // Collect all results
      final allResults = <SearchResultModel>[];
      for (final response in responses) {
        allResults.addAll(response.results);
      }

      // Filter duplicates and convert to ArticleModel
      for (final result in allResults) {
        final url = result.url.toLowerCase().trim();
        if (!seenUrls.contains(url) && _hasThumbnail(result)) {
          seenUrls.add(url);
          articles.add(_convertToArticleModel(result));
        }
      }

      // Shuffle the results for variety
      articles.shuffle();

      return articles;
    } catch (e) {
      throw ServerException('Failed to fetch articles: ${e.toString()}');
    }
  }

  @override
  Future<List<ArticleModel>> getPreviewArticles(DiscoverTopic topic) async {
    try {
      final topicConfig = _getTopicConfig(topic);
      final random = Random();
      final randomLink =
          topicConfig.links[random.nextInt(topicConfig.links.length)];
      final randomQuery =
          topicConfig.queries[random.nextInt(topicConfig.queries.length)];

      final response = await searxngService.search(
        'site:$randomLink $randomQuery',
        page: 1,
        searchType: SearchType.news,
        language: 'en',
      );

      // Convert results that have thumbnails
      return response.results
          .where(_hasThumbnail)
          .map(_convertToArticleModel)
          .toList();
    } catch (e) {
      throw ServerException(
        'Failed to fetch preview articles: ${e.toString()}',
      );
    }
  }

  /// Check if a search result has a thumbnail
  bool _hasThumbnail(SearchResultModel result) {
    return result.thumbnail.isNotEmpty &&
        !result.thumbnail.contains('favicon.im');
  }

  /// Convert search result to ArticleModel
  ArticleModel _convertToArticleModel(SearchResultModel result) {
    return ArticleModel(
      title: result.title,
      content: result.snippet,
      url: result.url,
      thumbnail: result.thumbnail,
    );
  }

  /// Get topic configuration
  _TopicConfig _getTopicConfig(DiscoverTopic topic) {
    switch (topic) {
      case DiscoverTopic.tech:
        return _TopicConfig(
          queries: [
            'technology news',
            'latest tech',
            'AI',
            'science and innovation',
          ],
          links: ['techcrunch.com', 'wired.com', 'theverge.com'],
        );
      case DiscoverTopic.finance:
        return _TopicConfig(
          queries: ['finance news', 'economy', 'stock market', 'investing'],
          links: ['bloomberg.com', 'reuters.com', 'cnbc.com'],
        );
      case DiscoverTopic.art:
        return _TopicConfig(
          queries: ['art news', 'culture', 'museums', 'artists'],
          links: ['artnet.com', 'artforum.com', 'theartnewspaper.com'],
        );
      case DiscoverTopic.sports:
        return _TopicConfig(
          queries: ['sports news', 'football', 'basketball', 'athletics'],
          links: ['espn.com', 'sportingnews.com', 'theguardian.com/sport'],
        );
      case DiscoverTopic.entertainment:
        return _TopicConfig(
          queries: ['entertainment news', 'movies', 'music', 'celebrities'],
          links: ['variety.com', 'hollywoodreporter.com', 'entertainment.com'],
        );
    }
  }
}

/// Helper class for topic configuration
class _TopicConfig {
  final List<String> queries;
  final List<String> links;

  _TopicConfig({required this.queries, required this.links});
}
