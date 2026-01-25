import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:searvo/features/search/domain/entities/autocomplete_entities.dart';
import 'package:searvo/features/search/domain/repositories/search_repository.dart';
import 'package:searvo/features/search/domain/usecases/get_autocomplete_suggestions_usecase.dart';
import 'package:searvo/features/search/domain/entities/search_intent.dart';

import 'get_autocomplete_suggestions_usecase_test.mocks.dart';

@GenerateMocks([SearchRepository])
void main() {
  late GetAutocompleteSuggestionsUseCase useCase;
  late MockSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchRepository();
    useCase = GetAutocompleteSuggestionsUseCase(mockRepository);
  });

  group('GetAutocompleteSuggestionsUseCase', () {
    test('should return empty list when query is too short', () async {
      // Act
      final result = await useCase('a');

      // Assert
      expect(result, isEmpty);
      verifyZeroInteractions(mockRepository);
    });

    test(
      'should return cached suggestions if query matches last query',
      () async {
        // Arrange
        when(
          mockRepository.getSuggestions(any),
        ).thenAnswer((_) async => ['test']);
        await useCase('test'); // First call to populate cache

        // Act
        final result = await useCase('test');

        // Assert
        expect(result.first.text, 'test');
        verify(
          mockRepository.getSuggestions(any),
        ).called(1); // Only called once
      },
    );

    test('should fetch and enhance suggestions from repository', () async {
      // Arrange
      const query = 'flutter';
      final suggestions = ['flutter tutorial', 'flutter widgets'];
      when(
        mockRepository.getSuggestions(any),
      ).thenAnswer((_) async => suggestions);

      // Act
      final result = await useCase(query);

      // Assert
      expect(result.length, 2);
      expect(result[0].text, 'flutter widgets');
      expect(result[0].type, SuggestionType.topic);
      expect(
        result[0].intent,
        SearchIntent.technical,
      ); // Matches query intent 'technical'

      expect(result[1].text, 'flutter tutorial');
      expect(result[1].intent, SearchIntent.howTo);
    });

    test('should return fallback suggestions on error', () async {
      // Arrange
      when(
        mockRepository.getSuggestions(any),
      ).thenThrow(Exception('Network error'));

      // Act
      final result = await useCase('flutter');

      // Assert
      expect(result, isNotEmpty);
      expect(result.first.text, 'flutter');
      expect(result.first.type, SuggestionType.topic);
    });

    test('should debounce calls', () async {
      // Arrange
      when(
        mockRepository.getSuggestions(any),
      ).thenAnswer((_) async => ['result']);

      // Act
      useCase.callDebounced('test', (results) {});
      useCase.callDebounced('test', (results) {});
      useCase.callDebounced('test', (results) {
        expect(results.first.text, 'result');
      });

      await Future.delayed(const Duration(milliseconds: 350));

      // Assert
      verify(mockRepository.getSuggestions(any)).called(1);
    });
  });
}
