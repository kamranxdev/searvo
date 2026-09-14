import 'package:searvo/core/di/injection_container.dart';
import 'package:searvo/features/discover/data/datasources/discover_remote_datasource.dart';
import 'package:searvo/features/discover/data/repositories/discover_repository_impl.dart';
import 'package:searvo/features/discover/domain/repositories/discover_repository.dart';
import 'package:searvo/features/discover/domain/usecases/get_articles.dart';
import 'package:searvo/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:searvo/features/search/data/datasources/search_data_source.dart';

/// Initialize discover feature dependencies
Future<void> initDiscoverDependencies() async {
  // Data sources
  sl.registerLazySingleton<DiscoverRemoteDataSource>(
    () => DiscoverRemoteDataSourceImpl(
      searchRemoteDataSource: sl<SearchRemoteDataSource>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<DiscoverRepository>(
    () => DiscoverRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetArticles(sl()));

  // Cubit
  sl.registerFactory(() => DiscoverCubit(getArticles: sl()));
}
