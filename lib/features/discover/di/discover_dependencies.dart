import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:searvo/features/discover/data/repositories/discover_repository_impl.dart';
import 'package:searvo/features/discover/domain/repositories/discover_repository.dart';
import 'package:searvo/features/discover/domain/usecases/get_articles.dart';
import 'package:searvo/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:searvo/features/search/services/searxng_service.dart';

/// Initialize discover feature dependencies
Future<void> initDiscoverDependencies() async {
  // Data sources
  sl.registerLazySingleton<DiscoverRemoteDataSource>(
    () => DiscoverRemoteDataSourceImpl(
      searxngService: SearXNGService(),
    ),
  );

  // Repository
  sl.registerLazySingleton<DiscoverRepository>(
    () => DiscoverRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetArticles(sl()));

  // Cubit
  sl.registerFactory(
    () => DiscoverCubit(
      getArticles: sl(),
    ),
  );
}
