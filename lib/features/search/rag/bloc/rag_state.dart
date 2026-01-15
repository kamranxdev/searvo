import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/rag_models.dart';
import '../services/query_processing/query_analyzer.dart';

part 'rag_state.freezed.dart';

@freezed
sealed class RAGState with _$RAGState {
  const factory RAGState({
    @Default(false) bool isProcessingRAG,
    @Default(false) bool isProcessingAttachments,
    @Default(false) bool isProcessingWebScraping,
    @Default(false) bool isProcessingPDF,
    @Default(false) bool isAnalyzingQuery,
    @Default([]) List<Document> cachedDocuments,
    QueryAnalysis? lastQueryAnalysis,
    @Default({}) Map<String, dynamic> performanceMetrics,
    String? errorMessage,
  }) = _RAGState;

  const RAGState._();

  bool get isAnyProcessing =>
      isProcessingRAG ||
      isProcessingAttachments ||
      isProcessingWebScraping ||
      isProcessingPDF ||
      isAnalyzingQuery;
}
