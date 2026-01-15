import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/discover/domain/usecases/get_articles.dart';
import 'package:searvo/features/discover/presentation/cubit/discover_state.dart';

/// Cubit for managing discover state
/// Uses use cases from domain layer
class DiscoverCubit extends Cubit<DiscoverState> {
  final GetArticles getArticles;

  DiscoverCubit({
    required this.getArticles,
  }) : super(const DiscoverState.initial());

  /// Load articles for a topic
  Future<void> loadArticles(DiscoverTopic topic, {bool isPreview = false}) async {
    emit(const DiscoverState.loading());
    final result = await getArticles(
      GetArticlesParams(topic: topic, isPreview: isPreview),
    );
    result.fold(
      (failure) => emit(DiscoverState.error(failure)),
      (articles) => emit(DiscoverState.loaded(articles, topic)),
    );
  }

  /// Refresh articles for current topic
  Future<void> refreshArticles() async {
    await state.maybeWhen(
      loaded: (articles, currentTopic) async {
        await loadArticles(currentTopic);
      },
      orElse: () async {},
    );
  }

  /// Load preview articles for a topic
  Future<void> loadPreviewArticles(DiscoverTopic topic) async {
    await loadArticles(topic, isPreview: true);
  }
}
