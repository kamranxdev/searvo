import 'package:get_it/get_it.dart';
import 'package:searvo/features/history/services/conversation_database_service.dart';
import 'package:searvo/features/search/presentation/bloc/search_bloc.dart';
import 'package:searvo/features/search/rag/bloc/rag_cubit.dart';
import 'package:searvo/features/search/rag/services/orchestration/rag_orchestrator.dart';
import 'package:searvo/features/search/domain/services/search_service.dart';
import 'package:searvo/features/search/presentation/bloc/conversation_manager.dart';
import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/rag/services/document_processing/document_ranker.dart';
import 'package:searvo/features/search/rag/services/document_processing/context_fusion.dart';
import 'package:searvo/features/search/rag/services/citation/citation_manager.dart';
import 'package:searvo/features/llm/services/providers/llm_provider_manager.dart';
import 'package:searvo/features/search/rag/services/query_processing/prompt_engineer.dart';
import 'package:searvo/features/search/rag/services/data_ingestion/attachment_processor.dart';
import 'package:searvo/features/search/rag/services/query_processing/query_analyzer.dart';
import 'package:searvo/features/search/rag/services/data_ingestion/rag_scraper_adapter.dart';
import 'package:searvo/features/search/domain/services/intent_classifier.dart';
import 'package:searvo/features/search/data/datasources/search_local_data_source.dart';
import 'package:searvo/features/settings/services/llm_settings_service.dart';
import 'package:searvo/features/settings/services/search_provider_settings_service.dart';
import 'package:searvo/features/search/domain/usecases/get_autocomplete_suggestions_usecase.dart';
import 'package:searvo/features/search/domain/repositories/search_repository.dart';
import 'package:searvo/features/search/data/repositories/search_repository_impl.dart';

final sl = GetIt.instance;

Future<void> initSearchDependencies() async {
  // Services
  sl.registerLazySingleton(() => SearXNGRemoteDataSource());
  sl.registerLazySingleton(() => SearchLocalDataSource());
  sl.registerLazySingleton(() => LLMProviderManager());

  // Settings Services (Ensure they are registered if not already)
  if (!sl.isRegistered<LLMSettingsService>()) {
    sl.registerLazySingleton(() => LLMSettingsService());
  }
  if (!sl.isRegistered<SearchProviderSettingsService>()) {
    sl.registerLazySingleton(() => SearchProviderSettingsService());
  }

  // RAG Components
  sl.registerLazySingleton(() => DocumentRanker());
  sl.registerLazySingleton(() => ContextFusion());
  sl.registerLazySingleton(() => CitationManager());
  sl.registerLazySingleton(() => PromptEngineer());
  sl.registerLazySingleton(() => AttachmentProcessor());
  sl.registerLazySingleton(() => QueryAnalyzer());
  sl.registerLazySingleton(() => RAGScraperAdapter());
  sl.registerLazySingleton(() => IntentClassifier());

  // RAG Orchestrator
  sl.registerLazySingleton(
    () => RAGOrchestrator(
      searxngService: sl(),
      documentRanker: sl(),
      contextFusion: sl(),
      citationManager: sl(),
      llmManager: sl(),
      promptEngineer: sl(),
      attachmentProcessor: sl(),
      queryAnalyzer: sl(),
      scraperAdapter: sl(),
      cacheService: sl(),
      intentClassifier: sl(),
    ),
  );

  sl.registerLazySingleton(() => ConversationManager());

  // Repositories
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAutocompleteSuggestionsUseCase(sl()));

  // Search Service
  sl.registerLazySingleton(
    () => SearchService(
      ragOrchestrator: sl(),
      llmSettings: sl(),
      searchSettings: sl(),
      scraperAdapter: sl(),
      queryAnalyzer: sl(),
    ),
  );

  // Blocs
  sl.registerFactory(
    () => SearchBloc(
      searchService: sl(),
      conversationManager: sl(),
      conversationDatabaseService: sl<ConversationDatabaseService>(),
    ),
  );

  sl.registerFactory(() => RAGCubit(ragOrchestrator: sl()));
}
