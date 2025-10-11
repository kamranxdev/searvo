import 'package:flutter/material.dart';
import '../models/rag_models.dart';
import '../services/orchestration/rag_orchestrator.dart';
import '../services/data_ingestion/attachment_processor.dart';
import '../services/data_ingestion/web_scraper_service.dart';
import '../services/data_ingestion/pdf_extractor_service.dart';
import '../services/query_processing/query_analyzer.dart';
import '../../models/message_data.dart';
import '../../widgets/search_box.dart';

class RAGProvider extends ChangeNotifier {
  final RAGOrchestrator _ragOrchestrator = RAGOrchestrator();
  final AttachmentProcessor _attachmentProcessor = AttachmentProcessor();
  final WebScraperService _webScraper = WebScraperService();
  final PDFExtractorService _pdfExtractor = PDFExtractorService();
  final QueryAnalyzer _queryAnalyzer = QueryAnalyzer();

  // State
  bool _isProcessingRAG = false;
  bool _isProcessingAttachments = false;
  bool _isProcessingWebScraping = false;
  bool _isProcessingPDF = false;
  bool _isAnalyzingQuery = false;

  List<Document> _cachedDocuments = [];
  QueryAnalysis? _lastQueryAnalysis;
  Map<String, dynamic> _performanceMetrics = {};

  // Getters
  bool get isProcessingRAG => _isProcessingRAG;
  bool get isProcessingAttachments => _isProcessingAttachments;
  bool get isProcessingWebScraping => _isProcessingWebScraping;
  bool get isProcessingPDF => _isProcessingPDF;
  bool get isAnalyzingQuery => _isAnalyzingQuery;
  bool get isAnyProcessing => _isProcessingRAG || _isProcessingAttachments ||
                              _isProcessingWebScraping || _isProcessingPDF ||
                              _isAnalyzingQuery;

  List<Document> get cachedDocuments => _cachedDocuments;
  QueryAnalysis? get lastQueryAnalysis => _lastQueryAnalysis;
  Map<String, dynamic> get performanceMetrics => _performanceMetrics;

  Future<void> initialize() async {
    // Initialize RAG services if needed
    notifyListeners();
  }

  Future<QueryAnalysis> analyzeQuery(String query) async {
    _isAnalyzingQuery = true;
    notifyListeners();

    try {
      _lastQueryAnalysis = _queryAnalyzer.analyzeQuery(query);
      return _lastQueryAnalysis!;
    } finally {
      _isAnalyzingQuery = false;
      notifyListeners();
    }
  }

  Future<List<AttachmentProcessResult>> processAttachments(List<String> filePaths, List<String> fileNames) async {
    _isProcessingAttachments = true;
    notifyListeners();

    try {
      final results = <AttachmentProcessResult>[];
      for (int i = 0; i < filePaths.length; i++) {
        final result = await _attachmentProcessor.processAttachment(filePaths[i], fileNames[i]);
        results.add(result);
      }
      return results;
    } finally {
      _isProcessingAttachments = false;
      notifyListeners();
    }
  }

  Future<ScrapedContent> scrapeWebContent(String url) async {
    _isProcessingWebScraping = true;
    notifyListeners();

    try {
      return await _webScraper.scrape(url);
    } finally {
      _isProcessingWebScraping = false;
      notifyListeners();
    }
  }

  Future<PDFContent> extractPDFContent(String url) async {
    _isProcessingPDF = true;
    notifyListeners();

    try {
      return await _pdfExtractor.extractFromUrl(url);
    } finally {
      _isProcessingPDF = false;
      notifyListeners();
    }
  }

  Future<MessageData> generateRAGResponse({
    required String query,
    List<dynamic>? attachments,
    SearchMode searchMode = SearchMode.search,
  }) async {
    _isProcessingRAG = true;
    notifyListeners();

    try {
      final response = await _ragOrchestrator.generateRAGResponse(
        query,
        attachments: attachments,
        searchMode: searchMode,
      );

      // Update performance metrics if available
      // _performanceMetrics = _ragOrchestrator.getPerformanceMetrics();

      return response;
    } finally {
      _isProcessingRAG = false;
      notifyListeners();
    }
  }

  void clearCache() {
    _cachedDocuments.clear();
    _lastQueryAnalysis = null;
    _performanceMetrics.clear();
    notifyListeners();
  }

  void addDocuments(List<Document> documents) {
    _cachedDocuments.addAll(documents);
    notifyListeners();
  }

  void removeDocument(String documentId) {
    _cachedDocuments.removeWhere((doc) => doc.id == documentId);
    notifyListeners();
  }
}