import 'package:dartz/dartz.dart';
import 'package:searvo/core/error/exceptions.dart';
import 'package:searvo/core/error/failures.dart';
import 'package:searvo/core/network/network_info.dart';
import 'package:searvo/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/domain/repositories/discover_repository.dart';

/// Implementation of DiscoverRepository
/// Handles error mapping from data layer exceptions to domain failures
class DiscoverRepositoryImpl implements DiscoverRepository {
  final DiscoverRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DiscoverRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Article>>> getArticles(DiscoverTopic topic) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final articleModels = await remoteDataSource.getArticles(topic);
      final articles = articleModels.map((model) => model.toEntity()).toList();
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Article>>> getPreviewArticles(DiscoverTopic topic) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }

    try {
      final articleModels = await remoteDataSource.getPreviewArticles(topic);
      final articles = articleModels.map((model) => model.toEntity()).toList();
      return Right(articles);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
