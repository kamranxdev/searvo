import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:searvo/features/search/bloc/search_bloc.dart';
import 'package:searvo/features/search/bloc/search_event.dart';
import 'package:searvo/features/search/bloc/search_state.dart';
import 'package:searvo/features/search/domain/entities/message_branch_manager.dart';
import 'package:searvo/features/search/domain/entities/message_branch.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import 'package:searvo/features/search/domain/entities/search_mode.dart';
import 'package:searvo/features/search/domain/services/search_service.dart';
import 'package:searvo/features/search/presentation/bloc/conversation_manager.dart';
import 'package:searvo/features/search/rag/models/rag_models.dart';
import 'package:searvo/features/history/services/conversation_database_service.dart';
import 'package:searvo/features/history/models/conversation_model.dart';

import 'search_bloc_test.mocks.dart';

@GenerateMocks([
  SearchService,
  ConversationManager,
  ConversationDatabaseService,
  ConversationModel,
])
void main() {
  late MockSearchService mockSearchService;
  late MockConversationManager mockConversationManager;
  late MockConversationDatabaseService mockConversationDatabaseService;
  late SearchBloc searchBloc;

  setUp(() {
    mockSearchService = MockSearchService();
    mockConversationManager = MockConversationManager();
    mockConversationDatabaseService = MockConversationDatabaseService();

    // Default stubs to prevent null errors
    when(mockConversationManager.state).thenReturn(ConversationState.initial());
    when(mockSearchService.initialize()).thenAnswer((_) async {});

    // Stub sync service if needed logic calls it (e.g. saveConversation) - ignoring for now unless errors pop up

    searchBloc = SearchBloc(
      searchService: mockSearchService,
      conversationManager: mockConversationManager,
      conversationDatabaseService: mockConversationDatabaseService,
    );
  });

  tearDown(() {
    searchBloc.close();
  });

  group('SearchState Tests', () {
    group('Initial State', () {
      test('should have correct properties', () {
        const state = SearchState.initial();

        expect(state.messageBranches, isEmpty);
        expect(state.isProcessing, false);
        expect(state.conversationId, isNull);
        expect(state.conversationTitle, isNull);
        expect(state.hasActiveConversation, false);
      });
    });

    group('Loading State', () {
      test('should have correct properties', () {
        final branches = [
          MessageBranchManager(
            branches: [
              MessageBranch(
                id: 'b1',
                message: MessageData(query: 'q', answer: 'a'),
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ];

        final state = SearchState.loading(
          messageBranches: branches,
          conversationId: 'conv-1',
          conversationTitle: 'Test Title',
        );

        expect(state.messageBranches, branches);
        expect(state.isProcessing, true);
        expect(state.conversationId, 'conv-1');
        expect(state.conversationTitle, 'Test Title');
        expect(state.hasActiveConversation, true);
      });
    });

    group('Loaded State', () {
      test('should have correct properties', () {
        final branches = [
          MessageBranchManager(
            branches: [
              MessageBranch(
                id: 'b1',
                message: MessageData(query: 'q', answer: 'a'),
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ];

        final state = SearchState.loaded(
          messageBranches: branches,
          isProcessing: false,
          conversationId: 'conv-1',
          conversationTitle: 'Test Title',
        );

        expect(state.messageBranches, branches);
        expect(state.isProcessing, false);
        expect(state.conversationId, 'conv-1');
        expect(state.conversationTitle, 'Test Title');
        expect(state.hasActiveConversation, true);
      });

      test('should report isProcessing correctly', () {
        final branches = [
          MessageBranchManager(
            branches: [
              MessageBranch(
                id: 'b1',
                message: MessageData(query: 'q', answer: 'a'),
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ];

        final processingState = SearchState.loaded(
          messageBranches: branches,
          isProcessing: true,
        );

        final notProcessingState = SearchState.loaded(
          messageBranches: branches,
          isProcessing: false,
        );

        expect(processingState.isProcessing, true);
        expect(notProcessingState.isProcessing, false);
      });
    });

    group('Error State', () {
      test('should have correct properties', () {
        final branches = [
          MessageBranchManager(
            branches: [
              MessageBranch(
                id: 'b1',
                message: MessageData(query: 'q', answer: 'a'),
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ];

        final state = SearchState.error(
          message: 'Error occurred',
          messageBranches: branches,
          conversationId: 'conv-1',
          conversationTitle: 'Test',
        );

        expect(state.messageBranches, branches);
        expect(state.isProcessing, false);
        expect(state.conversationId, 'conv-1');
        expect(state.conversationTitle, 'Test');
      });
    });

    group('hasActiveConversation', () {
      test('should return false when no branches', () {
        const state = SearchState.initial();
        expect(state.hasActiveConversation, false);
      });

      test('should return true when has branches', () {
        final state = SearchState.loaded(
          messageBranches: [
            MessageBranchManager(
              branches: [
                MessageBranch(
                  id: 'b1',
                  message: MessageData(query: 'q', answer: 'a'),
                  createdAt: DateTime.now(),
                ),
              ],
            ),
          ],
          isProcessing: false,
        );
        expect(state.hasActiveConversation, true);
      });
    });
  });

  group('SearchEvent Tests', () {
    test('performInitialSearch event should contain correct data', () {
      const event = SearchEvent.performInitialSearch(
        query: 'test query',
        searchMode: SearchMode.search,
        conversationId: 'conv-123',
      );

      event.maybeWhen(
        performInitialSearch: (query, searchMode, attachments, conversationId) {
          expect(query, 'test query');
          expect(searchMode, SearchMode.search);
          expect(conversationId, 'conv-123');
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('addNewMessage event should contain correct data', () {
      const event = SearchEvent.addNewMessage(query: 'follow up query');

      event.maybeWhen(
        addNewMessage: (query, attachments) {
          expect(query, 'follow up query');
          expect(attachments, isNull);
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('rewriteMessage event should contain correct data', () {
      const event = SearchEvent.rewriteMessage(index: 2);

      event.maybeWhen(
        rewriteMessage: (index) {
          expect(index, 2);
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('editQuery event should contain correct data', () {
      const event = SearchEvent.editQuery(index: 1, newQuery: 'edited query');

      event.maybeWhen(
        editQuery: (index, newQuery) {
          expect(index, 1);
          expect(newQuery, 'edited query');
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('clearMessages event should be created', () {
      const event = SearchEvent.clearMessages();

      event.maybeWhen(
        clearMessages: () {
          // Event created successfully
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('loadConversation event should contain correct data', () {
      final branches = [
        MessageBranchManager(
          branches: [
            MessageBranch(
              id: 'b1',
              message: MessageData(query: 'q', answer: 'a'),
              createdAt: DateTime.now(),
            ),
          ],
        ),
      ];

      final event = SearchEvent.loadConversation(
        conversationId: 'loaded-conv',
        title: 'Loaded Title',
        branches: branches,
      );

      event.maybeWhen(
        loadConversation: (conversationId, title, loadedBranches) {
          expect(conversationId, 'loaded-conv');
          expect(title, 'Loaded Title');
          expect(loadedBranches, branches);
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('switchBranch event should contain correct data', () {
      const event = SearchEvent.switchBranch(messageIndex: 0, branchIndex: 2);

      event.maybeWhen(
        switchBranch: (messageIndex, branchIndex) {
          expect(messageIndex, 0);
          expect(branchIndex, 2);
        },
        orElse: () => fail('Wrong event type'),
      );
    });

    test('initialize event should be created', () {
      const event = SearchEvent.initialize();

      event.maybeWhen(
        initialize: () {
          // Event created successfully
        },
        orElse: () => fail('Wrong event type'),
      );
    });
  });

  group('SearchBloc Tests', () {
    test('initial state should be SearchState.initial', () {
      // For this test we can instantiate manually
      final bloc = SearchBloc(
        searchService: mockSearchService,
        conversationManager: mockConversationManager,
        conversationDatabaseService: mockConversationDatabaseService,
      );
      expect(bloc.state, const SearchState.initial());
      bloc.close();
    });

    blocTest<SearchBloc, SearchState>(
      'onInitialize should call searchService.initialize',
      build: () => SearchBloc(
        searchService: mockSearchService,
        conversationManager: mockConversationManager,
        conversationDatabaseService: mockConversationDatabaseService,
      ),
      act: (bloc) => bloc.add(const SearchEvent.initialize()),
      verify: (bloc) {
        verify(mockSearchService.initialize()).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'performInitialSearch should call conversationManager.startNewConversation',
      build: () {
        final branchManager = MessageBranchManager(
          branches: [
            MessageBranch(
              id: 'b1',
              message: MessageData(query: 'query', answer: ''),
              createdAt: DateTime.now(),
            ),
          ],
        );

        when(
          mockConversationManager.startNewConversation(
            any,
            providedId: anyNamed('providedId'),
          ),
        ).thenReturn(branchManager);

        when(mockConversationManager.state).thenReturn(
          ConversationState(
            messageBranches: [branchManager],
            conversationId: 'conv-1',
            conversationTitle: 'Title',
            isProcessing: true,
          ),
        );

        when(
          mockSearchService.generateSearchStream(
            any,
            attachments: anyNamed('attachments'),
            searchMode: anyNamed('searchMode'),
            isNewConversation: anyNamed('isNewConversation'),
          ),
        ).thenAnswer((_) => Stream.empty());

        when(
          mockConversationDatabaseService.getConversationByConversationId(any),
        ).thenAnswer((_) async => null);

        when(
          mockConversationDatabaseService.saveConversation(
            conversationId: anyNamed('conversationId'),
            title: anyNamed('title'),
            messageBranches: anyNamed('messageBranches'),
            tags: anyNamed('tags'),
          ),
        ).thenAnswer((_) async => MockConversationModel());

        return SearchBloc(
          searchService: mockSearchService,
          conversationManager: mockConversationManager,
          conversationDatabaseService: mockConversationDatabaseService,
        );
      },
      act: (bloc) => bloc.add(
        const SearchEvent.performInitialSearch(
          query: 'query',
          searchMode: SearchMode.search,
        ),
      ),
      verify: (bloc) {
        verify(mockConversationManager.startNewConversation('query')).called(1);
      },
    );
  });
}
