import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';

/// Abstract repository interface for discover
/// Implementation is in the data layer
abstract class DiscoverRepository {
  /// Fetch articles for a specific topic
  Future<Either<Failure, List<Article>>> getArticles(DiscoverTopic topic);
  
  /// Fetch preview articles for a specific topic (smaller set)
  Future<Either<Failure, List<Article>>> getPreviewArticles(DiscoverTopic topic);
}
