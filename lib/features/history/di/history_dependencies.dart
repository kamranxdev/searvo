import 'package:searvo/core/di/injection_container.dart' as di;
import 'package:searvo/features/history/data/datasources/conversation_local_datasource.dart';
import 'package:searvo/features/history/data/repositories/conversation_repository_impl.dart';
import 'package:searvo/features/history/domain/repositories/conversation_repository.dart';
import 'package:searvo/features/history/domain/usecases/delete_conversation.dart';
import 'package:searvo/features/history/domain/usecases/delete_all_conversations.dart';
import 'package:searvo/features/history/domain/usecases/get_all_conversations.dart';
import 'package:searvo/features/history/domain/usecases/get_conversation_by_id.dart';
import 'package:searvo/features/history/domain/usecases/get_grouped_conversations.dart';
import 'package:searvo/features/history/domain/usecases/search_conversations.dart';
import 'package:searvo/features/history/domain/usecases/toggle_pin_conversation.dart';
import 'package:searvo/features/history/presentation/cubit/history_cubit.dart';
import 'package:searvo/features/history/services/conversation_database_service.dart';

/// Register all dependencies for History feature
Future<void> initHistoryDependencies() async {
  // Services (Singleton)
  if (!di.sl.isRegistered<ConversationDatabaseService>()) {
    final databaseService = ConversationDatabaseService();
    await databaseService.initialize();
    di.sl.registerLazySingleton<ConversationDatabaseService>(
      () => databaseService,
    );
  }

  // Data Sources
  di.sl.registerLazySingleton<ConversationLocalDataSource>(
    () => ConversationLocalDataSourceImpl(
      databaseService: di.sl<ConversationDatabaseService>(),
    ),
  );

  // Repository
  di.sl.registerLazySingleton<ConversationRepository>(
    () => ConversationRepositoryImpl(
      localDataSource: di.sl<ConversationLocalDataSource>(),
    ),
  );

  // Use Cases
  di.sl.registerLazySingleton(
    () => GetAllConversations(di.sl<ConversationRepository>()),
  );
  di.sl.registerLazySingleton(
    () => GetGroupedConversations(di.sl<ConversationRepository>()),
  );
  di.sl.registerLazySingleton(
    () => GetConversationById(di.sl<ConversationRepository>()),
  );
  di.sl.registerLazySingleton(
    () => SearchConversations(di.sl<ConversationRepository>()),
  );
  di.sl.registerLazySingleton(
    () => DeleteConversation(di.sl<ConversationRepository>()),
  );
  di.sl.registerLazySingleton(
    () => DeleteAllConversations(di.sl<ConversationRepository>()),
  );
  di.sl.registerLazySingleton(
    () => TogglePinConversation(di.sl<ConversationRepository>()),
  );

  // Cubit (Factory - new instance each time)
  di.sl.registerFactory(
    () => HistoryCubit(
      getAllConversations: di.sl<GetAllConversations>(),
      getGroupedConversations: di.sl<GetGroupedConversations>(),
      getConversationById: di.sl<GetConversationById>(),
      searchConversations: di.sl<SearchConversations>(),
      deleteConversation: di.sl<DeleteConversation>(),
      deleteAllConversations: di.sl<DeleteAllConversations>(),
      togglePinConversation: di.sl<TogglePinConversation>(),
    ),
  );
}
