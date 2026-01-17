import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:searvo/features/search/domain/entities/autocomplete_entities.dart';
import 'package:searvo/features/search/domain/repositories/search_repository.dart';
import 'package:searvo/features/search/domain/usecases/get_autocomplete_suggestions_usecase.dart';

import 'get_autocomplete_suggestions_usecase_test.mocks.dart';

@GenerateMocks([SearchRepository])
void main() {
  late GetAutocompleteSuggestionsUseCase useCase;
  late MockSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchRepository();
    useCase = GetAutocompleteSuggestionsUseCase(mockRepository);
  });

  test(
    'should return fallback suggestions when repository returns empty list',
    () async {
      // Arrange
      const query = 'flutter';

      // Simulate repository returning empty list (no results found)
      when(mockRepository.getSuggestions(any)).thenAnswer((_) async => []);

      // Act
      final result = await useCase(query);

      // Assert
      // We expect fallback suggestions to be generated, so result should NOT be empty
      expect(
        result,
        isNotEmpty,
        reason: 'Should return fallback suggestions even if API returns empty',
      );

      // Verify it's not just an empty list
      expect(
        result.first.type,
        isNotNull,
      ); // Just checking we got some suggestions
    },
  );
}
