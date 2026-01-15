import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/usecases/usecase.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/domain/repositories/discover_repository.dart';

/// Use case for getting articles by topic
class GetArticles implements UseCase<List<Article>, GetArticlesParams> {
  final DiscoverRepository repository;

  GetArticles(this.repository);

  @override
  Future<Either<Failure, List<Article>>> call(GetArticlesParams params) async {
    if (params.isPreview) {
      return await repository.getPreviewArticles(params.topic);
    }
    return await repository.getArticles(params.topic);
  }
}

class GetArticlesParams extends UseCaseParams {
  final DiscoverTopic topic;
  final bool isPreview;

  const GetArticlesParams({
    required this.topic,
    this.isPreview = false,
  });

  @override
  List<Object?> get props => [topic, isPreview];
}
