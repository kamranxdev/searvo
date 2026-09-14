import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/search/data/datasources/search_data_source.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';
import 'package:searvo/features/search/domain/entities/search_stream_status.dart';

import 'article_detail_state.dart';

class ArticleDetailCubit extends Cubit<ArticleDetailState> {
  final SearchRemoteDataSource _searchRemoteDataSource;

  final StringBuffer _responseBuffer = StringBuffer();

  ArticleDetailCubit({
    required SearchRemoteDataSource searchRemoteDataSource,
  }) : _searchRemoteDataSource = searchRemoteDataSource,
       super(ArticleDetailInitial());

  Future<void> learnMore(Article article) async {
    emit(const ArticleDetailLoadingAI(streamingText: "Exploring topic..."));
    _responseBuffer.clear();

    final sourceItems = <SourceItem>[
      SourceItem(
        title: article.title,
        url: article.url,
        description: "Original Article",
        thumbnail: article.thumbnail,
        domain: "Discover",
        source: "Discover",
      ),
    ];

    try {
      final query =
          "Tell me more about '${article.title}' and provide related context and details.";
      final stream = _searchRemoteDataSource.streamSearch(query);

      await for (final update in stream) {
        if (update.status == SearchStreamStatus.streaming && update.token != null) {
          _responseBuffer.write(update.token);
          emit(
            ArticleDetailLoadingAI(streamingText: _responseBuffer.toString()),
          );
        } else if (update.status == SearchStreamStatus.completed) {
          final sources =
              update.finalResult?.sources.isNotEmpty == true
                  ? update.finalResult!.sources
                  : sourceItems;
          emit(
            ArticleDetailLoadedAI(
              content:
                  update.finalResult?.answer.isNotEmpty == true
                      ? update.finalResult!.answer
                      : _responseBuffer.toString(),
              sources: sources,
            ),
          );
          return;
        } else if (update.status == SearchStreamStatus.thinking ||
            update.status == SearchStreamStatus.searching) {
          emit(
            ArticleDetailLoadingAI(
              streamingText: update.message ?? "Analyzing topic...",
            ),
          );
        }
      }

      emit(
        ArticleDetailLoadedAI(
          content: _responseBuffer.toString(),
          sources: sourceItems,
        ),
      );
    } catch (e) {
      emit(ArticleDetailError("Failed to learn more: $e"));
    }
  }
}
