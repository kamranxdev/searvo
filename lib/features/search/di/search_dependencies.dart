import 'package:get_it/get_it.dart';
import 'package:searvo/features/history/services/conversation_database_service.dart';
import 'package:searvo/features/search/presentation/bloc/search_bloc.dart';
import 'package:searvo/features/search/data/datasources/search_data_source.dart';
import 'package:searvo/features/search/presentation/bloc/conversation_manager.dart';
import 'package:searvo/features/discover/presentation/cubit/article_detail_cubit.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/settings/services/search_provider_settings_service.dart';
import 'package:searvo/features/search/domain/usecases/get_autocomplete_suggestions_usecase.dart';
import 'package:searvo/features/search/domain/repositories/search_repository.dart';
import 'package:searvo/features/search/data/repositories/search_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initSearchDependencies() async {
  // Settings Services
  if (!sl.isRegistered<LLMSettingsService>()) {
    sl.registerLazySingleton(() => LLMSettingsService());
  }
  if (!sl.isRegistered<SearchProviderSettingsService>()) {
    sl.registerLazySingleton(() => SearchProviderSettingsService());
  }

  // Conversation Management
  sl.registerLazySingleton(() => ConversationManager());

  // Search Remote Data Source (FastAPI Backend)
  sl.registerLazySingleton(
    () => SearchRemoteDataSource(
      searchSettings: sl(),
      llmSettings: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAutocompleteSuggestionsUseCase(sl()));

  // Blocs & Cubits
  sl.registerFactory(
    () => SearchBloc(
      searchRemoteDataSource: sl(),
      conversationManager: sl(),
      conversationDatabaseService: sl<ConversationDatabaseService>(),
    ),
  );

  sl.registerFactory(
    () => ArticleDetailCubit(searchRemoteDataSource: sl()),
  );
}
