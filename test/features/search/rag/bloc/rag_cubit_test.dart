import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:searvo/features/search/rag/bloc/rag_cubit.dart';
import 'package:searvo/features/search/rag/bloc/rag_state.dart';
import 'package:searvo/features/search/data/datasources/rag_data_source.dart';
import 'package:searvo/features/search/domain/entities/message_data.dart';
import 'package:searvo/features/search/rag/domain/entities/rag_update.dart';
import 'package:searvo/features/search/rag/domain/entities/rag_status.dart';

class MockRAGDataSource extends Mock implements RAGDataSource {
  @override
  Stream<RAGUpdate> generateRAGStream(
    String? query, {
    int? maxSearchResults = 20,
    int? maxRelevantDocuments = 10,
    int? maxContextLength,
    bool? enableQueryEnhancement = true,
    bool? enableAdaptivePrompting = true,
    List<dynamic>? attachments,
    dynamic searchMode,
    List<MessageData>? previousMessages,
    int? maxHistoryMessages = 3,
    bool? isNewConversation = false,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #generateRAGStream,
        [query],
        {
          #maxSearchResults: maxSearchResults,
          #maxRelevantDocuments: maxRelevantDocuments,
          #maxContextLength: maxContextLength,
          #enableQueryEnhancement: enableQueryEnhancement,
          #enableAdaptivePrompting: enableAdaptivePrompting,
          #attachments: attachments,
          #searchMode: searchMode,
          #previousMessages: previousMessages,
          #maxHistoryMessages: maxHistoryMessages,
          #isNewConversation: isNewConversation,
        },
      ),
      returnValue: Stream<RAGUpdate>.empty(),
    );
  }
}

void main() {
  group('RAGCubit Tests', () {
    late RAGCubit ragCubit;
    late MockRAGDataSource mockRAGDataSource;

    setUp(() {
      mockRAGDataSource = MockRAGDataSource();
      ragCubit = RAGCubit(ragDataSource: mockRAGDataSource);
    });

    tearDown(() {
      ragCubit.close();
    });

    test('initial state should be RAGState with defaults', () {
      expect(ragCubit.state.isProcessingRAG, false);
    });

    blocTest<RAGCubit, RAGState>(
      'generateRAGResponse should consume stream and return result',
      build: () {
        when(
          mockRAGDataSource.generateRAGStream(
            any,
            attachments: anyNamed('attachments'),
            searchMode: anyNamed('searchMode'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            RAGUpdate(status: RAGStatus.searching),
            RAGUpdate(
              status: RAGStatus.completed,
              finalResult: MessageData(query: 'test', answer: 'Success'),
            ),
          ]),
        );
        return ragCubit;
      },
      act: (cubit) async => await cubit.generateRAGResponse(query: 'test'),
      verify: (cubit) {
        verify(
          mockRAGDataSource.generateRAGStream(
            any,
            attachments: anyNamed('attachments'),
            searchMode: anyNamed('searchMode'),
          ),
        ).called(1);
      },
      expect: () => [
        const RAGState(isProcessingRAG: true),
        const RAGState(isProcessingRAG: false),
      ],
    );

    blocTest<RAGCubit, RAGState>(
      'generateRAGResponse should throw if stream yields no result',
      build: () {
        when(
          mockRAGDataSource.generateRAGStream(
            any,
            attachments: anyNamed('attachments'),
            searchMode: anyNamed('searchMode'),
          ),
        ).thenAnswer(
          (_) => Stream.fromIterable([
            RAGUpdate(status: RAGStatus.searching),
            // No final result
          ]),
        );
        return ragCubit;
      },
      act: (cubit) async {
        try {
          await cubit.generateRAGResponse(query: 'test');
        } catch (_) {}
      },
      expect: () => [
        const RAGState(isProcessingRAG: true),
        predicate(
          (state) =>
              state is RAGState &&
              state.isProcessingRAG == false &&
              state.errorMessage != null,
        ),
      ],
    );
  });
}
