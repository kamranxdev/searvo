import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:searvo/features/discover/domain/entities/article.dart';
import 'package:searvo/features/search/data/datasources/searxng_remote_data_source.dart';
import 'package:searvo/features/search/domain/entities/source_item.dart';
import 'package:searvo/features/search/rag/services/langchain_service.dart';
import 'package:langchain_core/documents.dart' as lc;

import 'article_detail_state.dart';

class ArticleDetailCubit extends Cubit<ArticleDetailState> {
  final SearXNGRemoteDataSource _searxngService;
  final LangChainService _langChainService;

  // Keep track of the full generated answer
  final StringBuffer _responseBuffer = StringBuffer();

  ArticleDetailCubit({
    required SearXNGRemoteDataSource searxngService,
    required LangChainService langChainService,
  }) : _searxngService = searxngService,
       _langChainService = langChainService,
       super(ArticleDetailInitial());

  Future<void> learnMore(Article article) async {
    // If we already have loaded content for this article, maybe don't reload?
    // For now, assume a fresh load every time 'Learn More' is requested or re-requested.

    emit(const ArticleDetailLoadingAI(streamingText: "Exploring topic..."));
    _responseBuffer.clear();

    try {
      // 1. Perform Web Search for the article title to get extra context
      final searchResults = await _searxngService.search(article.title);

      final webDocs = <lc.Document>[];
      final sourceItems = <SourceItem>[];

      // Source 1 is always the article itself (Implicitly or Explicitly)
      // We'll treat the article as a primary source document
      final articleDoc = lc.Document(
        pageContent: "${article.title}\n\n${article.content}",
        metadata: {
          'title': article.title,
          'url': article.url,
          'source': 'Original Article',
          'thumbnail': article.thumbnail,
        },
      );

      webDocs.add(articleDoc);

      // Add a source item for the original article
      sourceItems.add(
        SourceItem(
          title: article.title,
          url: article.url,
          description: "Original Article",
          thumbnail: article.thumbnail,
          domain: "Discover",
          source: "Discover",
        ),
      );

      // 2. Process Web Results
      if (searchResults.results.isNotEmpty) {
        emit(const ArticleDetailLoadingAI(streamingText: "Reading sources..."));

        for (final result in searchResults.results.take(5)) {
          // Take top 5 web results
          webDocs.add(
            lc.Document(
              pageContent: result.snippet,
              metadata: {
                'title': result.title,
                'url': result.url,
                'source': result.source,
                'thumbnail': result.thumbnail,
              },
            ),
          );

          sourceItems.add(
            SourceItem(
              title: result.title,
              url: result.url,
              description: result.snippet,
              thumbnail: result.thumbnail,
              domain: Uri.tryParse(result.url)?.host ?? '',
              source: result.source ?? 'Web',
            ),
          );
        }
      }

      // 3. Generate Answer using LangChain
      emit(const ArticleDetailLoadingAI(streamingText: "Analyzing..."));

      final stream = _langChainService.generateAnswer(
        "Tell me more about '${article.title}' and provide related context and details.",
        webDocs,
      );

      await for (final token in stream) {
        _responseBuffer.write(token);
        emit(ArticleDetailLoadingAI(streamingText: _responseBuffer.toString()));
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
