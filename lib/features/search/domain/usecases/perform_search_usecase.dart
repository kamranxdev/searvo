import '../repositories/search_repository.dart';
import '../entities/search_mode.dart';

class PerformSearchUseCase {
  final SearchRepository repository;

  PerformSearchUseCase(this.repository);

  Stream<dynamic> call(
    String query, {
    SearchMode searchMode = SearchMode.search,
    Map<String, dynamic> options = const {},
  }) {
    return repository.performSearch(
      query,
      searchMode: searchMode,
      options: options,
    );
  }
}
