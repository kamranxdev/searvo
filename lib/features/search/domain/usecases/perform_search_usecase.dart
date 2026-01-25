import '../repositories/search_repository.dart';

class PerformSearchUseCase {
  final SearchRepository repository;

  PerformSearchUseCase(this.repository);

  Stream<dynamic> call(
    String query, {
    Map<String, dynamic> options = const {},
  }) {
    return repository.performSearch(query, options: options);
  }
}
