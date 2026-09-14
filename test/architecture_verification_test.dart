import 'package:flutter_test/flutter_test.dart';

import 'package:searvo/features/search/domain/repositories/search_repository.dart';
import 'package:searvo/features/search/data/repositories/search_repository_impl.dart';
import 'package:searvo/features/search/domain/usecases/get_autocomplete_suggestions_usecase.dart';
import 'package:searvo/features/search/data/datasources/search_data_source.dart';
import 'package:searvo/features/search/domain/entities/search_enums.dart';

void main() {
  test('Architecture Verification', () {
    // 1. Verify Enum Availability
    expect(SearchType.general, isNotNull);
    expect(SearchRecency.any, isNotNull);

    // 2. Verify Repository Implementation with SearchRemoteDataSource
    final remoteDataSource = SearchRemoteDataSource();
    final repository = SearchRepositoryImpl(
      remoteDataSource: remoteDataSource,
    );

    expect(repository, isA<SearchRepository>());

    // 3. Verify UseCase
    final autocompleteUseCase = GetAutocompleteSuggestionsUseCase(repository);
    expect(autocompleteUseCase, isNotNull);
  });
}
