import 'package:flutter_bloc/flutter_bloc.dart';
import 'rag_state.dart';
import '../models/rag_models.dart';
import '../../data/datasources/rag_data_source.dart';
import '../services/data_ingestion/rag_scraper_adapter.dart';
import '../services/data_ingestion/pdf_extractor_service.dart';
import '../services/query_processing/query_analyzer.dart';
import '../../domain/entities/message_data.dart';

class RAGCubit extends Cubit<RAGState> {
  final RAGDataSource _ragDataSource;
  final RAGScraperAdapter _scraperAdapter = RAGScraperAdapter();
  final PDFExtractorService _pdfExtractor = PDFExtractorService();
  final QueryAnalyzer _queryAnalyzer = QueryAnalyzer();

  RAGCubit({required RAGDataSource ragDataSource})
    : _ragDataSource = ragDataSource,
      super(const RAGState());

  Future<void> initialize() async {
    // Initialize RAG services if needed
  }

  Future<QueryAnalysis> analyzeQuery(String query) async {
    emit(state.copyWith(isAnalyzingQuery: true, errorMessage: null));

    try {
      final analysis = _queryAnalyzer.analyzeQuery(query);
      emit(
        state.copyWith(isAnalyzingQuery: false, lastQueryAnalysis: analysis),
      );
      return analysis;
    } catch (e) {
      emit(state.copyWith(isAnalyzingQuery: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<Document> scrapeWebContent(String url) async {
    emit(state.copyWith(isProcessingWebScraping: true, errorMessage: null));

    try {
      final document = await _scraperAdapter.scrape(url);
      emit(state.copyWith(isProcessingWebScraping: false));
      return document;
    } catch (e) {
      emit(
        state.copyWith(
          isProcessingWebScraping: false,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  Future<PDFContent> extractPDFContent(String url) async {
    emit(state.copyWith(isProcessingPDF: true, errorMessage: null));

    try {
      final content = await _pdfExtractor.extractFromUrl(url);
      emit(state.copyWith(isProcessingPDF: false));
      return content;
    } catch (e) {
      emit(state.copyWith(isProcessingPDF: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  Future<MessageData> generateRAGResponse({
    required String query,
    List<dynamic>? attachments,
  }) async {
    emit(state.copyWith(isProcessingRAG: true, errorMessage: null));

    try {
      MessageData? finalResponse;
      await for (final update in _ragDataSource.generateRAGStream(
        query,
        attachments: attachments,
      )) {
        if (update.finalResult != null) {
          finalResponse = update.finalResult;
        }
      }

      if (finalResponse == null) {
        throw Exception('Failed to generate response');
      }

      final response = finalResponse;

      emit(state.copyWith(isProcessingRAG: false));
      return response;
    } catch (e) {
      emit(state.copyWith(isProcessingRAG: false, errorMessage: e.toString()));
      rethrow;
    }
  }

  void clearCache() {
    emit(
      state.copyWith(
        cachedDocuments: [],
        lastQueryAnalysis: null,
        performanceMetrics: {},
      ),
    );
  }

  void addDocuments(List<Document> documents) {
    final updatedDocs = List<Document>.from(state.cachedDocuments)
      ..addAll(documents);
    emit(state.copyWith(cachedDocuments: updatedDocs));
  }

  void removeDocument(String documentId) {
    final updatedDocs = state.cachedDocuments
        .where((doc) => doc.id != documentId)
        .toList();
    emit(state.copyWith(cachedDocuments: updatedDocs));
  }
}
